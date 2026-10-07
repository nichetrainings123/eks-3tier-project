# Terraform infrastructure

The AWS infrastructure is split into local, reusable modules:

- `modules/network`: VPC, public/private subnets, routing, and NAT.
- `modules/eks`: EKS control plane, managed node group, IAM roles, OIDC, and EBS CSI add-on.
- `modules/load-balancer`: private NLB, target group, listener, and managed-node-group attachment.
- `modules/api-gateway`: API Gateway HTTP API and its private VPC Link.
- `istio`: a separate Terraform root for Istio's CRDs, control plane, and ingress gateway.

The `training` environment uses the original internal NLB and shared Istio ingress
gateway. Login and BMI are private ClusterIP services; Istio routes `/` to the login
service and `/bmi` to the BMI service. Its target health check uses Istio's readiness
NodePort `30021` and `/healthz/ready`, rather than the application HTTP route.

## Dev, test, and production environments

The existing EKS cluster and Istio control plane are shared. A separate Terraform root
at `terraform/environments` uses Terraform workspaces `dev`, `test`, and `prod` to
manage one isolated ingress gateway, internal NLB, API Gateway, and VPC Link per
environment. Each environment's gateway has unique NodePorts and pod selectors, and
the Helm application release creates its own namespace and PostgreSQL volume.
Environment URLs are available from that workspace's `public_login_url` output.

The GitHub Actions workflow maps branch pushes as follows:

| Branch | Namespace | Environment URL |
| --- | --- | --- |
| `dev` | `dev` | `terraform output -raw public_login_url` in the `dev` workspace |
| `test` | `test` | `terraform output -raw public_login_url` in the `test` workspace |
| `prod` | `prod` | `terraform output -raw public_login_url` in the `prod` workspace |
| `main` | `training` | Existing training endpoint |

To create the isolated infrastructure after the shared EKS cluster and Istio control
plane are available:

```powershell
terraform -chdir=terraform/environments init
terraform -chdir=terraform/environments workspace new dev
terraform -chdir=terraform/environments plan
terraform -chdir=terraform/environments apply

terraform -chdir=terraform/environments workspace new test
terraform -chdir=terraform/environments plan
terraform -chdir=terraform/environments apply

terraform -chdir=terraform/environments workspace new prod
terraform -chdir=terraform/environments plan
terraform -chdir=terraform/environments apply
```

Seed each namespace once with its corresponding current image tag; later pushes to the
matching Git branch build both images and deploy that branch's commit SHA automatically:

```powershell
aws eks update-kubeconfig --region us-east-1 --name training-eks-cluster
helm upgrade --install login-app .\helm\login-app --namespace dev --create-namespace `
  --take-ownership --wait --set-string namespace=dev `
  --set-string gateway.selector=ingressgateway-dev `
  --set-string postgres.storage.storageClass=gp3-dev `
  --set loginApp.replicas=1 --set bmiApp.replicas=1
```

Use the same seed command with namespace, selector, and storage class `test` /
`ingressgateway-test` / `gp3-test`, then `prod` / `ingressgateway-prod` / `gp3-prod`.
Each environment needs a unique StorageClass because the chart creates cluster-scoped
StorageClass resources. The workflow applies one replica per application in these
environments and retains two ingress gateway replicas. Scale the node group and
application replicas for production availability as needed.

The environment Terraform root uses local Terraform workspace state. Back it up and
protect it; do not commit state files. For team use, migrate the root to an encrypted,
versioned remote backend with state locking before relying on it for production.
All three PostgreSQL databases currently use the same password, as requested. Use a
unique secret per environment before exposing production data or handling real users.

## Deploy

From the repository root:

```powershell
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

The main Terraform root manages the existing VPC, EKS cluster, and NLB. If those
resources already exist but this checkout has no matching Terraform state, do not apply
this root yet: first restore its state or import the existing resources to avoid
attempting to recreate them.

After applying the EKS infrastructure, apply the separate Terraform Istio layer. This
separate state is intentional: it connects to the already-created cluster and installs
Istio's base CRDs, control plane, and NodePort ingress gateway:

```powershell
terraform -chdir=terraform/istio init
terraform -chdir=terraform/istio validate
terraform -chdir=terraform/istio plan
terraform -chdir=terraform/istio apply

helm upgrade --install login-app .\helm\login-app `
  --namespace training --create-namespace --take-ownership --wait
```

The Helm command uses `--take-ownership` because the chart declares the namespace
resource itself; use Helm 3.17 or newer.

The Helm chart labels the `training` namespace for Istio sidecar injection. The Istio
Gateway and VirtualService send the browser to the BMI service after a successful login;
the shared, Helm-managed session secret keeps that service behind the login session.
The Istio Terraform layer defaults to HTTP NodePort `30080` and readiness NodePort
`30021`; if these are changed, set matching `login_node_port` and
`istio_status_node_port` values for the main stack and `http_node_port` and
`status_node_port` values for the Istio layer.

For production, use a shared, encrypted remote Terraform state backend and supply a
restricted value for `cluster_endpoint_public_access_cidrs`. The default CIDR keeps
the existing training-cluster access behavior and is not appropriate for a production
control-plane endpoint. If changing `aws_region`, also set `availability_zones` to
two zones in that region; ensure all subnet CIDRs are contained by `vpc_cidr`.

`moved.tf` preserves the state addresses for resources that were previously declared
in the root module. Review the plan before applying, especially when using a state
file created from the previous layout.
