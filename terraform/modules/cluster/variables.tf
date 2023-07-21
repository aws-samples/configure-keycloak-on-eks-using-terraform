variable "route53_zone_id" {
  type        = string
  description = "Route53 Zone ID"
}

variable "route53_zone_name" {
  type        = string
  description = "Route53 Zone Name"
}

variable "region" {
  type        = string
  description = "Region Name"
}

variable "cert_arn" {
  type        = string
  description = "Route53 Hosted Zone ID AWS Certificate Manager ARN"
}

variable "environment" {
  type        = string
  description = "Environment workspace"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default = "keycloak-demo"
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Type"
  default = "t3.large"
}

variable "kms_alias" {
  default     = "vpcflowlog_key"
  description = "KMS Key Alias for VPC flow log key"
  type        = string
}