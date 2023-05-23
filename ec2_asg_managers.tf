resource "aws_iam_instance_profile" "docker_manager" {
  name = "docker-manager"
  role = aws_iam_role.docker_manager.name

  tags = {
    Name = "docker_manager"
  }
}
resource "aws_iam_role" "docker_manager" {
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "docker-manager"
  }
}
resource "aws_iam_role_policy_attachment" "docker_manager_join" {
  policy_arn = aws_iam_policy.docker_manager_join.arn
  role       = aws_iam_role.docker_manager.name
}

# add policy to read S3 object to join the docker swarm
resource "aws_iam_policy" "docker_manager_join" {
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.docker_swarm.arn}/docker/join-manager.sh",
          "${aws_s3_bucket.docker_swarm.arn}/docker/docker-login.sh"
        ]
      }
    ]
  })
}

resource "aws_launch_template" "asg" {
  name_prefix = "docker_manager"
  image_id    = data.aws_ami.arm_ubuntu_docker.id

  key_name = aws_key_pair.main.key_name

  # free until 2023-12-31
  instance_type          = "t4g.small"
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.docker_manager.arn
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      encrypted  = true
      volume_size = 8
      volume_type = "gp3"
      throughput = 125
      iops = 3000
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true

    security_groups = [
      aws_security_group.internet.id,
      aws_security_group.ssh.id,
      aws_security_group.docker_plane.id,
      aws_security_group.docker_overlay.id,
    ]
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  user_data = base64encode("")

  tags = {
    "DockerPlatform"     = "linux"
    "DockerArchitecture" = "arm64"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "docker_manager" {
  placement_group = aws_placement_group.managers.id

  name_prefix = "docker-manager"

  min_size = 1
  desired_capacity = 1
  max_size = 3

  capacity_rebalance        = true
  force_delete              = true
  vpc_zone_identifier       = aws_subnet.public.*.id
  default_instance_warmup   = 60
  default_cooldown          = 15
  health_check_grace_period = 30
  metrics_granularity       = "1Minute"
  #  protect_from_scale_in   = true

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 100

#      spot_instance_pools      = 0
#      spot_allocation_strategy = "capacity-optimized"
#      spot_max_price           = "0.0"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.asg.id
        version            = aws_launch_template.asg.latest_version
      }
    }
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      skip_matching          = true
      min_healthy_percentage = 70
      instance_warmup        = 60
    }
  }

  tag {
    key                 = "Name"
    value               = "docker-manager"
    propagate_at_launch = true
  }
  tag {
    key                 = "DockerSwarm"
    value               = true
    propagate_at_launch = true
  }
  tag {
    key                 = "SwarmManager"
    value               = true
    propagate_at_launch = true
  }

  depends_on = [
    aws_launch_template.asg,
    aws_vpc.docker_swarm
  ]
}
