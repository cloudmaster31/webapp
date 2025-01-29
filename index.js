const express = require("express");
const { Sequelize, DataTypes } = require("sequelize");
const app = express();


// Postgre Initiated
const sequelize = new Sequelize("cloud", "postgres", "1234", {
    host: "localhost",
    dialect: "postgres",
    logging: false,
});

// Define the HealthCheck model (table)
const HealthCheck = sequelize.define(
    "HealthCheck",
    {
        checkId: {
            type: DataTypes.INTEGER,
            primaryKey: true,
            autoIncrement: true,
        },
        datetime: {
            type: DataTypes.DATE,
            allowNull: false,
            defaultValue: Sequelize.NOW,
        },
    },
    {
        tableName: "health_check",
        timestamps: false,
    }
);

// sync table so if table not exist then also create a table automaticlly.
(async () => {
    try {
        await sequelize.sync(); 
    } catch (error) {
        console.error("Error syncing database:", error);
    }
})();

// Get Api Call
app.get("/healthz", async (req, res) => {
    try {

        //  check for Payload
        if (req.get("Content-Length") > 0) {
            return res.status(400).end();
        }

        // Add Cache-Control header
        res.set("Cache-Control", "no-cache");

        // Connect with Databasse
        await sequelize.authenticate();

        // Data Inserted
        const result = await HealthCheck.create({});

        console.log(`entry Added with ID: ${result.checkId}`);

        // Give Success Response
        res.status(200).end();
    } catch (error) {

        res.set("Cache-Control", "no-cache");
        console.error("Error in health check:", error);
        // Give Error 503
        res.status(503).end();
    }
});

// for other calls
app.all('/healthz', (req, res) => {
    res.status(405).send();
});




// Initialising Basic Node Server
const port = 8080;
app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});