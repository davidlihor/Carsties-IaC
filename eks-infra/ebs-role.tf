module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.1"

  name                  = "${module.eks.cluster_name}-ebs-csi-irsa"
  attach_ebs_csi_policy = true

  policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}