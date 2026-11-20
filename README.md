# Terraform EKS Cluster

Production-style **Amazon EKS** cluster provisioned end-to-end with **Terraform** — VPC networking, managed node groups, IAM Roles for Service Accounts (IRSA), and core cluster add-ons, following the same patterns I use for infrastructure-as-code at work.

## Architecture

- **VPC** — 3 AZs, private subnets for nodes, public subnets for load balancers, single NAT gateway, VPC flow logs off by default
- **EKS control plane** — configurable Kubernetes version, private + public endpoint access, CloudWatch control-plane logging
- **Managed node groups** — separate system and application node groups with launch templates, taints/labels, and autoscaling bounds
- **IRSA** — IAM role bound to a Kubernetes service account via the cluster OIDC provider (least-privilege, no node-wide credentials)
- **Add-ons** — VPC CNI, CoreDNS, kube-proxy, and EBS CSI driver managed by EKS

## Layout

```
.
├── versions.tf      # Terraform + provider version pins
├── providers.tf     # AWS provider configuration
├── variables.tf     # Inputs (region, cluster name, versions, node sizing)
├── main.tf          # VPC + EKS composition
├── outputs.tf       # Cluster endpoint, CA data, kubeconfig helpers
└── .gitignore
```

## Usage

```bash
terraform init
terraform plan  -var="cluster_name=demo-eks" -var="region=us-east-1"
terraform apply -var="cluster_name=demo-eks" -var="region=us-east-1"

aws eks update-kubeconfig --name demo-eks --region us-east-1
kubectl get nodes
```

## Notes

- State is configured for a local backend in this example; for team use, switch to an S3 backend with DynamoDB locking.
- Node groups use managed AMIs and are sized via variables so the same code serves dev and production shapes.

## Skills demonstrated

Terraform module composition · Amazon EKS · VPC design · IRSA / IAM least privilege · Kubernetes node-group operations
