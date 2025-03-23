const AWS = require("aws-sdk");

// Configure AWS CloudWatch Logs
const cloudwatchLogs = new AWS.CloudWatchLogs({
  region: process.env.AWS_REGION || "us-east-1",
});

const logGroupName = "/my-app/logs";
const logStreamName = "application-stream"; // Change this as needed
let sequenceToken = null; // AWS CloudWatch needs this for ordering logs


async function createLogGroupAndStream() {
    const credentials = new AWS.SharedIniFileCredentials({ profile: "dev" });
    AWS.config.credentials = credentials;
    AWS.config.region = "us-east-1";


    try {
      await cloudwatchLogs.createLogGroup({ logGroupName }).promise();
    } catch (error) {
      if (error.code !== "ResourceAlreadyExistsException") console.error(error);
    }
  
    try {
      await cloudwatchLogs.createLogStream({ logGroupName, logStreamName }).promise();
    } catch (error) {
      if (error.code !== "ResourceAlreadyExistsException") console.error(error);
    }
}

  
async function logToCloudWatch(level, message) {
  try {
    if (!sequenceToken) {
      // Fetch latest sequence token if it's not set
      const streams = await cloudwatchLogs.describeLogStreams({ logGroupName }).promise();
      const stream = streams.logStreams.find(s => s.logStreamName === logStreamName);
      if (stream) {
        sequenceToken = stream.uploadSequenceToken;
      }
    }

    const logEvent = {
      logGroupName,
      logStreamName,
      logEvents: [
        {
          timestamp: Date.now(),
          message: JSON.stringify({ level, message }),
        },
      ],
      sequenceToken,
    };

    const response = await cloudwatchLogs.putLogEvents(logEvent).promise();
    sequenceToken = response.nextSequenceToken; // Update sequence token for the next log
  } catch (error) {
    console.error("CloudWatch Logging Error:", error);
  }
}

module.exports = { createLogGroupAndStream, logToCloudWatch };
