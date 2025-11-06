output "kvv2_mount_path" {
  description = "KV v2 mount path"
  value       = vault_mount.kvv2.path
}

output "carsties_secret_name" {
  description = "Secret name in KV v2"
  value       = vault_kv_secret_v2.carsties.name
}

output "carsties_policy_name" {
  description = "Carsties policy name"
  value       = vault_policy.carsties.name
}

output "admin_policy_name" {
  description = "Admin policy name"
  value       = vault_policy.admin.name
}

output "kubernetes_auth_backend_path" {
  description = "Kubernetes auth backend path"
  value       = vault_auth_backend.kubernetes.path
}

output "carsties_role_name" {
  description = "Auth role for vault-auth SA"
  value       = vault_kubernetes_auth_backend_role.carsties.role_name
}

output "kubernetes_ca_cert" {
  description = "CA cert from kube-root-ca.crt"
  value       = data.kubernetes_config_map.root_ca.data["ca.crt"]
}
