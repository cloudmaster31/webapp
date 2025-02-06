const express = require("express");
const { sequelize, HealthCheck } = require("./database"); // Import HealthCheck model

const app = express();

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

// Handle other calls
app.all("/healthz", async (req, res) => {
  res.status(405).send();
});
app.use((req, res) => {
  res.status(404).end();
});


module.exports = app;
