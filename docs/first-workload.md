# Your first workload on the cluster

End-to-end: from `terraform apply` to a reachable application in about ten minutes.

## 1. Provision

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## 2. Connect kubectl

`terraform output` prints the exact command:

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-eks-cluster
kubectl get nodes        # system + app node groups should be Ready
```

## 3. Deploy the sample workload

```bash
kubectl apply -f workloads/sample-app.yaml
kubectl rollout status deployment/sample-app
```

The Deployment deliberately has **no nodeSelector**: the system node group carries
the `CriticalAddonsOnly` taint, so the scheduler places these pods on the app group
automatically — the two-group design doing its job.

## 4. Reach it

```bash
kubectl get svc sample-app   # wait for the NLB hostname in EXTERNAL-IP
curl http://<nlb-hostname>/
```

The Service requests an internet-facing NLB; the AWS load-balancer controller finds
the public subnets through the `kubernetes.io/role/elb` tags the VPC module set.

## 5. Prove storage works (the IRSA check)

The EBS CSI driver runs under an IAM role bound to its service account only:

```bash
kubectl get sa ebs-csi-controller-sa -n kube-system -o yaml | grep eks.amazonaws.com/role-arn
```

If that annotation is present, dynamic EBS provisioning is least-privilege — any
PersistentVolumeClaim in the cluster can provision volumes without the nodes (or
other pods) holding storage permissions.

## 6. Tear down (sandbox discipline)

```bash
kubectl delete -f workloads/sample-app.yaml
terraform destroy
```

Delete the workload first so the load balancer is released before the VPC goes —
otherwise destroy can stall on the orphaned NLB.
