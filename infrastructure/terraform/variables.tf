variable "aws_region" {
  default     = "us-east-1"
  description = "AWS region to deploy resources"
}

variable "project_name" {
  default     = "cloud-resume-tf"
  description = "Project name used as prefix for all resources"
}

variable "lambda_function_name" {
  default     = "visitor-counter-tf"
  description = "Name for the Lambda function"
}