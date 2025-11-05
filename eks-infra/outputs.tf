output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security Group ID for EKS Cluster"
  value       = module.eks.cluster_security_group_id
}

output "current_region" {
  description = "Current AWS Region"
  value       = var.region
}

output "vault_kms_key_arn" {
  description = "KMS Key ARN"
  value = aws_kms_key.vault.arn
}
