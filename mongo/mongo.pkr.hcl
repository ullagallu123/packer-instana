packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "ubuntu-22" {
  ami_name      = "mongo-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami = "ami-0ad21ae1d0696ad58"
  ssh_username = "ubuntu"
}

build {
  name    = "mongo"
  sources = ["source.amazon-ebs.ubuntu-22"]

  provisioner "file" {
    source      = "mongo.sh"
    destination = "/tmp/mongo.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/mongo.sh",
      "sudo /tmp/mongo.sh"
      ]
  }
}