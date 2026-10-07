variable "aws_region" {
  description = "AWS region for the stack."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name applied to resource tags."
  type        = string
  default     = "eks-3tier"
}

variable "environment" {
  description = "Deployment environment applied to resource tags."
  type        = string
  default     = "training"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "training-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.34"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the EKS VPC."
  type        = string
  default     = "15.0.0.0/16"
}

variable "availability_zones" {
  description = "Two availability zones used for the EKS subnets. Match these to aws_region."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones are required by this network module."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR ranges for the two public subnets."
  type        = list(string)
  default     = ["15.0.1.0/24", "15.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required by this network module."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR ranges for the two private subnets."
  type        = list(string)
  default     = ["15.0.10.0/24", "15.0.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs are required by this network module."
  }
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "IPv4 CIDRs allowed to reach the public EKS API endpoint. Restrict this for production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired EKS worker node count."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum EKS worker node count."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum EKS worker node count."
  type        = number
  default     = 4
}

variable "login_node_port" {
  description = "HTTP NodePort served by the Istio ingress gateway and registered in the NLB target group."
  type        = number
  default     = 30080

  validation {
    condition     = var.login_node_port >= 30000 && var.login_node_port <= 32767
    error_message = "The Istio HTTP NodePort must be in the Kubernetes NodePort range (30000-32767)."
  }
}

variable "istio_status_node_port" {
  description = "NodePort used by the Istio ingress gateway readiness health check."
  type        = number
  default     = 30021

  validation {
    condition     = var.istio_status_node_port >= 30000 && var.istio_status_node_port <= 32767
    error_message = "The Istio status NodePort must be in the Kubernetes NodePort range (30000-32767)."
  }
}
