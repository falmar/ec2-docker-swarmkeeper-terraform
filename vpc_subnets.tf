data "aws_availability_zones" "subnet_availability_zones" {
  state = "available"

  filter {
    name   = "zone-name"
    values = var.aws_subnet_azs
  }
}

# public subnet
# 3 public subnets
# range 172.16.[0-2].1 ~ 172.16.[0-2].254
resource "aws_subnet" "public" {
  # max 3
  count = 3

  vpc_id                  = aws_vpc.docker_swarm.id
  cidr_block              = cidrsubnet(aws_vpc.docker_swarm.cidr_block, 8, count.index)
  map_public_ip_on_launch = true

  availability_zone_id = element(data.aws_availability_zones.subnet_availability_zones.zone_ids, count.index)

  tags = {
    Name = "public-${element(data.aws_availability_zones.subnet_availability_zones.names, count.index)}"
  }
}
