const { Sequelize, DataTypes } = require("sequelize");

const dbName = "cloud";


const rootSequelize = new Sequelize("postgres", "postgres", "1234", {
  host: "localhost",
  dialect: "postgres",
  logging: false,
});

const sequelize = new Sequelize(dbName, "postgres", "1234", {
  host: "localhost",
  dialect: "postgres",
  logging: false,

});
async function ensureDatabaseExists(dbName) {
  try {
    const [results] = await rootSequelize.query(
      `SELECT 1 FROM pg_database WHERE datname = '${dbName}'`
    );

    if (results.length === 0) {
      console.log(`Database "${dbName}" not found.`);
      await rootSequelize.query(`CREATE DATABASE "${dbName}"`);
      console.log(`Database "${dbName}" created.`);
    }
  } catch (error) {
    console.error("Error checking/creating database:", error);
    throw error; // Re-throw for higher-level handling
  } finally {
    await rootSequelize.close(); // Close root connection
  }
}


// Define HealthCheck model
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

async function connectDatabase() {

  await ensureDatabaseExists(dbName);
  try {
    await sequelize.authenticate();
    console.log(`Connected to database: ${dbName}`);
    await HealthCheck.sync(); // ✅ Ensure the table exists
    console.log("Database synced successfully.");
  } catch (error) {
    console.error("Database connection error:", error);
    process.exit(1);
  }
}

module.exports = { sequelize, HealthCheck, connectDatabase };
