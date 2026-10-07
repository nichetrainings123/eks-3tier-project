terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
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

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_vpc" "this" {
  id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

data "aws_eks_node_group" "workers" {
  cluster_name    = data.aws_eks_cluster.this.name
  node_group_name = var.node_group_name
}

locals {
  environments = {
    dev = {
      http_node_port   = 30081
      status_node_port = 30022
    }
    test = {
      http_node_port   = 30082
      status_node_port = 30023
    }
    prod = {
      http_node_port   = 30083
      status_node_port = 30024
    }
  }

  environment        = terraform.workspace
  environment_config = lookup(local.environments, local.environment, local.environments.dev)
  resource_name      = "training-${local.environment}"
  common_tags = {
    Project     = "eks-3tier"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

check "supported_workspace" {
  assert {
    condition     = contains(keys(local.environments), local.environment)
    error_message = "Select a Terraform workspace named dev, test, or prod before planning."
  }
}

resource "helm_release" "ingress_gateway" {
  name       = "istio-ingressgateway-${local.environment}"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_version
  namespace  = "istio-system"
  wait       = true
  timeout    = 600

  values = [
    yamlencode({
      autoscaling = {
        enabled = false
      }
      replicaCount = 2
      podDisruptionBudget = {
        minAvailable = 1
      }
      labels = {
        istio = "ingressgateway-${local.environment}"
      }
      service = {
        type = "NodePort"
        selectorLabels = {
          istio = "ingressgateway-${local.environment}"
        }
        ports = [
          {
            name       = "status-port"
            port       = 15021
            targetPort = 15021
            nodePort   = local.environment_config.status_node_port
            protocol   = "TCP"
          },
          {
            name       = "http2"
            port       = 80
            targetPort = 80
            nodePort   = local.environment_config.http_node_port
            protocol   = "TCP"
          }
        ]
      }
    })
  ]

  depends_on = [data.aws_eks_cluster.this]
}

module "load_balancer" {
  source = "../modules/load-balancer"

  name                   = local.resource_name
  vpc_id                 = data.aws_vpc.this.id
  vpc_cidr               = data.aws_vpc.this.cidr_block
  private_subnet_ids     = data.aws_subnets.private.ids
  node_group_asg_name    = data.aws_eks_node_group.workers.resources[0].autoscaling_groups[0].name
  node_security_group_id = data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  node_port              = local.environment_config.http_node_port
  health_check_node_port = local.environment_config.status_node_port
  tags                   = local.common_tags

  depends_on = [helm_release.ingress_gateway]
}

module "api_gateway" {
  source = "../modules/api-gateway"

  name               = local.resource_name
  random_suffix      = local.environment
  vpc_id             = data.aws_vpc.this.id
  vpc_cidr           = data.aws_vpc.this.cidr_block
  private_subnet_ids = data.aws_subnets.private.ids
  nlb_listener_arn   = module.load_balancer.listener_arn
  tags               = local.common_tags
}
