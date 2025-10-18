variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instanceName" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "carsties-ec2"
}

variable "clusterName" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "carsties-eks"
}

variable "projectName" {
  description = "Name of the project"
  type        = string
  default     = "dev"
}

variable "environment" {
  description = "Environment of the project"
  type        = string
  default     = "dev"
}