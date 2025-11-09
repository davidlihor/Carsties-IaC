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

  backend "s3" {
    bucket  = "carsties-terraform-state"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    use_lockfile = true
  }

  required_version = ">= 1.13.3"
}
