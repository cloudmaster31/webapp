# Webapp

## Description
This application is built using **Node.js** and provides RESTful API endpoints, including a `/healthz` endpoint for health checks and `/v1/file` endpoints for file uploads, retrieval, and deletion. It integrates with **AWS CloudWatch** for logging and monitoring and uses **AWS S3** for file storage and **RDS PostgreSQL** for metadata storage.

---

## Setup Instructions

### 1. Install Dependencies
```bash
npm install
```

### 2. Start the Server
```bash
node index.js
```
The server runs on port **8080**.

---

## API Usage

### Health Check
```bash
curl -vvv http://localhost:8080/healthz
```

### Upload a File
```bash
curl -X POST -F "profilePic=@path/to/file.jpg" http://localhost:8080/v1/file
```

### Retrieve File Metadata
```bash
curl -X GET http://localhost:8080/v1/file/{file_id}
```

### Delete a File
```bash
curl -X DELETE http://localhost:8080/v1/file/{file_id}
```

---

## API Endpoints

### `/healthz`
- `GET`: Health check. Returns `200 OK` if the service is running.
- Other methods: Returns `405 Method Not Allowed`.

### `/v1/file`
- `POST`: Upload a file.
- `GET` & `DELETE`: Returns `400 Bad Request`.
- Other methods: Returns `405 Method Not Allowed`.

### `/v1/file/:id`
- `GET`: Retrieves file metadata.
- `DELETE`: Deletes file and metadata.
- Other methods: Returns `405 Method Not Allowed`.

---

## Running Tests
```bash
npm test
```

---

## CI/CD Pipeline (GitHub Actions)

This project uses GitHub Actions for CI/CD. The pipeline is triggered on a pull request merge and follows these steps:

### 📦 CI Workflow
1. Run unit tests.
2. Validate Packer templates.
3. Build application artifact(s).
4. Build AMI in **DEV AWS Account**.
5. Upgrade OS packages.
6. Install system dependencies (Node.js, Python, etc.).
7. Install application dependencies (`npm install`).
8. Copy built application and configuration to the target machine.
9. Configure the application to auto-start on VM launch.

### 🚀 Deployment (Post-Merge)
1. Share AMI with the **DEMO AWS Account**.
2. Switch AWS CLI context to use DEMO account credentials.
3. Create a new Launch Template version using the latest AMI.
4. Update Auto Scaling Group to use the new Launch Template version.
5. Trigger an **Instance Refresh** on the Auto Scaling Group.
6. Wait until the instance refresh completes successfully.
7. Exit the workflow with the refresh status.

> 💡 Rollback for failed deployments is not handled.

---

## Metrics & Logging

### CloudWatch Custom Metrics
- **API_Call_Count**: API call frequency.
- **API_Response_Time**: Response time per endpoint (ms).
- **DB_Query_Time**: Query performance in milliseconds.
- **S3_Call_Time**: Time taken for each S3 call.

### Logging
- All logs are sent to **AWS CloudWatch Logs**.
- Logs include levels: `INFO`, `WARN`, `ERROR`.
- Stack traces and meaningful messages are provided.

#### Example Logs
```txt
INFO: Health check passed
INFO: File uploaded successfully: uploads/pic.jpg
INFO: DB query execution time: 35ms
INFO: S3 call completed in 27ms
```

---

## Deployment Notes
- This app is deployed to **EC2 instances** behind an **Application Load Balancer (ALB)**.
- ALB supports both **HTTP** and **HTTPS**.
- SSL certificate is **imported manually (e.g., via Namecheap)** and attached to the ALB.
- DNS routing is handled via **Route 53**.


