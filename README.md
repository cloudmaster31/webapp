# Webapp

## Description
This application is created using Node.js and provides a `/healthz` endpoint. The API supports only `GET` requests.

## Setup Instructions

### 1. Install Dependencies
To install all dependencies, run:
```bash
npm install
```

### 2. Start Server
To start the server:
```bash
node index.js
```
The server runs on port 8080.

### 3. Testing
To test the API:
```bash
curl -vvv http://localhost:8080/healthz
```

### 4. Running Tests
A new test API has been added. Run the tests using:
```bash
npm test
```

### 5. Webapp CI Pipeline
A GitHub Actions CI pipeline has been created to automate testing and validation of the application.
