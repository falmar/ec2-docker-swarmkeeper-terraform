resource "aws_s3_bucket" "docker_swarm" {
  bucket_prefix = "docker-swarm-"

  tags = {

  }

  lifecycle {
    prevent_destroy = false
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "docker_swarm_encryption" {
  bucket = aws_s3_bucket.docker_swarm.bucket

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  depends_on = [
    aws_s3_bucket.docker_swarm,
  ]
}
resource "aws_s3_bucket_ownership_controls" "docker_swarm" {
  bucket = aws_s3_bucket.docker_swarm.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [
    aws_s3_bucket.docker_swarm,
  ]
}
resource "aws_s3_bucket_public_access_block" "docker_swarm" {
  bucket = aws_s3_bucket.docker_swarm.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [
    aws_s3_bucket.docker_swarm,
    aws_s3_bucket_acl.docker_swarm,
  ]
}

resource "aws_s3_bucket_acl" "docker_swarm" {
  bucket = aws_s3_bucket.docker_swarm.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket.docker_swarm,
    aws_s3_bucket_ownership_controls.docker_swarm,
  ]
}

output "docker_swarm_bucket" {
  value = aws_s3_bucket.docker_swarm.bucket
}
