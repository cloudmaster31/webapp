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
  default = "n1-standard-1"
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
  source_image            = "ubuntu-minimal-2004-focal-v20250213"
  zone                    = var.gcp_zone
  image_name              = "ubuntu-custom-webapp"
  image_family            = "ubuntu-minimal-2004-lts"
  machine_type            = var.gcp_instance_type
  ssh_username            = "ubuntu"
  image_storage_locations = ["us"]
  labels = {
    env = "dev"
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
    "source.googlecompute.ubuntu",
  ]
  provisioner "file" {
    source      = "${var.artifact_path}" # File on the GitHub Actions runner
    destination = "/tmp/webapp.zip"      # Destination inside the VM
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

      "sudo bash -c 'echo \"DB_NAME=cloud\" >> /etc/environment'",
      "sudo bash -c 'echo \"DB_USER=postgres\" >> /etc/environment'",
      "sudo bash -c 'echo \"DB_PASSWORD=1234\" >> /etc/environment'",
      "sudo bash -c 'echo \"DB_HOST=localhost\" >> /etc/environment'",
      "sudo bash -c 'echo \"DB_DIALECT=postgres\" >> /etc/environment'",

      # Load environment variables using bash
      ". /etc/environment",

      "sudo useradd -m -s /usr/sbin/nologin csye6225",
      "sudo groupadd -f csye6225",
      "sudo usermod -aG csye6225 csye6225",
      # Unzip the application artifacts to a directory
      "sudo unzip ${var.artifact_path} -d /home/csye6225/app",

      # Set ownership of the application files
      "sudo chown -R csye6225:csye6225 /home/csye6225/app",

      # Install application dependencies
      "cd /home/csye6225/app && sudo -u csye6225 npm install",

    ]
  }
}
