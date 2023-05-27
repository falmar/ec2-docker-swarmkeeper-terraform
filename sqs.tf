resource "aws_sqs_queue" "plane_queue" {
  name       = "swarmkeeper_node_drain.fifo"
  fifo_queue = true

  message_retention_seconds   = 60 * 5 // 5 minutes
  visibility_timeout_seconds  = 0
  content_based_deduplication = true
}
output "plane_queue_url" {
  value = aws_sqs_queue.plane_queue.url
}

resource "aws_sqs_queue" "remove_queue" {
  name       = "swarmkeeper_node_remove.fifo"
  fifo_queue = true

  delay_seconds = 60 * 5 // 5 minutes
  message_retention_seconds   = 60 * 60 // 1 hour
  visibility_timeout_seconds  = 0
  content_based_deduplication = true
}
output "remove_queue_url" {
  value = aws_sqs_queue.remove_queue.url
}
