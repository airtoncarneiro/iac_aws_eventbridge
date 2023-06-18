output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "invoke_url" {
  value = "https://${aws_api_gateway_deployment.deployment.rest_api_id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.deployment.stage_name}"
}