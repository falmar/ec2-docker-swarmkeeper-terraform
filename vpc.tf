resource "aws_vpc" "docker_swarm" {
  cidr_block = "172.16.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {

  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.docker_swarm.id

  tags = {

  }
}
resource "aws_route" "gw" {
  route_table_id = aws_vpc.docker_swarm.default_route_table_id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

