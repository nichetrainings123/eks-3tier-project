output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to configure kubectl for this EKS cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "oidc_provider" {
  description = "OIDC issuer URL for the EKS cluster."
  value       = module.eks.oidc_provider_url
}

output "login_load_balancer_dns_name" {
  description = "Private DNS name of the Terraform-managed login NLB."
  value       = module.load_balancer.dns_name
}

output "public_login_url" {
  description = "Public HTTPS endpoint for the login application through API Gateway."
  value       = module.api_gateway.api_endpoint
}
