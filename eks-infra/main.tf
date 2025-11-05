provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
  cluster_name = "${var.clusterName}-${var.environment}"
  instance_name = "${var.instanceName}-${var.environment}"
}