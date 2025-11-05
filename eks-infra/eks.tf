module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.2.0"

  name               = local.cluster_name
  kubernetes_version = "1.34"
  enable_irsa        = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access                   = true
  endpoint_private_access                  = true
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.arn
    }
  }

  eks_managed_node_groups = {
    one = {
      name           = "node-group-1"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m7i-flex.large"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2

      metadata_options = {
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }
    }

    two = {
      name           = "node-group-2"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m7i-flex.large"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    
      metadata_options = {
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }
    }
  }

  tags = {
    Name        = local.cluster_name
    Project     = var.projectName
    Environment = var.environment
  }
}