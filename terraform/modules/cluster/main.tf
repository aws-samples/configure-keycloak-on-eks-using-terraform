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

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "dev"
      Name        = "terraform keycloak demo provider tag"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token

}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    }
}


data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

locals {
  account_id     = data.aws_caller_identity.current.account_id
}

module "eks-kubeconfig" {
  source     = "hyperbadger/eks-kubeconfig/aws"
  version    = "1.0.0"

  depends_on = [module.eks]
  cluster_id =  module.eks.cluster_id
  }

resource "local_file" "kubeconfig" {
  content  = module.eks-kubeconfig.kubeconfig
  filename = "kubeconfig_${var.cluster_name}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name                 = var.cluster_name
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  database_subnets     = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  map_public_ip_on_launch = false
  create_flow_log_cloudwatch_log_group = true
  flow_log_cloudwatch_iam_role_arn = aws_iam_role.cw_role.arn
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_destination_type = "cloud-watch-logs"
  flow_log_file_format = "plain-text"
  flow_log_traffic_type = "ALL"

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "true"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "true"
  }

  database_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cw_role" {
  name               = "cw_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "cw_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "example" {
  name   = "example"
  role   = aws_iam_role.cw_role.id
  policy = data.aws_iam_policy_document.cw_logs.json
}

resource "aws_default_security_group" "this" {
  vpc_id = module.vpc.vpc_id
}

data "aws_iam_policy_document" "key" {

  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "this" {
  deletion_window_in_days = 7
  description             = "VPC Flow Log Encryption Key"
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.key.json
  tags = merge(
    {
      "Name" = "vpcflowlog-key"
    }
  )
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  depends_on = [
    aws_kms_key.this
  ]
  name = "vpc-flow-logs"
  kms_key_id = aws_kms_key.this.arn
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids        = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id
  cluster_endpoint_public_access  = true
  create_cloudwatch_log_group = true
  cluster_enabled_log_types = ["api", "audit", "authenticator","controllerManager","scheduler"]
  cloudwatch_log_group_kms_key_id = aws_kms_key.this.arn
  create_kms_key                  = true
  cluster_encryption_config = [{
    resources = ["secrets"]
    provider_key_arn = aws_kms_key.this.arn
  }]

  kms_key_description             = "KMS Secrets encryption for EKS cluster."
  kms_key_enable_default_policy   = true

  eks_managed_node_groups = {
    first = {
      desired_capacity = 1
      max_capacity     = 10
      min_capacity     = 1

      instance_type = var.instance_type
    }
  }
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane_webhook = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    },
    ingress_allow_access_from_control_plane_metrics = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 4443
      to_port                       = 4443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to metrics server AWS load balancer controller"
    }
  }
}

resource "aws_iam_policy" "worker_policy" {
  name        = "worker-policy-${var.cluster_name}"
  description = "Worker policy for the ALB Ingress"

  policy = file("modules/iam/worker-policy.json")
}

resource "aws_iam_policy" "dnsupdate_policy" {
  name        = "dnsupdate-policy-${var.cluster_name}"
  description = "DNS update policy for Route53 Resource Record Sets and Hosted Zones"

  policy = file("modules/iam/dns-update-policy.json")
}


resource "aws_iam_role_policy_attachment" "workerpolicy" {
  for_each = module.eks.eks_managed_node_groups

  policy_arn = aws_iam_policy.worker_policy.arn
  role       = each.value.iam_role_name
}

resource "aws_iam_role_policy_attachment" "dnsupdatepolicy" {
  for_each = module.eks.eks_managed_node_groups

  policy_arn = aws_iam_policy.dnsupdate_policy.arn
  role       = each.value.iam_role_name
}

resource "helm_release" "ingress" {
  name       = "demo"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.4.7"

  set {
    name  = "autoDiscoverAwsRegion"
    value = "true"
  }
  set {
    name  = "autoDiscoverAwsVpcID"
    value = "true"
  }
  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name = "SubnetsClusterTagCheck"
    value = "false"
  }
}

resource "aws_security_group" "lb_security_group" {
  name        = "${var.cluster_name}-lb-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Ingress ALB"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["52.94.133.131/32"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [module.eks.node_security_group_id]
  }

  tags = merge({
    Name                                      = "${var.cluster_name}-lb-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes:application"                  = "kube-ingress-aws-controller"
  })
}

# ============= auth configmap / external DNS config ============= #
data "kubectl_path_documents" "kube_configs" {
  pattern = "${path.module}/templates/*.tftpl"
  vars = {
    account_number = local.account_id
    nodegroup_role_name = module.eks.eks_managed_node_groups.first.iam_role_name
    route53_zone_id = var.route53_zone_id
    region = var.region
    domain_name = var.route53_zone_name
    }
}
# Resource to get around Terraform count bug. We use this so that Terraform provider is aware of the number of vars at runtime. This resource should mimic the above resource.
# Link to bug: https://github.com/gavinbunney/terraform-provider-kubectl/issues/58
data "kubectl_path_documents" "kube_config_count" {
  pattern = "${path.module}/templates/*.tftpl"
  vars = {
    account_number = ""
    nodegroup_role_name = ""
    route53_zone_id = ""
    region = ""
    domain_name = ""
    }
}

resource "kubectl_manifest" "configs_apply" {
  count     = length(data.kubectl_path_documents.kube_config_count.documents)
  yaml_body = element(data.kubectl_path_documents.kube_configs.documents, count.index)
}

# ============= metric server ============= #
terraform {
  required_version = "~>1.3.9"
  
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}


data "kubectl_file_documents" "docs" {
  content = file("modules/metrics-server/components.yml")
}

resource "kubectl_manifest" "metrics-apply" {
  for_each  = data.kubectl_file_documents.docs.manifests
  yaml_body = each.value
}