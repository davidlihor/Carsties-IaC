terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.0.2"
    }
  }

  required_version = ">= 1.13.3"
}
