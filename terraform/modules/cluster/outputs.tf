output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "database_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.database_subnets
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks
}

output "cluster_identity_oidc_issuer" {
  description = "Issuer URL for the OpenID Connect identity provider"
  value = module.eks.cluster_oidc_issuer_url
}

output "cluster_identity_oidc_issuer_arn" {
  description = "The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account"
  value = module.eks.oidc_provider_arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value = module.eks.cluster_endpoint
}

output "cluster_sg_id" {
  description = "EKS Cluster Security Group ID"
  value = module.eks.node_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value = module.eks.cluster_certificate_authority_data
}