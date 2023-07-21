# Copyright 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

locals {
  region = data.aws_region.current.name
}

output "db_hostname" {
  value = module.dev_database.db_hostname
}

module "dev_cluster" {
  source            = "./modules/cluster"
  route53_zone_id   = var.route53_zone_id
  route53_zone_name = var.route53_zone_name
  cert_arn          = var.cert_arn
  environment       = var.environment
  cluster_version   = var.cluster_version
  region            = local.region
}

module "dev_autoscaler" {
  source                             = "./modules/cluster-autoscaler"
  cluster_identity_oidc_issuer       = module.dev_cluster.cluster_identity_oidc_issuer
  cluster_identity_oidc_issuer_arn   = module.dev_cluster.cluster_identity_oidc_issuer_arn
  cluster_endpoint                   = module.dev_cluster.cluster_endpoint
  cluster_certificate_authority_data = module.dev_cluster.cluster_certificate_authority_data
}

module "dev_database" {
  source                       = "./modules/database"
  db_username                  = var.db_username
  db_password                  = var.db_password
  database_name                = var.database_name
  vpc_id                       = module.dev_cluster.vpc_id
  database_subnets             = module.dev_cluster.database_subnets
  database_subnets_cidr_blocks = module.dev_cluster.database_subnets_cidr_blocks
  cluster_sg_id                = module.dev_cluster.cluster_sg_id
}