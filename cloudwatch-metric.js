const AWS = require("aws-sdk");
const cloudwatch = new AWS.CloudWatch();

function logMetric(metricName, apiName, value) {
  const params = {
    MetricData: [
      {
        MetricName: metricName,
        Dimensions: [
          {
            Name: "API",
            Value: apiName,
          },
        ],
        Unit: "Milliseconds",
        Value: value,
      },
    ],
    Namespace: "MyApplicationMetrics",
  };

  cloudwatch.putMetricData(params, (err, data) => {
    if (err) console.error(`CloudWatch metric error: ${err.message}`);
  });
}

module.exports = { logMetric };
