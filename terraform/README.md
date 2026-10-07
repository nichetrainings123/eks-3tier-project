# Terraform infrastructure

The AWS infrastructure is split into local, reusable modules:

- `modules/network`: VPC, public/private subnets, routing, and NAT.
- `modules/eks`: EKS control plane, managed node group, IAM roles, OIDC, and EBS CSI add-on.
- `modules/load-balancer`: private NLB, target group, listener, and managed-node-group attachment.
- `modules/api-gateway`: API Gateway HTTP API and its private VPC Link.

The login NLB is now provisioned by Terraform. The Helm chart exposes the application as
NodePort `30080`; the NLB target group forwards to that port on the EKS worker nodes.
This avoids asking Kubernetes to provision a second load balancer.

## Deploy

From the repository root:

```powershell
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

After applying the infrastructure, configure `kubectl` with the `configure_kubectl`
output and install/upgrade the application chart:

```powershell
helm upgrade --install login-app .\helm\login-app --namespace training --create-namespace
```

For production, use a shared, encrypted remote Terraform state backend and supply a
restricted value for `cluster_endpoint_public_access_cidrs`. The default CIDR keeps
the existing training-cluster access behavior and is not appropriate for a production
control-plane endpoint. If changing `aws_region`, also set `availability_zones` to
two zones in that region; ensure all subnet CIDRs are contained by `vpc_cidr`.

`moved.tf` preserves the state addresses for resources that were previously declared
in the root module. Review the plan before applying, especially when using a state
file created from the previous layout.
