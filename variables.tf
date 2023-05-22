variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_subnet_azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
