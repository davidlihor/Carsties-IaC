

#  Carsties Infrastructure as Code (IaC)

This repository defines and provisions the **AWS infrastructure** for the Carsties platform using **Terraform**, **Helm**, and **Kubernetes manifests**.
It automates the setup of an **EKS cluster**, **Vault**, **External Secrets Operator**, **KMS**, **IRSA**, and related components required for secure application deployments.



# 🧠 Tehnologies

AWS • Terraform • Kubernetes (EKS) • Helm • HashiCorp Vault • External Secrets Operator (ESO) • AWS KMS • Cert-Manager • AWS Load Balancer Controller • IRSA (IAM Roles for Service Accounts) • kubectl • GitHub Actions

# 📁 Repository Structure

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

---

#  Prerequisites

Before deploying, ensure you have:

* **AWS CLI** configured with valid credentials (`aws configure`)
* **kubectl** v1.33+
* **Terraform** v1.13+
* **Helm** v3.18+
* Access to an **S3 bucket** and **DynamoDB table** for Terraform state (recommended)
* Proper IAM permissions to manage EKS, KMS, IAM, and VPC resources

---

# Deployment Steps

### 1. Deploy the EKS Infrastructure

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

---

### 2. Configure kubectl to Access the Cluster

```bash
aws eks update-kubeconfig --name carsties-eks-dev --region us-east-1
```

Verify connection:

```bash
kubectl get nodes
```

---

### 3. Install Required Helm Components

####  • AWS Load Balancer Controller

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --version 1.14.1 \
  --set clusterName=carsties-eks-dev \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

> **Note:** The ALB Controller manifest can be found under `tests/alb/alb.yml`.

---

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

---

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

---

### 4. Deploy HashiCorp Vault

Vault handles secrets and dynamic credentials for workloads inside EKS.

Create the CA secret:

```bash
kubectl get secret vault-tls -n vault -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
kubectl create secret generic vault-ca --from-file=ca.crt=ca.crt
```
> The same secret (`vault-ca`) must exist in any namespace that needs Vault TLS communication.

```bash
helm install vault hashicorp/vault \
  --version 0.31.0 \
  --namespace vault \
  -f tests/vault/values.yml
```



---

### 5. Initialize and Verify Vault

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

---

### 6. Validate IRSA and Vault Integration

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

---

## 🧩 Components Overview

| Component                           | Description                                                |
| ----------------------------------- | ---------------------------------------------------------- |
| **EKS**                             | Managed Kubernetes cluster for running workloads           |
| **Vault**                           | Secrets management and encryption                          |
| **External Secrets Operator (ESO)** | Syncs secrets from Vault/KMS to Kubernetes Secrets         |
| **Cert-Manager**                    | Issues and renews TLS certificates for Vault and workloads |
| **AWS Load Balancer Controller**    | Manages ingress and AWS ALB integration                    |
| **IRSA**                            | IAM Role for Service Accounts (secure AWS access for Pods) |



---

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

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
