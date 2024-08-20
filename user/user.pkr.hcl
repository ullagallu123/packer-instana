packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}
source "amazon-ebs" "ubuntu-24" {
  ami_name      = "user-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami    = "ami-0ad21ae1d0696ad58"
  ssh_username  = "ubuntu"
}

build {
  name    = "user"
  sources = ["source.amazon-ebs.ubuntu-24"]

  provisioner "file" {
    source      = "user.sh"
    destination = "/tmp/user.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/user.sh",
      "sudo /tmp/user.sh"
      ]
  }
}
