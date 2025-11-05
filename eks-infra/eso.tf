resource "aws_iam_role" "eso" {
  name = "eso-secretsmanager-role"

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
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eso_secretsmanager" {
  name = "eso-secretsmanager-policy"
  role = aws_iam_role.eso.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "kubernetes_service_account" "eso" {
  metadata {
    name      = "external-secrets"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eso.arn
    }
  }
}
