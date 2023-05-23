resource "aws_key_pair" "main" {
  public_key = file("./ssh_keys/main.pub")
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data aws_ami "arm_ubuntu_docker" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = [
      "ubuntu-22-docker-24*"
    ]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

#data aws_ami "amd_ubuntu_docker" {
#  most_recent = true
#  owners      = ["self"]
#
#  filter {
#    name   = "name"
#    values = [
#      "ubuntu-22-docker-24*"
#    ]
#  }
#
#  filter {
#    name   = "architecture"
#    values = ["x86_64"]
#  }
#}
