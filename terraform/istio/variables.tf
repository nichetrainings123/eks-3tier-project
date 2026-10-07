variable "aws_region" {
  description = "AWS region containing the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster created by the parent Terraform configuration."
  type        = string
  default     = "training-eks-cluster"
}

variable "istio_version" {
  description = "Istio chart release to install."
  type        = string
  default     = "1.30.5"
}

variable "http_node_port" {
  description = "Must match login_node_port in the parent Terraform configuration."
  type        = number
  default     = 30080

  validation {
    condition     = var.http_node_port >= 30000 && var.http_node_port <= 32767
    error_message = "The Istio HTTP NodePort must be in the Kubernetes NodePort range (30000-32767)."
  }
}

variable "status_node_port" {
  description = "Must match istio_status_node_port in the parent Terraform configuration."
  type        = number
  default     = 30021

  validation {
    condition     = var.status_node_port >= 30000 && var.status_node_port <= 32767
    error_message = "The Istio status NodePort must be in the Kubernetes NodePort range (30000-32767)."
  }
}
