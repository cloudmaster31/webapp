const fs = require("fs");
const path = "/var/log/node/csye6225.log"; // Must match cloudwatch-config.json

function logToCloudWatch(level, message, error = null) {
  try {
    const timestamp = new Date().toISOString();
    const logMessage = {
      level,
      message,
      timestamp,
      ...(error && { error: error.stack || error.toString() }),
    };

    const logString = `[${level}] ${timestamp} - ${message}${error ? ` | Error: ${error.stack || error.toString()}` : ""}\n`;

    // Append log to file
    fs.appendFileSync(path, logString, "utf8");

    // Also log to console for debugging
    // console.log(logString.trim());
  } catch (err) {
    console.error("File Logging Error:", err);
  }
}

module.exports = { logToCloudWatch };
