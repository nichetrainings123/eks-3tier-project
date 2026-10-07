# Terraform infrastructure

The AWS infrastructure is split into local, reusable modules:

- `modules/network`: VPC, public/private subnets, routing, and NAT.
- `modules/eks`: EKS control plane, managed node group, IAM roles, OIDC, and EBS CSI add-on.
- `modules/load-balancer`: private NLB, target group, listener, and managed-node-group attachment.
- `modules/api-gateway`: API Gateway HTTP API and its private VPC Link. The main root creates
  a separate API Gateway for `dev`, `staging`, and `prod`.
- `istio`: a separate Terraform root for Istio's CRDs, control plane, and ingress gateway.
- `environments`: a separate S3-backed Terraform root for the `dev`, `staging`, and `prod`
  Kubernetes namespaces and namespace-scoped EKS deployment access.

The internal NLB is provisioned by Terraform and forwards to the Istio ingress gateway
NodePort `30080`. Login and BMI are private ClusterIP services; Istio routes `/` to the
login service and `/bmi` to the BMI service. Its target health check uses Istio's
readiness NodePort `30021` and `/healthz/ready`, rather than the application HTTP route.
Each API Gateway integration overwrites the backend `Host` header with its environment's
internal host (for example, `training-eks-cluster-dev.internal`); the Istio Gateway and
VirtualService use that host to route to only the matching environment's namespace.
`terraform -chdir=terraform output -json environment_api_endpoints` lists the three
public API endpoints.

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

## Dev, staging, and prod

The three application environments share the EKS cluster but use isolated Kubernetes
namespaces, Helm values, API Gateways, and deployment pipelines. The new EKS access
configuration enables access entries while retaining `aws-auth` compatibility. Existing
clusters may need an in-place authentication-mode update; inspect and approve the main
Terraform plan before applying it.

The namespaces root uses S3 state with native state locking. Create the state bucket
first, enable versioning and encryption, and keep its access restricted. Set
`TF_STATE_BUCKET` to that bucket name, then initialize the root:

```powershell
$env:TF_STATE_BUCKET = "your-terraform-state-bucket"
terraform -chdir=terraform/environments init `
  -backend-config="bucket=$env:TF_STATE_BUCKET" `
  -backend-config="key=eks-3tier/environments.tfstate" `
  -backend-config="region=us-east-1" `
  -backend-config="encrypt=true" `
  -backend-config="use_lockfile=true"
Copy-Item terraform\environments\terraform.tfvars.example terraform\environments\terraform.tfvars
```

Replace the example AWS account and IAM role ARNs in `terraform.tfvars`. Create one
GitHub Actions OIDC role per environment, restricted to this repository and the matching
GitHub Environment (`dev`, `staging`, or `prod`). Each role needs ECR push permissions
for `login-app` and `bmi-service`, `eks:DescribeCluster`, and an EKS access entry; this
Terraform root associates the role with `AmazonEKSEditPolicy` scoped only to its
namespace. Apply the EKS access-mode change in the main root before applying this root:

```powershell
terraform -chdir=terraform/environments plan
terraform -chdir=terraform/environments apply
```

The `deployment_role_arns` map may be empty when only creating namespaces, but the
deployment workflows will not be able to access the cluster until each role is supplied
and its EKS access association has been applied. The namespace resources prevent
accidental deletion because each contains environment data, including persistent
PostgreSQL volumes.

Create GitHub Environments named `dev`, `staging`, and `prod`. Set `AWS_REGION` and
`EKS_CLUSTER_NAME` as environment variables, and set `AWS_ROLE_ARN`, `POSTGRES_PASSWORD`,
and `SESSION_SECRET` as environment secrets. Use separate credentials for each
environment. Restrict each environment to its matching branch; configure required
reviewers for `prod`. The two ECR repositories must exist before an environment pipeline
runs (the existing `main` workflow can create them).

The separate workflows are `.github/workflows/deploy-dev.yml`,
`.github/workflows/deploy-staging.yml`, and `.github/workflows/deploy-prod.yml`. Each
builds and pushes commit-tagged images, then deploys the chart to its matching
Terraform-managed namespace. The reusable implementation is
`.github/workflows/deploy-environment.yml`.

Create the local environment branches and push them to the repository when ready:

```powershell
git branch dev
git branch staging
git branch prod
git push origin dev staging prod
```

The environment URLs are separate API Gateway endpoints, not separate custom domains.
Each endpoint forwards privately through the existing NLB and routes using a distinct
Istio host. Configure a custom domain and ACM certificate separately if stable,
human-readable URLs are needed.

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
