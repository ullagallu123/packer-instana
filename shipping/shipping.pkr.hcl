packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}
source "amazon-ebs" "ubuntu-24" {
  ami_name      = "shipping-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami    = "ami-0ad21ae1d0696ad58"
  ssh_name  = "ubuntu"
}

build {
  name    = "shipping"
  sources = ["source.amazon-ebs.ubuntu-24"]

  provisioner "file" {
    source      = "shipping.sh"
    destination = "/tmp/shipping.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/shipping.sh",
      "sudo /tmp/shipping.sh"
      ]
  }
}
