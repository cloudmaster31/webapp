# Webapp

## Description  
This application is built using Node.js and provides multiple API endpoints, including a `/healthz` endpoint for health checks and `/v1/file` endpoints for file uploads, retrieval, and deletion.  

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

#### Health Check Endpoint  
To test the `/healthz` endpoint manually:  
```bash
curl -vvv http://localhost:8080/healthz
```  

#### File Upload API  
To upload a file:  
```bash
curl -X POST -F "profilePic=@path/to/file.jpg" http://localhost:8080/v1/file
```  

#### Retrieve File Metadata  
To get metadata for a specific file:  
```bash
curl -X GET http://localhost:8080/v1/file/{file_id}
```  

#### Delete File  
To delete a file:  
```bash
curl -X DELETE http://localhost:8080/v1/file/{file_id}
```  

### 4. Running Tests  
A test API has been added. Run the tests using:  
```bash
npm test
```  

## API Endpoints  

### `/healthz`  
- **Method:** `GET`  
- **Description:** Health check endpoint.  
- **Response:** `200 OK` if the service is running.  
- **Other Methods:** Return `405 Method Not Allowed`.  

### `/v1/file`  
- **`POST`** - Uploads a file to S3 and stores metadata in the database.  
  - **Request:** Multipart form-data with a file under the key `profilePic`.  
  - **Response:** `201 Created` with file metadata.  
  - **Error Handling:** Returns `400` if no file is provided.  
- **`GET` & `DELETE`** - Return `400 Bad Request`.  
- **Other Methods:** Return `405 Method Not Allowed`.  

### `/v1/file/:id`  
- **`GET`** - Retrieves file metadata from the database.  
  - **Response:** `200 OK` with file details.  
  - **Error Handling:** Returns `404` if the file is not found.  
- **`DELETE`** - Deletes a file from S3 and removes metadata from the database.  
  - **Response:** `204 No Content` on success.  
  - **Error Handling:** Returns `404` if the file is not found.  
- **Other Methods:** Return `405 Method Not Allowed`.  

## CI/CD Pipeline  

The application includes a CI/CD pipeline using GitHub Actions with the following workflows:  

1. **Packer Validation & Formatting:**  
   - Ensures that the Packer configuration files are correctly formatted and valid.  

2. **API Testing Workflow:**  
   - Runs automated tests to validate API endpoints.  

3. **Packer Image Creation (AWS & GCP):**  
   - Builds and deploys a machine image using Packer for both Google Cloud Platform (GCP) and Amazon Web Services (AWS).  

These workflows help automate the validation, testing, and deployment of the web application