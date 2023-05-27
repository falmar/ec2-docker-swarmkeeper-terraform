resource "aws_lb_listener_rule" "nginx" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  depends_on = [
    aws_lb_target_group.nginx
  ]
}

resource "aws_lb_target_group" "nginx" {
  port       = 3000
  protocol   = "HTTP"
  vpc_id     = aws_vpc.docker_swarm.id

  slow_start = 0
  target_type = "instance"
  deregistration_delay = 30
  load_balancing_algorithm_type = "round_robin"
  load_balancing_cross_zone_enabled = true

  health_check {
    path = "/"
    enabled = true
    healthy_threshold = 3
    unhealthy_threshold = 4
    interval = 60
    matcher = "200"
  }

  stickiness {
    type = "lb_cookie"
    enabled = false
  }

  depends_on = [
    aws_lb_listener.http
  ]
}

resource "aws_autoscaling_attachment" "nginx" {
  lb_target_group_arn    = aws_lb_target_group.nginx.arn
  autoscaling_group_name = aws_autoscaling_group.docker_worker.name
}
