resource "vault_mount" "kvv2" {
  path        = "kv-v2"
  type        = "kv-v2"
  description = "Key-Value v2 secrets engine"
}

resource "vault_kv_secret_v2" "carsties" {
  mount = vault_mount.kvv2.path
  name  = "carsties/secret"

  data_json = jsonencode({
    email = "testuser@email.com"
    password = "testpass"
  })
}

resource "vault_policy" "carsties" {
  name   = "carsties-policy"
  policy = <<-EOT
    path "kv-v2/data/carsties/*" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_policy" "admin" {
  name   = "admin-policy"
  policy = <<-EOT
    path "*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
  EOT
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

data "kubernetes_config_map" "root_ca" {
  metadata {
    name      = "kube-root-ca.crt"
    namespace = "kube-system"
  }
}

resource "vault_kubernetes_auth_backend_config" "example" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://kubernetes.default.svc:443"
  kubernetes_ca_cert = data.kubernetes_config_map.root_ca.data["ca.crt"]
}

resource "vault_kubernetes_auth_backend_role" "carsties" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "carsties-role"
  bound_service_account_names      = ["vault-auth"]
  bound_service_account_namespaces = ["default"]
  token_policies                   = [vault_policy.carsties.name]
  token_ttl                        = 3600
}