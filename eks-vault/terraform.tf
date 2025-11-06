terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "5.3.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.5"
    }
  }

  required_version = ">= 1.13.3"
}
