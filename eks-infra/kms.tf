resource "aws_kms_key" "vault" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_secretsmanager_secret" "vault_kms_arn" {
  name = "vault/kmsArn-dev-key18"
}

resource "aws_secretsmanager_secret_version" "vault_kms_arn_value" {
  secret_id     = aws_secretsmanager_secret.vault_kms_arn.id
  secret_string = aws_kms_key.vault.arn
}

resource "aws_iam_role" "vault" {
  name = "vault-kms-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:vault:vault"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vault_kms" {
  name = "vault-kms-policy"
  role = aws_iam_role.vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ]
        Resource = aws_kms_key.vault.arn
      }
    ]
  })
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_service_account" "vault" {
  metadata {
    name      = "vault"
    namespace = kubernetes_namespace.vault.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.vault.arn
    }
  }
}

resource "kubernetes_cluster_role_binding" "vault_tokenreview" {
  metadata {
    name = "vault-server-tokenreview-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault.metadata[0].name
    namespace = kubernetes_service_account.vault.metadata[0].namespace
  }
}

resource "kubernetes_service_account" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = "default"
  }
}

resource "kubernetes_secret" "vault_auth_token" {
  metadata {
    name      = "vault-auth-token"
    namespace = kubernetes_service_account.vault_auth.metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.vault_auth.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role_binding" "vault_auth_tokenreview" {
  metadata {
    name = "vault-auth-tokenreview-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault_auth.metadata[0].name
    namespace = kubernetes_service_account.vault_auth.metadata[0].namespace
  }
}