const express = require("express");
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const { sequelize, HealthCheck, s3, FileMetadata } = require("./database");
const {logToCloudWatch} = require("./cloudwatch-logger");
const { logMetric } = require("./cloudwatch-metric");

const app = express();
const bucketName = process.env.S3_BUCKET;
const upload = multer({ storage: multer.memoryStorage() });

// Health Check Endpoint
app.get("/healthz", async (req, res) => {
  const start = Date.now(); 
  
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
    res.status(503).end();
  } finally {
    const duration = Date.now() - start;
    logMetric("API_Call_Count", "healthz", 1); // Increment API call count
    logMetric("API_Response_Time", "healthz", duration); // Log execution time
  }
});


// Upload File Endpoint
app.post("/v1/file", upload.single("profilePic"), async (req, res) => {
  const start = Date.now(); // Start time tracking

  if (!req.file) {
    logToCloudWatch("WARN", "File upload request missing file");
    return res.status(400).end();
  }

  const fileId = uuidv4();
  const fileKey = `${fileId}/${req.file.originalname}`;

  try {
    const s3Start = Date.now();
    await s3.upload({
      Bucket: bucketName,
      Key: fileKey,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
    }).promise();
    logMetric("S3_Call_Time", "upload", Date.now() - s3Start); // Log S3 execution time

    const dbStart = Date.now();
    const file = await FileMetadata.create({
      id: fileId,
      filename: req.file.originalname,
      s3_path: fileKey,
    });
    logMetric("DB_Query_Time", "insert_file", Date.now() - dbStart); // Log DB execution time

    logToCloudWatch("INFO", `File uploaded successfully: ${fileKey}`);
    res.status(201).json({
      file_name: file.filename,
      id: file.id,
      url: file.s3_path,
      upload_date: new Intl.DateTimeFormat('en-CA').format(new Date()),
    });
  } catch (error) {
    logToCloudWatch("ERROR", `File upload error: ${error.message}`, error);
    res.status(500).end();
  } finally {
    const duration = Date.now() - start;
    logMetric("API_Call_Count", "file_upload", 1);
    logMetric("API_Response_Time", "file_upload", duration);
  }
});


// Retrieve File Metadata Endpoint
app.get("/v1/file/:id", async (req, res) => {
  const start = Date.now();

  try {
    const dbStart = Date.now();
    const file = await FileMetadata.findByPk(req.params.id);
    logMetric("DB_Query_Time", "fetch_file", Date.now() - dbStart);

    if (!file) {
      return res.status(404).end();
    }
    logToCloudWatch("INFO", `File retrieved successfully: ${file.s3_path}`);
    res.json({
      file_name: file.filename,
      id: file.id,
      url: file.s3_path,
      upload_date: file.createdAt,
    });
  } catch (error) {
    logToCloudWatch("ERROR", `Error retrieving file: ${error.message}`, error);
    res.status(500).end();
  } finally {
    const duration = Date.now() - start;
    logMetric("API_Call_Count", "file_retrieve", 1);
    logMetric("API_Response_Time", "file_retrieve", duration);
  }
});


// Delete File Endpoint
app.delete("/v1/file/:id", async (req, res) => {
  const start = Date.now();

  try {
    const dbStart = Date.now();
    const file = await FileMetadata.findByPk(req.params.id);
    logMetric("DB_Query_Time", "fetch_file_for_delete", Date.now() - dbStart);

    if (!file) {
      logToCloudWatch("WARN", `File not found for deletion: ${req.params.id}`);
      return res.status(404).end();
    }

    const s3Start = Date.now();
    await s3.deleteObject({ Bucket: bucketName, Key: file.s3_path }).promise();
    logMetric("S3_Call_Time", "delete_file", Date.now() - s3Start);

    const dbDeleteStart = Date.now();
    await file.destroy();
    logMetric("DB_Query_Time", "delete_file", Date.now() - dbDeleteStart);

    logToCloudWatch("INFO", `File deleted successfully: ${file.s3_path}`);
    res.status(204).send();
  } catch (error) {
    logToCloudWatch("ERROR", `File deletion error: ${error.message}`, error);
    res.status(500).end();
  } finally {
    const duration = Date.now() - start;
    logMetric("API_Call_Count", "file_delete", 1);
    logMetric("API_Response_Time", "file_delete", duration);
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
  res.set("Cache-Control", "no-cache");x
  logToCloudWatch("WARN", `404 Not Found: ${req.method} ${req.originalUrl}`);
  res.status(404).end();
});



module.exports = app;
