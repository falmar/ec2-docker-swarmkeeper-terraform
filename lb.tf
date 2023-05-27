resource "aws_security_group" "lb_default" {
  description = "Allow outbound traffic from the load balancer to the instances"
  vpc_id      = aws_vpc.docker_swarm.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.public.*.cidr_block
  }
}

resource "aws_lb" "docker_swarm" {
  name               = "docker-swarm"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [
    aws_default_security_group.default.id,
    aws_security_group.lb_default.id,
    aws_security_group.http.id,
  ]
  subnets      = aws_subnet.public.*.id
  enable_http2 = true

  tags = {
    Name = "docker-swarm"
  }
  depends_on = [
    aws_default_security_group.default,
    aws_subnet.public
  ]
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.docker_swarm.arn

  port     = "80"
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404 - Not Found"
      status_code  = "404"
    }
  }

  tags = {
    Name = "http"
  }
}



output "lb_public_dns" {
  value = aws_lb.docker_swarm.dns_name
}
