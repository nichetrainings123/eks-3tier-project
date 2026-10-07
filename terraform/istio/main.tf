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

resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = var.istio_version
  namespace        = "istio-system"
  create_namespace = true
  wait             = true
  timeout          = 600
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.istio_version
  namespace  = helm_release.istio_base.namespace
  wait       = true
  timeout    = 600

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "ingress_gateway" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_version
  namespace  = helm_release.istio_base.namespace
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
      service = {
        type = "NodePort"
        ports = [
          {
            name       = "status-port"
            port       = 15021
            targetPort = 15021
            nodePort   = var.status_node_port
            protocol   = "TCP"
          },
          {
            name       = "http2"
            port       = 80
            targetPort = 80
            nodePort   = var.http_node_port
            protocol   = "TCP"
          },
          {
            name       = "https"
            port       = 443
            targetPort = 443
            protocol   = "TCP"
          }
        ]
      }
    })
  ]

  depends_on = [helm_release.istiod]
}
