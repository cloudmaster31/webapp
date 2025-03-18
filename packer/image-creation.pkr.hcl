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
  source_image_family     = "ubuntu-minimal-2004-lts"
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
      "sudo apt update",
      "if ! curl -fsSL -m 2 http://169.254.169.254/latest/meta-data >/dev/null 2>&1; then",
      "  echo 'Not on AWS, installing apt-utils...';",
      "  sudo apt install -y apt-utils;",
      "else",
      "  echo 'Skipping apt-utils (running on AWS)';",
      "fi"
      "sudo apt upgrade -y",
      # "sudo apt install -y postgresql",
      # "sudo systemctl enable --now postgresql",
      # "sudo systemctl start postgresql",
      # "sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD '1234';\" >/dev/null 2>&1",
      "sudo apt install -y unzip curl",
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -",
      "sudo apt-get install -y nodejs",
      # "echo \"DB_NAME=${var.db_name}\" | sudo tee -a /etc/environment",
      # "echo \"DB_USER=${var.db_user}\" | sudo tee -a /etc/environment",
      # "echo \"DB_PASSWORD=${var.db_password}\" | sudo tee -a /etc/environment",
      # "echo \"DB_HOST=${var.db_host}\" | sudo tee -a /etc/environment",
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
