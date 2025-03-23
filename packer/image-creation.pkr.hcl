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
  ssh_username            = "packer"
  image_storage_locations = ["us-central1"]
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
      "  echo 'Not on AWS, checking apt-utils compatibility...';",
      "  if sudo apt-cache policy apt-utils | grep -q 'Installed: (none)'; then",
      "    echo 'apt-utils not installed, attempting to install...';",
      "    sudo apt install -y --allow-downgrades apt=2.0.2ubuntu0.2 apt-utils || echo 'Skipping apt-utils due to dependency issues';",
      "  else",
      "    echo 'apt-utils already installed or unnecessary';",
      "  fi",
      "else",
      "  echo 'Skipping apt-utils (running on AWS)';",
      "fi",
      "sudo apt upgrade -y",

      "sudo apt install -y unzip curl",
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -",
      "sudo apt-get install -y nodejs",
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
      "curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
      "sudo dpkg -i -E amazon-cloudwatch-agent.deb",
      "sudo mkdir -p /var/log/node",
      "sudo touch /var/log/node/csye6225.log",
      "sudo chmod 644 /var/log/node/csye6225.log",
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
