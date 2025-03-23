const app = require("./app");
const { connectDatabase } = require("./database");
const { createLogGroupAndStream } = require("./cloudwatch-logger");
const PORT = process.env.PORT || 8080;

connectDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    // createLogGroupAndStream();
  });
});
