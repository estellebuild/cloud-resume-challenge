output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.resume.domain_name}"
}

output "api_endpoint" {
  description = "API Gateway endpoint"
  value       = "${aws_apigatewayv2_stage.visitor.invoke_url}/count"
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.resume.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.visitor_count.name
}