const express = require("express");
const { Sequelize, DataTypes } = require("sequelize");
const app = express();


// Initialising Basic Node Server

const port = 8080;
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});