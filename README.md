

#  Carsties Infrastructure as Code (IaC)

This repository defines and provisions the **AWS infrastructure** for the Carsties platform using **Terraform**, **Helm**, and **Kubernetes manifests**.
It automates the setup of an **EKS cluster**, **Vault**, **External Secrets Operator**, **KMS**, **IRSA**, and related components required for secure application deployments.


## 🧠 Technologies

- **AWS**  
  - **Core Infrastructure**: VPC, EC2, EKS, IAM, KMS, Load Balancer Controller  
  - **Serverless & Messaging**: Lambda, SNS, EventBridge, S3  
- **Terraform** – Infrastructure as Code for AWS and Vault resources  
- **Kubernetes (EKS)** – Container orchestration platform  
- **Helm** – Package manager for Kubernetes applications  
- **HashiCorp Vault** – Secrets management and Kubernetes auth integration  
- **External Secrets Operator (ESO)** – Sync secrets from Vault into Kubernetes  
- **Cert-Manager** – Automated certificate management in Kubernetes  
- **IRSA (IAM Roles for Service Accounts)** – Secure AWS IAM integration with pods  
- **kubectl** – Kubernetes CLI for cluster management  
- **GitHub Actions** – CI/CD automation
- **Checkov** – Static analysis & policy‑as‑code for infrastructure

## 📁 Repository Structure

```
.
├── eks-infra/              # Terraform for core EKS infrastructure (VPC, EKS, KMS, IAM, ALB, RDS, etc.)
├── eks-vault/              # Terraform for Vault integration and IAM policies
├── lambda/                 # Optional AWS Lambda resources (SNS, S3, EventBridge)
├── tests/
│   ├── alb/                # ALB controller test manifests
│   ├── certs/              # TLS certificate and ClusterIssuer manifests
│   ├── eso/                # External Secrets configuration (Vault + KMS)
│   └── vault/              # Vault Helm values and test workloads (IRSA test, example app)
└── README.md
```


##  Prerequisites
Before deploying, ensure you have:
| Tool        | Minimum Version | Purpose                          |
|-------------|-----------------|----------------------------------|
| AWS CLI     | latest          | Configure AWS credentials        |
| kubectl     | v1.33+          | Manage Kubernetes cluster        |
| Terraform   | v1.13+          | Provision AWS & Vault resources  |
| Helm        | v3.18+          | Install Kubernetes packages      |


## Deployment Steps

### 1. **Deploy the EKS Infrastructure**

Navigate to the `eks-infra` folder and apply Terraform:

```bash
cd eks-infra
terraform init
terraform apply -auto-approve
```

This creates:

* VPC, subnets, security groups
* EKS cluster
* IAM roles for service accounts (IRSA)
* KMS key for Vault and ESO
* Load balancer and Helm setup resources



### 2. **Configure kubectl to Access the Cluster**

```bash
aws eks update-kubeconfig --name carsties-eks-dev --region us-east-1
```

Verify connection:

```bash
kubectl get nodes
```



### 3. **Install Required Helm Components**

####  • AWS Load Balancer Controller

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --version 1.14.1 \
  --set clusterName=carsties-eks-dev \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

**Note:** The ALB Controller manifest can be found under `tests/alb/alb.yml`.



#### • External Secrets Operator (ESO)

Used for pulling secrets from AWS KMS/Vault into Kubernetes.

```bash
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --version 0.20.4 \
  --set installCRDs=true \
  --set serviceAccount.create=false \
  --set serviceAccount.name=external-secrets
```

Then apply the ESO configuration:

```bash
kubectl apply -f tests/eso/
```



#### • Cert-Manager

Used to issue and manage internal TLS certificates for Vault and applications.

```bash
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.1 \
  --set crds.enabled=true
```

Apply certificate and issuer manifests:

```bash
kubectl apply -f tests/certs/
```



### 4. **Deploy HashiCorp Vault**

Vault handles secrets and dynamic credentials for workloads inside EKS.

Create the CA secret:

```bash
kubectl get secret vault-tls -n vault -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
kubectl create secret generic vault-ca --from-file=ca.crt=ca.crt
```
 The same secret (`vault-ca`) must exist in any namespace that needs Vault TLS communication.

```bash
helm install vault hashicorp/vault \
  --version 0.31.0 \
  --namespace vault \
  -f tests/vault/values.yml
```




### 5. **Initialize and Verify Vault**

Run the following commands to initialize Vault and verify its state:

```bash
kubectl exec -n vault -it vault-0 -- vault operator init
kubectl exec -n vault -it vault-0 -- vault status
kubectl exec -n vault -it vault-0 -- vault login
kubectl exec -n vault -it vault-0 -- vault operator raft list-peers
```

If DNS is not configured, you can port-forward to access the UI locally:

```bash
kubectl port-forward -n vault svc/vault 8200:8200
```


### 6. **Deploy the Vault Integration**

Navigate to the `eks-vault` folder:

```bash
cd eks-vault
```

First, create a `terraform.tfvars` file in this folder with the following variables:

```hcl
address     = "https://<vault-server-address>"
token       = "<vault-root-token>"
config_path = "~/.kube/config"
```

This file provides:
- **Vault server address** – the URL of your Vault instance  
- **Vault root token** – the root token used by Terraform to authenticate against Vault  
- **Kubeconfig path** – the path to your EKS cluster’s kubeconfig file  

Then initialize and apply Terraform:

```bash
terraform init
terraform apply -auto-approve
```

This creates:

- **Vault secrets engine mount** – `kv-v2` for storing application secrets  
- **Vault KV secret** – example secret at `carsties/secret` containing email and password values  
- **Vault policies** –  
  - `carsties-policy`: grants read-only access to the `carsties/*` path  
  - `admin-policy`: grants full administrative capabilities across all paths  
- **Vault Kubernetes auth backend** – enabled at path `kubernetes`  
- **Kubernetes CA config** – retrieved from the `kube-root-ca.crt` ConfigMap in the `kube-system` namespace  
- **Vault Kubernetes auth backend config** – connects Vault to the EKS cluster using the CA certificate and API endpoint  
- **Vault Kubernetes role** – `carsties-role`, bound to the `vault-auth` service account in the `default` namespace, associated with the `carsties-policy`, with a token TTL of 3600 seconds  



### 7. **Validate IRSA and Vault Integration**

You can use the provided test manifests to validate IAM roles for service accounts (IRSA) and secret injection:

```bash
kubectl apply -f tests/vault/irsa-test.yml
kubectl apply -f tests/vault/app.yml
```

Check logs:

```bash
kubectl logs -n vault irsa-test
kubectl logs -f deployment/app
kubectl get ingress -n vault
```

If everything is configured correctly, the app should successfully pull secrets from Vault using ESO + KMS + IRSA.



## 🧩 Components Overview

| Component                           | Description                                                |
| ----------------------------------- | ---------------------------------------------------------- |
| **EKS**                             | Managed Kubernetes cluster for running workloads           |
| **Vault**                           | Secrets management and encryption                          |
| **External Secrets Operator (ESO)** | Syncs secrets from Vault/KMS to Kubernetes Secrets         |
| **Cert-Manager**                    | Issues and renews TLS certificates for Vault and workloads |
| **AWS Load Balancer Controller**    | Manages ingress and AWS ALB integration                    |
| **IRSA**                            | IAM Role for Service Accounts (secure AWS access for Pods) |





## 🧰 Useful Commands

```bash
# Terraform
terraform fmt -recursive
terraform validate
terraform plan
terraform apply -auto-approve

# Kubernetes
kubectl get pods -A
kubectl get ingress -A
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Helm
helm list -A
helm uninstall <release> -n <namespace>
```


---

This project is licensed under the MIT License.
