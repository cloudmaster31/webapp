#!/bin/bash

# Exit on any error
set -e

# Update and upgrade system packages
echo "Updating package lists..."
sudo apt update -y
sudo apt upgrade -y

# Install PostgreSQL (Change to MySQL/MariaDB if needed)
echo "Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL service
echo "Enabling and starting PostgreSQL service..."
sudo systemctl enable postgresql
sudo systemctl start postgresql
read -sp "Enter PostgreSQL password: " DB_PASSWORD

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$DB_PASSWORD';"

# # Create database
# echo "Creating application database..."
# sudo -u postgres psql -c "CREATE DATABASE app_db;"

# Create application group and user
echo "Creating application group and user..."
sudo groupadd csye6225
sudo useradd -m -g csye6225 smit

# Ensure /opt/csye6225 exists
echo "Setting up application directory..."
sudo mkdir -p /opt/csye6225

# Unzip application package (assuming it's in /tmp/app.zip)
echo "Unzipping application..."
sudo apt install -y unzip  # Ensure unzip is available
sudo unzip /root/Smit_Patel_002088543_02.zip -d /opt/csye6225/

# Update permissions
echo "Updating folder permissions..."
sudo chown -R smit:cyse6225 /opt/csye6225/Smit_Patel_002088543_02
sudo chmod -R 750 /opt/csye6225/Smit_Patel_002088543_02

echo "Setup completed successfully."
cd /opt/csye6225/Smit_Patel_002088543_02/webapp
sudo apt install npm
sudo apt install nodejs
sudo npm install

echo "Setting environment variables..."
echo "export DB_NAME=cloud" | sudo tee -a /etc/environment
echo "export DB_USER=postgres" | sudo tee -a /etc/environment
echo "export DB_PASSWORD=$DB_PASSWORD" | sudo tee -a /etc/environment
echo "export DB_HOST=localhost" | sudo tee -a /etc/environment
echo "export DB_DIALECT=postgres" | sudo tee -a /etc/environment

# Load environment variables immediately
source /etc/environment


sudo node index.js

