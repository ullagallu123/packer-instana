packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "amz2023" {
  ami_name      = "dispatch-{{timestamp}}"
  instance_type = "t2.micro"
  region = "ap-south-1"
  source_ami = "ami-0a4408457f9a03be3"
  ssh_username = "ec2-user"
}

build {
  name    = "dispatch"
  sources = ["source.amazon-ebs.amz2023"]

  provisioner "file" {
    source      = "dispatch.sh"
    destination = "/tmp/dispatch.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/dispatch.sh",
      "sudo /tmp/dispatch.sh"
    ]
  }
}