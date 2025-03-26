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
  ami_name      = "custom-ubuntu-24.04-${timestamp()}"
  ami_groups    = []
  ami_users     = [var.aws_copy_account_id]
  tags = {
    Project = "DEV"
    Owner   = "Smit"
  }
}



packer {
  required_plugins {
    amazon-ebs = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0, < 2.0.0"
    }
  }
}

build {
  sources = [
    "source.amazon-ebs.ubuntu",
  ]

  provisioner "file" {
    source      = var.artifact_path
    destination = "/tmp/webapp.zip"
  }

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo rm -rf /var/lib/apt/lists/lock /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend",
      "sudo dpkg --configure -a",
      "sudo apt-get clean",

      # Disable Ubuntu Pro/ESM repositories to prevent repo issues
      "sudo pro config set apt-news=false || true",
      "sudo pro detach || true",
      "sudo rm -f /etc/apt/sources.list.d/ubuntu-esm-infra.list",
      "sudo rm -f /etc/apt/sources.list.d/ubuntu-esm-apps.list",
      "sudo sed -i '/esm.ubuntu.com/d' /etc/apt/sources.list",

      # Run APT update without installing apt-utils
      "sudo apt-get update --allow-releaseinfo-change",
      "sudo apt-get upgrade -y",
      "sudo apt install -y unzip curl",
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -",
      "sudo apt-get install -y nodejs",
      "curl -o /tmp/amazon-cloudwatch-agent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
      "sudo dpkg -i -E /tmp/amazon-cloudwatch-agent.deb",
      "echo \"DB_DIALECT=${var.db_dialect}\" | sudo tee -a /etc/environment",
      "export $(cat /etc/environment | xargs)",
      "sudo useradd -m -s /bin/bash csye6225 || true",
      "sudo groupadd -f csye6225",
      "sudo usermod -aG csye6225 csye6225",
      "sudo mkdir -p /opt/csye6225/app",
      "sudo chown -R csye6225:csye6225 /opt/csye6225",
      "sudo chmod -R 755 /opt/csye6225",
      "sudo ls -ld /opt/csye6225 /opt/csye6225/app",
      "sudo -u csye6225 unzip /tmp/webapp.zip -d /opt/csye6225/app",
      "sudo -u csye6225 ls -la /opt/csye6225/app",
      "cd /opt/csye6225/app && sudo -u csye6225 npm install",
      "sudo mkdir -p /var/log/node",
      "sudo touch /var/log/node/csye6225.log",
      "sudo chown csye6225:csye6225 /var/log/node/csye6225.log",
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
      WorkingDirectory=/opt/csye6225/app
      EnvironmentFile=/etc/environment
      ExecStart=/usr/bin/env node /opt/csye6225/app/index.js >> /var/log/node/csye6225.log 2>&1
      Restart=always
      StandardOutput=append:/var/log/node/csye6225.log
      StandardError=append:/var/log/node/csye6225.log

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
