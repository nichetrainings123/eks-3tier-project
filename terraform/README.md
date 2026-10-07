# Terraform infrastructure

The AWS infrastructure is split into local, reusable modules:

- `modules/network`: VPC, public/private subnets, routing, and NAT.
- `modules/eks`: EKS control plane, managed node group, IAM roles, OIDC, and EBS CSI add-on.
- `modules/load-balancer`: private NLB, target group, listener, and managed-node-group attachment.
- `modules/api-gateway`: API Gateway HTTP API and its private VPC Link.

The internal NLB is provisioned by Terraform and forwards to the Istio ingress gateway
NodePort `30080`. Login and BMI are private ClusterIP services; Istio routes `/` to the
login service and `/bmi` to the BMI service.

## Deploy

From the repository root:

```powershell
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

After applying the infrastructure, configure `kubectl` with the `configure_kubectl`
output. Install Istio with its ingress gateway as a NodePort service on port `30080`
(the Terraform NLB target port), then install/upgrade the application chart:

```powershell
istioctl install --set profile=default `
  --set components.ingressGateways[0].k8s.service.type=NodePort `
  --set components.ingressGateways[0].k8s.service.ports[1].nodePort=30080 -y
helm upgrade --install login-app .\helm\login-app --namespace training --create-namespace
```

The Helm chart labels the `training` namespace for Istio sidecar injection. The Istio
Gateway and VirtualService send the browser to the BMI service after a successful login;
the shared, Helm-managed session secret keeps that service behind the login session.
The chart assumes the Istio CRDs and `istio-ingressgateway` are installed first.

For production, use a shared, encrypted remote Terraform state backend and supply a
restricted value for `cluster_endpoint_public_access_cidrs`. The default CIDR keeps
the existing training-cluster access behavior and is not appropriate for a production
control-plane endpoint. If changing `aws_region`, also set `availability_zones` to
two zones in that region; ensure all subnet CIDRs are contained by `vpc_cidr`.

`moved.tf` preserves the state addresses for resources that were previously declared
in the root module. Review the plan before applying, especially when using a state
file created from the previous layout.
