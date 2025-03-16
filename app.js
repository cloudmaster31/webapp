const express = require("express");
const multer = require("multer");
const { v4: uuidv4 } = require("uuid");

const { sequelize, HealthCheck,s3,FileMetadata } = require("./database"); // Import HealthCheck model.

const app = express();
const bucketName = process.env.S3_BUCKET;
const upload = multer({ storage: multer.memoryStorage() }); // Store files in memory before uploading to S3

// GET API Call
app.get("/healthz", async (req, res) => {
  try {
    if (req.get("Content-Length") > 0) {
      return res.status(400).end();
    }
    if (Object.keys(req.query).length > 0) {
      return res.status(400).end();
    }
    res.set("Cache-Control", "no-cache");

    await sequelize.authenticate();
    
    const result = await HealthCheck.create({});
    console.log(`Entry added with ID: ${result.checkId}`);

    res.status(200).end();
  } catch (error) {
    console.error("Error in health check:", error);
    res.status(503).end();
  }
});

app.post("/v1/file", upload.single("file"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No file uploaded" });
  }

  const fileId = uuidv4();
  const fileKey = `${fileId}-${req.file.originalname}`;

  const params = {
    Bucket: bucketName,
    Key: fileKey,
    Body: req.file.buffer,
    ContentType: req.file.mimetype,
  };

  try {
    await s3.upload(params).promise();

    // Save file metadata in DB
    const file = await FileMetadata.create({
      id: fileId,
      filename: req.file.originalname,
      s3_path: fileKey,
    });

    res.status(201).json({ id: file.id, filename: file.filename, s3_path: file.s3_path });
  } catch (error) {
    console.error("File upload error:", error);
    res.status(500).json({ error: "Failed to upload file" });
  }
});

// Retrieve File Metadata
app.get("/v1/file/:id", async (req, res) => {
  try {
    const file = await FileMetadata.findByPk(req.params.id);
    if (!file) {
      return res.status(404).json({ error: "File not found" });
    }

    res.json({ id: file.id, filename: file.filename, s3_path: file.s3_path });
  } catch (error) {
    console.error("Error retrieving file:", error);
    res.status(500).json({ error: "Failed to retrieve file" });
  }
});

// Delete File from S3 & Database
app.delete("/v1/file/:id", async (req, res) => {
  try {
    const file = await FileMetadata.findByPk(req.params.id);
    if (!file) {
      return res.status(404).json({ error: "File not found" });
    }

    // Delete from S3
    await s3.deleteObject({ Bucket: bucketName, Key: file.s3_path }).promise();

    // Delete from database
    await file.destroy();

    res.status(204).send();
  } catch (error) {
    console.error("File deletion error:", error);
    res.status(500).json({ error: "Failed to delete file" });
  }
});


// Handle other calls
app.all("/healthz", async (req, res) => {
  res.set("Cache-Control", "no-cache");
  res.status(405).send();
});
app.use((req, res) => {
  res.set("Cache-Control", "no-cache");
  res.status(404).end();
});


module.exports = app;
