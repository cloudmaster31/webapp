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
  ami_users     = [var.aws_account_id, var.aws_copy_account_id]
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
