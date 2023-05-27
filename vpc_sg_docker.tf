resource "aws_security_group" "docker_plane" {
  vpc_id = aws_vpc.docker_swarm.id

  # for communication with and between manager nodes
  ingress {
    from_port = 2377
    to_port   = 2377
    protocol  = "tcp"
    self      = true

    security_groups = [
      aws_security_group.docker_overlay.id
    ]
  }

  tags = {
    Name = "docker-plane"
  }
}

resource "aws_security_group" "docker_ingress" {
  vpc_id = aws_vpc.docker_swarm.id

  # ingress ports on worker nodes

  # nginx
  ingress {
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    self             = true
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups  = [
      aws_security_group.lb_default.id
    ]
  }

  tags = {
    Name = "docker-ingress"
  }
}
resource "aws_security_group" "docker_overlay" {
  vpc_id = aws_vpc.docker_swarm.id

  # overlay network traffic
  ingress {
    from_port = 4789
    to_port   = 4789
    protocol  = "udp"
    self      = true
  }

  # overlay network node discovery
  ingress {
    from_port = 7946
    to_port   = 7946
    protocol  = "tcp"
    self      = true
  }
  ingress {
    from_port = 7946
    to_port   = 7946
    protocol  = "udp"
    self      = true
  }

  tags = {
    Name = "docker-overlay"
  }
}
