variable "db_password" {
  type        = string
  description = "DB administrator password"
  sensitive   = true
}

variable "db_username" {
  type        = string
  description = "DB username"
}

variable "database_name" {
  description = "DB Name"
  type        = string
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 Zone ID"
}

variable "route53_zone_name" {
  type        = string
  description = "Route53 Zone Name"
}

variable "cert_arn" {
  type        = string
  description = "Route53 Hosted Zone ID AWS Certificate Manager ARN"
}

variable "environment" {
  type        = string
  description = "Environment workspace"
}

variable "keycloak_username" {
  type        = string
  description = "Keycloak username"
}

variable "keycloak_password" {
  description = "Keycloak Password"
  type        = string
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
}