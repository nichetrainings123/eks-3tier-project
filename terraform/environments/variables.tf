variable "aws_region" {
  description = "AWS region containing the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster."
  type        = string
  default     = "training-eks-cluster"
}

variable "environments" {
  description = "Kubernetes namespaces managed by this configuration."
  type        = list(string)
  default     = ["dev", "staging", "prod"]

  validation {
    condition     = length(var.environments) == 3 && toset(var.environments) == toset(["dev", "staging", "prod"])
    error_message = "The environments must be exactly dev, staging, and prod."
  }
}

variable "deployment_role_arns" {
  description = "Map of environment names to GitHub Actions IAM role ARNs, granted namespace-scoped EKS edit access."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for environment in keys(var.deployment_role_arns) :
      contains(["dev", "staging", "prod"], environment)
    ])
    error_message = "Deployment role map keys must be dev, staging, or prod."
  }
}
