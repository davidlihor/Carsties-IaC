variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instanceName" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "bytecraft"
}

variable "environment" {
  description = "Environment of the EC2 instance"
  type        = string
  default     = "dev"
}