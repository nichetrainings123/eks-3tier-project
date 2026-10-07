terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "network" {
  source = "./modules/network"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name                 = var.cluster_name
  cluster_version              = var.cluster_version
  private_subnet_ids           = module.network.private_subnet_ids
  public_subnet_ids            = module.network.public_subnet_ids
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  node_instance_types          = var.node_instance_types
  node_desired_size            = var.node_desired_size
  node_min_size                = var.node_min_size
  node_max_size                = var.node_max_size
  tags                         = local.common_tags
}

module "load_balancer" {
  source = "./modules/load-balancer"

  name                   = var.cluster_name
  vpc_id                 = module.network.vpc_id
  vpc_cidr               = var.vpc_cidr
  private_subnet_ids     = module.network.private_subnet_ids
  node_group_asg_name    = module.eks.node_group_asg_name
  node_security_group_id = module.eks.cluster_security_group_id
  node_port              = var.login_node_port
  tags                   = local.common_tags
}

module "api_gateway" {
  source = "./modules/api-gateway"

  name               = var.cluster_name
  random_suffix      = module.eks.name_suffix
  vpc_id             = module.network.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.network.private_subnet_ids
  nlb_listener_arn   = module.load_balancer.listener_arn
  tags               = local.common_tags
}
