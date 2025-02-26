variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "dev"
}

variable "gcp_project_id" {
  default = "webapp-dev-451815"
}

variable "aws_instance_type" {
  default = "t3.micro"
}
variable "gcp_instance_type" {
  default = "e2-medium"
}
variable "gcp_zone" {
  default = "us-central1-b"
}
variable "artifact_path" {
  description = "Path to the artifact"
  type        = string
  default     = "/"
}


source "amazon-ebs" "ubuntu" {

  source_ami_filter {
    filters = {
      name                = "ubuntu-*-24.04-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
  instance_type = var.aws_instance_type
  ssh_username  = "ubuntu"
  ami_name      = "custom-ubuntu-24.04"
  ami_groups    = []
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

# source "googlecompute" "ubuntu" {
#   project_id       = var.gcp_project_id
#   source_image     = "ubuntu-2404-lts"
#   zone             = "us-central1-a"
#   image_name       = "custom-ubuntu-24-04-${timestamp()}"
#   image_family     = "custom-ubuntu-24-04"
#   machine_type     = "n1-standard-1"
#   image_storage_locations = ["us"]
#   labels = {
#     env = "dev"
#   }
# }

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
      "sudo apt update && sudo apt install -y apt-utils",
      "sudo apt upgrade -y",
      "sudo apt install -y postgresql",
      "sudo systemctl enable --now postgresql",
      "sudo systemctl start postgresql",
      "sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD '1234';\" >/dev/null 2>&1",
      "sudo apt install -y unzip curl",
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -",
      "sudo apt-get install -y nodejs",
      "echo 'DB_NAME=cloud' | sudo tee -a /etc/environment",
      "echo 'DB_USER=postgres' | sudo tee -a /etc/environment",
      "echo 'DB_PASSWORD=1234' | sudo tee -a /etc/environment",
      "echo 'DB_HOST=localhost' | sudo tee -a /etc/environment",
      "echo 'DB_DIALECT=postgres' | sudo tee -a /etc/environment",
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
      ExecStart=/usr/bin/node /home/csye6225/app/server.js
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

