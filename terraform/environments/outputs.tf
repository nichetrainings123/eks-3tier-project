output "environment" {
  description = "Environment managed by the active Terraform workspace."
  value       = terraform.workspace
}

output "public_login_url" {
  description = "Public API Gateway endpoint for this environment."
  value       = module.api_gateway.api_endpoint
}

output "login_load_balancer_dns_name" {
  description = "Private NLB DNS name for this environment."
  value       = module.load_balancer.dns_name
}
