const express = require("express");
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const { sequelize, HealthCheck, s3, FileMetadata } = require("./database");
// const {logToCloudWatch} = require("./cloudwatch-logger");

const app = express();
const bucketName = process.env.S3_BUCKET;
const upload = multer({ storage: multer.memoryStorage() });

// Health Check Endpoint
app.get("/healthz", async (req, res) => {
  try {
    if (req.get("Content-Length") > 0 || Object.keys(req.query).length > 0) {
      logToCloudWatch("WARN", "Invalid health check request received");
      return res.status(400).end();
    }
    res.set("Cache-Control", "no-cache");

    await sequelize.authenticate();
    await HealthCheck.create({});
    logToCloudWatch("INFO", "Health check passed");

    res.status(200).end();
  } catch (error) {
    logToCloudWatch("ERROR", `Health check failed: ${error.message}`, error);
    console.error("Health check failed:", error);
    res.status(503).end();
  }
});

// Upload File Endpoint
app.post("/v1/file", upload.single("profilePic"), async (req, res) => {
  if (!req.file) {
    logToCloudWatch("WARN", "File upload request missing file");
    return res.status(400).end();
  }
  res.set("Cache-Control", "no-cache");

  const fileId = uuidv4();
  const fileKey = `${fileId}/${req.file.originalname}`;
  
  try {
    await s3.upload({
      Bucket: bucketName,
      Key: fileKey,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
    }).promise();

    const file = await FileMetadata.create({
      id: fileId,
      filename: req.file.originalname,
      s3_path: fileKey,
    });
    logToCloudWatch("INFO", `File uploaded successfully: ${fileKey}`);

    res.status(201).json({
      file_name: file.filename,
      id: file.id,
      url: file.s3_path,
      upload_date: new Intl.DateTimeFormat('en-CA').format(new Date()), // Output: "2025-03-19"
    });
  } catch (error) {
    logToCloudWatch("ERROR", `File upload error: ${error.message}`, error);
    res.status(500).end();
  }
});

// Retrieve File Metadata Endpoint
app.get("/v1/file/:id", async (req, res) => {
  try {
    const file = await FileMetadata.findByPk(req.params.id);
    if (!file) {
      return res.status(404).end();
    }
    res.set("Cache-Control", "no-cache");
    console.log("File retrieved successfully:", file.s3_path);
    res.json({
      file_name: file.filename,
      id: file.id,
      url: file.s3_path,
      upload_date: file.createdAt,
    });
  } catch (error) {
    console.error("Error retrieving file:", error);a
    res.status(500).end();
  }
});

// Delete File Endpoint
app.delete("/v1/file/:id", async (req, res) => {
  try {
    const file = await FileMetadata.findByPk(req.params.id);
    if (!file) {
      logToCloudWatch("WARN", `File not found for deletion: ${req.params.id}`);

      return res.status(404).end();
    }

    await s3.deleteObject({ Bucket: bucketName, Key: file.s3_path }).promise();
    await file.destroy();
    logToCloudWatch("INFO", `File deleted successfully: ${file.s3_path}`);
    res.status(204).send();
  } catch (error) {
    logToCloudWatch("ERROR", `File deletion error: ${error.message}`, error);
    res.status(500).end();  
  }
});

app.all("/healthz", async (req, res) => {
  res.set("Cache-Control", "no-cache");
  logToCloudWatch("WARN", `Invalid method ${req.method} on /healthz`);
  res.status(405).send();
});

app.all("/v1/file", async (req, res) => {
  res.set("Cache-Control", "no-cache");
  logToCloudWatch("WARN", `Invalid method ${req.method} on /v1/file`);

  if (req.method === "GET" || req.method === "DELETE") {
    res.status(400).send();
  } else {
    res.status(405).send();
  }
});
app.all("/v1/file/:id", async (req, res) => {
  logToCloudWatch("WARN", `Invalid method ${req.method} on /v1/file/${req.params.id}`);
  res.set("Cache-Control", "no-cache");
  res.status(405).send();
});

app.use((req, res) => {
  res.set("Cache-Control", "no-cache");
  logToCloudWatch("WARN", `404 Not Found: ${req.method} ${req.originalUrl}`);
  res.status(404).end();
});



module.exports = app;
