resource "aws_placement_group" "managers" {
  name     = "ec2-docker-swarm-managers"
  strategy = "spread"
}

resource "aws_placement_group" "workers_a" {
  name     = "ec2-docker-swarm-workers-a"
  strategy = "spread"
}
