moved {
  from = random_id.suffix
  to   = module.eks.random_id.suffix
}

moved {
  from = aws_vpc.eks_vpc
  to   = module.network.aws_vpc.this
}

moved {
  from = aws_internet_gateway.igw
  to   = module.network.aws_internet_gateway.this
}

moved {
  from = aws_subnet.public1
  to   = module.network.aws_subnet.public1
}

moved {
  from = aws_subnet.public2
  to   = module.network.aws_subnet.public2
}

moved {
  from = aws_subnet.private1
  to   = module.network.aws_subnet.private1
}

moved {
  from = aws_subnet.private2
  to   = module.network.aws_subnet.private2
}

moved {
  from = aws_eip.nat
  to   = module.network.aws_eip.nat
}

moved {
  from = aws_nat_gateway.nat
  to   = module.network.aws_nat_gateway.nat
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table.private
  to   = module.network.aws_route_table.private
}

moved {
  from = aws_route_table_association.public1
  to   = module.network.aws_route_table_association.public1
}

moved {
  from = aws_route_table_association.public2
  to   = module.network.aws_route_table_association.public2
}

moved {
  from = aws_route_table_association.private1
  to   = module.network.aws_route_table_association.private1
}

moved {
  from = aws_route_table_association.private2
  to   = module.network.aws_route_table_association.private2
}

moved {
  from = aws_iam_role.eks_cluster_role
  to   = module.eks.aws_iam_role.cluster
}

moved {
  from = aws_iam_role_policy_attachment.cluster_policy
  to   = module.eks.aws_iam_role_policy_attachment.cluster
}

moved {
  from = aws_iam_role.node_role
  to   = module.eks.aws_iam_role.nodes
}

moved {
  from = aws_iam_role_policy_attachment.worker_node_policy
  to   = module.eks.aws_iam_role_policy_attachment.nodes
}

moved {
  from = aws_iam_role_policy_attachment.cni_policy
  to   = module.eks.aws_iam_role_policy_attachment.cni
}

moved {
  from = aws_iam_role_policy_attachment.ecr_policy
  to   = module.eks.aws_iam_role_policy_attachment.ecr
}

moved {
  from = aws_eks_cluster.eks_cluster
  to   = module.eks.aws_eks_cluster.this
}

moved {
  from = aws_eks_node_group.public_workers
  to   = module.eks.aws_eks_node_group.workers
}

moved {
  from = aws_iam_openid_connect_provider.oidc
  to   = module.eks.aws_iam_openid_connect_provider.this
}

moved {
  from = aws_iam_role.ebs_csi_role
  to   = module.eks.aws_iam_role.ebs_csi
}

moved {
  from = aws_iam_role_policy_attachment.ebs_csi_policy
  to   = module.eks.aws_iam_role_policy_attachment.ebs_csi
}

moved {
  from = aws_eks_addon.ebs_csi
  to   = module.eks.aws_eks_addon.ebs_csi
}

moved {
  from = aws_security_group.api_gateway_vpc_link
  to   = module.api_gateway.aws_security_group.vpc_link
}

moved {
  from = aws_apigatewayv2_vpc_link.login
  to   = module.api_gateway.aws_apigatewayv2_vpc_link.this
}

moved {
  from = aws_apigatewayv2_api.login
  to   = module.api_gateway.aws_apigatewayv2_api.this
}

moved {
  from = aws_apigatewayv2_integration.login
  to   = module.api_gateway.aws_apigatewayv2_integration.this
}

moved {
  from = aws_apigatewayv2_route.login
  to   = module.api_gateway.aws_apigatewayv2_route.this
}

moved {
  from = aws_apigatewayv2_stage.login
  to   = module.api_gateway.aws_apigatewayv2_stage.this
}
