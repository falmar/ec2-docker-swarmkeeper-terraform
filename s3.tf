resource "aws_s3_bucket" "docker_swarm" {
  bucket = "docker-swarm"

  tags = {

  }

  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "docker_swarm_encryption" {
  bucket = aws_s3_bucket.docker_swarm.bucket

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.docker_swarm.id
  acl    = "private"
}
