resource "aws_iam_instance_profile" "docker_worker" {
  name = "docker-worker"
  role = aws_iam_role.docker_worker.name

  tags = {
    Name = "docker-worker"
  }
}
resource "aws_iam_role" "docker_worker" {
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "docker-worker"
  }
}
resource "aws_iam_role_policy_attachment" "docker_worker_join" {
  policy_arn = aws_iam_policy.docker_worker_join.arn
  role       = aws_iam_role.docker_worker.name
}

# add policy to read S3 object to join the docker swarm
resource "aws_iam_policy" "docker_worker_join" {
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.docker_swarm.arn}/docker/join-worker.sh",
          "${aws_s3_bucket.docker_swarm.arn}/docker/docker-login.sh"
        ]
      }
    ]
  })
}

resource "aws_launch_template" "docker_worker" {
  name     = "docker-worker"
  image_id = data.aws_ami.arm_ubuntu_docker.id

  key_name = aws_key_pair.main.key_name

  # free until 2023-12-31
  instance_type          = "t4g.nano"
  update_default_version = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.docker_worker.arn
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 8
      volume_type           = "gp3"
      throughput            = 125
      iops                  = 3000
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true

    security_groups = [
      aws_security_group.internet.id,
      aws_security_group.ssh.id, # should only access from bastion
      aws_security_group.docker_ingress.id,
      aws_security_group.docker_overlay.id,
    ]
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  user_data = base64encode(<<EOF
#!/bin/bash
sleep 5;
EOF
  )

  tags = {
    "DockerPlatform"     = "linux"
    "DockerArchitecture" = "arm64"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "docker_worker" {
  placement_group = aws_placement_group.workers_a.id

  name = "docker-worker"

  min_size         = 0
  desired_capacity = 3
  max_size         = 6

  capacity_rebalance        = true
  force_delete              = false
  vpc_zone_identifier       = aws_subnet.public.*.id
  default_instance_warmup   = 60
  default_cooldown          = 60
  health_check_grace_period = 30
  metrics_granularity       = "1Minute"
  #  protect_from_scale_in   = true

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0

      spot_instance_pools      = 0
      spot_allocation_strategy = "price-capacity-optimized"
      spot_max_price           = "0.014"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.docker_worker.id
        version            = aws_launch_template.docker_worker.latest_version
      }

      #      override {
      #        instance_type = "t4g.nano"
      #      }
      #
      #      override {
      #        instance_type = "t4g.micro"
      #      }
    }
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      skip_matching          = true
      min_healthy_percentage = 90
    }
  }
  tag {
    key                 = "Name"
    value               = "docker-worker"
    propagate_at_launch = true
  }
  tag {
    key                 = "DockerSwarm"
    value               = true
    propagate_at_launch = true
  }
  tag {
    key                 = "SwarmWorker"
    value               = true
    propagate_at_launch = true
  }

  tag {
    key                 = "LifecycleHookName"
    propagate_at_launch = true
    value               = "worker-drain"
  }

  lifecycle {
    ignore_changes = [
      load_balancers,
      target_group_arns
    ]
  }

  depends_on = [
    aws_launch_template.docker_worker,
    aws_vpc.docker_swarm
  ]
}

resource "aws_autoscaling_lifecycle_hook" "docker_worker" {
  name                   = "worker-drain"
  autoscaling_group_name = aws_autoscaling_group.docker_worker.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 120 # 30s
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"

  // TODO: add notification
  #  notification_metadata = jsonencode({
  #
  #  })
}
