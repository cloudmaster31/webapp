const express = require("express");
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");
const { sequelize, HealthCheck, s3, FileMetadata } = require("./database");

const app = express();
const bucketName = process.env.S3_BUCKET;
const upload = multer({ storage: multer.memoryStorage() });

// Health Check Endpoint
app.get("/healthz", async (req, res) => {
  try {
    if (req.get("Content-Length") > 0 || Object.keys(req.query).length > 0) {
      return res.status(400).end();
    }
    res.set("Cache-Control", "no-cache");

    await sequelize.authenticate();
    await HealthCheck.create({});
    
    res.status(200).end();
  } catch (error) {
    console.error("Health check failed:", error);
    res.status(503).end();
  }
});

// Upload File Endpoint
app.post("/v1/file", upload.single("profilePic"), async (req, res) => {
  if (!req.file) {
    return res.status(400).end();
  }

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

    res.status(201).json({
      file_name: file.filename,
      id: file.id,
      url: file.s3_path,
      upload_date: new Date().toISOString(),
    });
  } catch (error) {
    console.error("File upload error:", error);
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

    res.json({
      file_name: file.filename,
      id: file.id,
      url: file.s3_path,
      upload_date: file.createdAt.toISOString(),
    });
  } catch (error) {
    console.error("Error retrieving file:", error);
    res.status(500).end();
  }
});

// Delete File Endpoint
app.delete("/v1/file/:id", async (req, res) => {
  try {
    const file = await FileMetadata.findByPk(req.params.id);
    if (!file) {
      return res.status(404).end();
    }

    await s3.deleteObject({ Bucket: bucketName, Key: file.s3_path }).promise();
    await file.destroy();

    res.status(204).send();
  } catch (error) {
    console.error("File deletion error:", error);
    res.status(500).end();  
  }
});

app.all("/healthz", async (req, res) => {
  res.set("Cache-Control", "no-cache");
  res.status(405).send();
});

app.all("/v1/file", async (req, res) => {
  res.set("Cache-Control", "no-cache");
  res.status(400).send();
});
app.all("/v1/file/:id", async (req, res) => {
  res.set("Cache-Control", "no-cache");
  res.status(405).send();
});

app.use((req, res) => {
  res.set("Cache-Control", "no-cache");
  res.status(404).end();
});



module.exports = app;
