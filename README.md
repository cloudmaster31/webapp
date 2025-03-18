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

### 3. Testing API
To test the API manually:
```bash
curl -vvv http://localhost:8080/healthz
```

### 4. Running Tests
A test API has been added. Run the tests using:
```bash
npm test
```

## CI/CD Pipeline

The application includes a CI/CD pipeline using GitHub Actions with the following workflows:

1. **Packer Validation & Formatting:**
   - Ensures that the Packer configuration files are correctly formatted and valid.

2. **API Testing Workflow:**
   - Runs automated tests to validate the `/healthz` API endpoint.

3. **Packer Image Creation (AWS & GCP):**
   - Builds and deploys a machine image using Packer for both Google Cloud Platform (GCP) and Amazon Web Services (AWS).

These workflows help automate the validation, testing, and deployment of the web application.
