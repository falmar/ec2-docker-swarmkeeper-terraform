packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.5"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-ami" "ubuntu_docker_arm64" {
  filters = {
    virtualization-type = "hvm"
    name                = "ubuntu/images/*ubuntu-jammy-22.04-arm64-server*"
    root-device-type    = "ebs"
    architecture        = "arm64"
  }
  owners      = ["amazon"]
  most_recent = true
}

source "amazon-ebs" "ubuntu_docker_arm64" {
  #  skip_create_ami = true

  ami_name      = "ubuntu-22-docker-24-arm64-{{timestamp}}"
  source_ami    = data.amazon-ami.ubuntu_docker_arm64.id
  instance_type = "t4g.small"
  region        = "eu-central-1"
  ssh_username  = "ubuntu"
  encrypt_boot  = true

  ami_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name          = "ubuntu-22-docker-24-arm64-{{timestamp}}"
    DockerSwarm   = "true"
    DockerVersion = "24"
  }
}

build {
  sources = [
    "source.amazon-ebs.ubuntu_docker_arm64"
  ]

  provisioner "shell" {
    script = "./packer/install_docker.sh"
  }
}
