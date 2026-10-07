variable "aws_region" {
  description = "AWS region containing the shared EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Existing shared EKS cluster name."
  type        = string
  default     = "training-eks-cluster"
}

variable "node_group_name" {
  description = "Existing EKS managed node group used by the environment load balancers."
  type        = string
  default     = "public-workers"
}

variable "istio_version" {
  description = "Istio gateway chart version installed in the shared cluster."
  type        = string
  default     = "1.30.5"
}
