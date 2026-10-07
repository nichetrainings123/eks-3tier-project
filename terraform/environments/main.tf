terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

locals {
  environments = toset(var.environments)
}

resource "kubernetes_namespace_v1" "environment" {
  for_each = local.environments

  metadata {
    name = each.value

    labels = {
      environment       = each.value
      "istio-injection" = "enabled"
      "managed-by"      = "terraform"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_eks_access_entry" "deployment" {
  for_each = var.deployment_role_arns

  cluster_name  = data.aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "deployment" {
  for_each = var.deployment_role_arns

  cluster_name  = data.aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [each.key]
  }

  depends_on = [kubernetes_namespace_v1.environment]
}

output "namespaces" {
  description = "Namespaces managed for the three deployment environments."
  value       = sort(tolist(local.environments))
}
