#!/bin/bash


# Exit on any error
set -e

# Update and upgrade system packages
echo "Updating package lists..."
sudo apt update -y
sudo apt upgrade -y

# Install PostgreSQL if not installed
if ! command -v psql &>/dev/null; then
    echo "Installing PostgreSQL..."
    sudo apt install -y postgresql postgresql-contrib
else
    echo "PostgreSQL is already installed"
fi

# Start and enable PostgreSQL service
echo "starting PostgreSQL service..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Securely set PostgreSQL password
read -sp "Enter PostgreSQL password: " DB_PASSWORD
echo ""

# Change PostgreSQL password 
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${DB_PASSWORD}';" >/dev/null 2>&1

# Create application group if it doesn't exist

#creating a group if not exists
if ! getent group csye6225 >/dev/null; then
    echo "Creating application group..."
    sudo groupadd csye6225
else
    echo "Group already exists"
fi

# Createing user if it doesn't exist
if ! id -u smit >/dev/null 2>&1; then
    echo "Creating user..."
    sudo useradd -m -g csye6225 smit
else
    echo "User already exists."
fi

echo "Setting up application directory..."
sudo mkdir -p /opt/csye6225

# Install unzip if not available
if ! command -v unzip &>/dev/null; then
    echo "Installing unzip..."
    sudo apt install -y unzip
fi

# Unzip application package 
echo "Unzipping application..."
sudo unzip -o /root/Smit_Patel_002088543_02.zip -d /opt/csye6225/

# Update permissions
echo "Updating folder permissions..."
sudo chown -R smit:csye6225 /opt/csye6225/
sudo chmod -R 750 /opt/csye6225/

echo "Setup completed successfully."

# Move into application directory
cd /opt/csye6225/Smit_Patel_002088543_02/webapp || exit 1

# Install Node.js & npm if not available
if ! command -v npm &>/dev/null; then
    echo "Installing npm..."
    sudo apt install -y npm
fi
if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."
    sudo apt install -y nodejs
fi

# Install Dependencies
echo "Install Application Dependencies..."
sudo npm install --silent

# Set env var..
echo "Setting environment variables..."
sudo tee /etc/environment >/dev/null <<EOF
DB_NAME=cloud
DB_USER=postgres
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=localhost
DB_DIALECT=postgres
EOF

# Load environment variables
source /etc/environment

# Start the Node.js application
echo "Starting application..."
sudo node index.js
