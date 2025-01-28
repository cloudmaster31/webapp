# Webapp

## Description

This application created using node.js and  that provides a `/healthz` endpoint.The API supports only `GET` requests.
## Setup Instructions

### 1. Install Dependencies

To install all dependencies, run command:

```bash
npm install
```
#### 2. Start Server

To Start the Server

```bash
node index.js
```

server is running on port 8080.

#### 3. Testing

To test the query

```bash
curl -vvv http://localhost:8080/healthz
````
