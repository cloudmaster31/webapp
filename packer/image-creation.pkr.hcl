source "amazon-ebs" "ubuntu" {

  source_ami_filter {
    filters = {
      name                = "ubuntu-*-24.04-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
  instance_type = var.aws_instance_type
  ssh_username  = "ubuntu"
  ami_name      = "custom-ubuntu-24.04"
  ami_groups    = []
  ami_users     = [var.aws_copy_account_id]
  tags = {
    Project = "DEV"
    Owner   = "Smit"
  }
}

source "googlecompute" "ubuntu" {
  project_id              = var.gcp_project_id
  source_image_family     = "ubuntu-minimal-2004-lts" # Always latest in the 2004 family
  zone                    = var.gcp_zone
  image_name              = "ubuntu-custom-webapp"
  image_family            = "ubuntu-minimal-webapp"
  machine_type            = var.gcp_instance_type
  ssh_username            = "packer"        # More standard for automated provisioning
  image_storage_locations = ["us-central1"] # More specific than just "us"
  labels = {
    env  = "dev"
    role = "webapp"
  }
}


packer {
  required_plugins {
    amazon-ebs = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0, < 2.0.0"
    }
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = ">= 1.0.0, < 2.0.0"
    }
  }
}

build {
  sources = [
    "source.amazon-ebs.ubuntu",
    "source.googlecompute.ubuntu"
  ]

  provisioner "file" {
    source      = var.artifact_path
    destination = "/tmp/webapp.zip"
  }

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",

      # Ensure no APT processes are running
      "while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do echo 'Waiting for dpkg lock...'; sleep 3; done",
      "while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do echo 'Waiting for apt lock...'; sleep 3; done",
      "while sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do echo 'Waiting for apt cache lock...'; sleep 3; done",

      # Kill any stuck apt/dpkg processes
      "sudo killall -9 apt apt-get dpkg 2>/dev/null || true",

      # Clean up package lists and cache
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo apt-get clean",
      "sudo apt-get update --fix-missing",

      # Ensure apt-utils is installed safely
      "sudo apt-get install -y --fix-broken apt-utils",

      # Perform a safe upgrade
      "sudo apt-get dist-upgrade -y",

      "sudo apt install -y postgresql",
      "sudo systemctl enable --now postgresql",
      "sudo systemctl start postgresql",
      "sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD '1234';\" >/dev/null 2>&1",
      "sudo apt install -y unzip curl",
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -",
      "sudo apt-get install -y nodejs",
      "echo \"DB_NAME=${var.db_name}\" | sudo tee -a /etc/environment",
      "echo \"DB_USER=${var.db_user}\" | sudo tee -a /etc/environment",
      "echo \"DB_PASSWORD=${var.db_password}\" | sudo tee -a /etc/environment",
      "echo \"DB_HOST=${var.db_host}\" | sudo tee -a /etc/environment",
      "echo \"DB_DIALECT=${var.db_dialect}\" | sudo tee -a /etc/environment",
      "export $(cat /etc/environment | xargs)",
      "sudo useradd -m -s /bin/bash csye6225 || true",
      "sudo groupadd -f csye6225",
      "sudo usermod -aG csye6225 csye6225",
      "sudo mkdir -p /home/csye6225/app",
      "sudo chown -R csye6225:csye6225 /home/csye6225",
      "sudo chmod -R 755 /home/csye6225",
      "sudo ls -ld /home/csye6225 /home/csye6225/app",
      "sudo -u csye6225 unzip /tmp/webapp.zip -d /home/csye6225/app",
      "sudo -u csye6225 ls -la /home/csye6225/app",
      "cd /home/csye6225/app && sudo -u csye6225 npm install",

    ]
  }

  provisioner "shell" {
    inline = [
      <<EOF
      sudo bash -c 'cat > /etc/systemd/system/myapp.service <<EOL
      [Unit]
      Description=My Web Application
      After=network.target

      [Service]
      User=csye6225
      Group=csye6225
      WorkingDirectory=/home/csye6225/app
      EnvironmentFile=/etc/environment
      ExecStart=/usr/bin/env node /home/csye6225/app/index.js
      Restart=always

      [Install]
      WantedBy=multi-user.target
      EOL'
      EOF
    ]
  }

  provisioner "shell" {
    inline = [
      <<EOF
      sudo bash -c 'cat > /etc/systemd/system/myapp.service <<EOL
      [Unit]
      Description=My Web Application
      After=network.target

      [Service]
      User=csye6225
      Group=csye6225
      WorkingDirectory=/home/csye6225/app
      EnvironmentFile=/etc/environment
      ExecStart=/usr/bin/env node /home/csye6225/app/index.js
      Restart=always

      [Install]
      WantedBy=multi-user.target
      EOL'
      EOF
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo systemctl daemon-reload",
      "sudo systemctl enable myapp.service",
      "sudo systemctl start myapp.service",
      "sudo systemctl status myapp.service || true"
    ]
  }

}
