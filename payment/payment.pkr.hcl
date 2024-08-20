packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}
source "amazon-ebs" "ubuntu-24" {
  ami_name      = "payment-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "ap-south-1"
  source_ami    = "ami-0ad21ae1d0696ad58"
  ssh_username  = "ubuntu"
}

build {
  name    = "payment"
  sources = ["source.amazon-ebs.ubuntu-24"]

  provisioner "file" {
    source      = "payment.sh"
    destination = "/tmp/payment.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /tmp/payment.sh",
      "sudo /tmp/payment.sh"
      ]
  }
}
