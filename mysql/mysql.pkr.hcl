packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

# Data block to fetch the Ubuntu 24.04 AMI dynamically
data "aws_ami" "ubuntu_24" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical's official owner ID
}

source "amazon-ebs" "ubuntu-24" {
  ami_name      = "mysql-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami    = data.aws_ami.ubuntu_24.id
  ssh_username  = "ubuntu"
}

build {
  name    = "mysql"
  sources = ["source.amazon-ebs.ubuntu-24"]

  provisioner "file" {
    source      = "mysql.sh"
    destination = "/tmp/mysql.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/mysql.sh",
      "sudo /tmp/mysql.sh"
      ]
  }
}
