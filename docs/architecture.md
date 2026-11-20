# Architecture — terraform-eks-cluster

What this configuration builds, and why each choice was made.

## Topology

```
                        ┌──────────────────────── AWS account ────────────────────────┐
                        │  VPC (10.0.0.0/16)                                          │
  kubectl / CI ───────► │   ┌─────────────┐      3 Availability Zones                 │
  (AWS IAM auth)        │   │ EKS control │      ┌──────────────┬──────────────┐      │
                        │   │   plane     │      │ Public       │ Private      │      │
                        │   │ (managed)   │      │ subnets      │ subnets      │      │
                        │   └──────┬──────┘      │ (LBs, NAT)   │ (nodes)      │      │
                        │          │             └──────────────┴───────┬───────┘      │
                        │   Node group: system (t3.medium, tainted)    │              │
                        │   Node group: app    (t3.large, scales 2–6)  │              │
                        │                                              │              │
                        │   Add-ons: CoreDNS · kube-proxy · VPC CNI · EBS CSI       │
                        └──────────────────────────────────────────────────────────────┘
```

## Design decisions

**Private subnets for nodes, public only for load balancers and NAT.**
Nodes never get public IPs. Outbound traffic (image pulls, AWS APIs) goes through a
NAT gateway. Subnets carry the `kubernetes.io/role/elb` and
`kubernetes.io/role/internal-elb` tags so the AWS load-balancer controller can
discover where to place internet-facing vs internal load balancers.

**Two managed node groups, not one.**
The `system` group is small and tainted (`CriticalAddonsOnly`) so cluster-critical
workloads (CoreDNS, monitoring agents) are insulated from application churn. The
`app` group scales 2–6 nodes on t3.large for general workloads. Separating them
means an app deploy storm can never starve the platform layer.

**IRSA instead of node-wide credentials.**
The EBS CSI driver needs AWS permissions. Rather than granting them to every node
(and therefore every pod), an IAM role is bound — via the cluster's OIDC provider —
to exactly one Kubernetes service account. A compromised pod elsewhere in the
cluster gets nothing. This is the least-privilege pattern EKS is designed around.

**Managed add-ons.**
CoreDNS, kube-proxy, the VPC CNI, and the EBS CSI driver are EKS-managed add-ons:
AWS tracks compatible versions at cluster upgrade time instead of the operator
hand-editing DaemonSets. `most_recent = true` keeps them current within the
cluster's Kubernetes version.

**Control-plane logging on.**
API, audit, authenticator, controller-manager, and scheduler logs go to CloudWatch —
the audit trail you need the first time someone asks "who deleted that namespace?"

## What is deliberately NOT here

- **No remote backend committed** — `versions.tf` shows the S3 + DynamoDB backend
  commented out. State holds sensitive data; each team wires its own bucket.
- **No secrets in Terraform** — nothing in this repo stores credentials. Workload
  secrets belong in AWS Secrets Manager / External Secrets, not in state.
- **No application workloads** — this repo provisions the platform. Workloads ship
  through GitOps (see the globomantics-gitops and cicd-pipeline-eks repositories).

## Cost shape (approximate, us-east-1)

EKS control plane ~$73/mo + NAT gateway ~$32/mo + nodes (system 2× t3.medium,
app 2–6× t3.large). A realistic steady-state floor is roughly $250–300/mo —
which is why `terraform destroy` is in the runbook for sandbox use.
