packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}
source "amazon-ebs" "ubuntu-24" {
  ami_name      = "cart-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami    = "ami-0ad21ae1d0696ad58"
  ssh_username  = "ubuntu"
}

build {
  name    = "cart"
  sources = ["source.amazon-ebs.ubuntu-24"]

  provisioner "file" {
    source      = "cart.sh"
    destination = "/tmp/cart.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cart.sh",
      "sudo /tmp/cart.sh"
      ]
  }
}
