# Get current AWS account ID
data "aws_caller_identity" "current" {}

# S3 bucket
resource "aws_s3_bucket" "resume" {
  bucket = "${var.project_name}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_website_configuration" "resume" {
  bucket = aws_s3_bucket.resume.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "resume" {
  bucket                  = aws_s3_bucket.resume.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "resume" {
  bucket = aws_s3_bucket.resume.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.resume.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.resume]
}

# DynamoDB table
resource "aws_dynamodb_table" "visitor_count" {
  name         = "${var.project_name}-visitor-count"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}




# IAM role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.visitor_count.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

# Lambda function
data "archive_file" "lambda" {
  type        = "zip"
  output_path = "/tmp/lambda.zip"

  source {
    content  = <<EOF
import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')

def handler(event, context):
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    response = table.update_item(
        Key={'id': 'visitors'},
        UpdateExpression='ADD #count :increment',
        ExpressionAttributeNames={'#count': 'count'},
        ExpressionAttributeValues={':increment': 1},
        ReturnValues='UPDATED_NEW'
    )
    count = int(response['Attributes']['count'])
    return {
        'statusCode': 200,
        'headers': {'Access-Control-Allow-Origin': '*'},
        'body': json.dumps({'count': count})
    }
EOF
    filename = "index.py"
  }
}

resource "aws_lambda_function" "visitor_counter" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "python3.13"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_count.name
    }
  }
}



# API Gateway
resource "aws_apigatewayv2_api" "visitor" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
  }
}

resource "aws_apigatewayv2_integration" "visitor" {
  api_id                 = aws_apigatewayv2_api.visitor.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "visitor" {
  api_id    = aws_apigatewayv2_api.visitor.id
  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.visitor.id}"
}

resource "aws_apigatewayv2_stage" "visitor" {
  api_id      = aws_apigatewayv2_api.visitor.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor.execution_arn}/*/*"
}



# CloudFront
resource "aws_cloudfront_distribution" "resume" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "${var.project_name} distribution"

  origin {
    origin_id   = "S3Origin"
    domain_name = aws_s3_bucket_website_configuration.resume.website_endpoint

    custom_origin_config {
     http_port                = 80
     https_port               = 443
    origin_protocol_policy   = "http-only"
     origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
