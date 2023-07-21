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

data "aws_iam_policy_document" "kubernetes_cluster_autoscaler" {
  count = var.enabled ? 1 : 0

  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

}

resource "aws_iam_policy" "kubernetes_cluster_autoscaler" {
  count       = var.enabled ? 1 : 0
  name        = "${var.cluster_name}-cluster-autoscaler"
  path        = "/"
  description = "Policy for cluster autoscaler service"

  policy = data.aws_iam_policy_document.kubernetes_cluster_autoscaler[0].json
}

# Role
data "aws_iam_policy_document" "kubernetes_cluster_autoscaler_assume" {
  count = var.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_identity_oidc_issuer_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_identity_oidc_issuer, "https://", "")}:sub"

      values = [
        "system:serviceaccount:${var.namespace}:${var.service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "kubernetes_cluster_autoscaler" {
  count              = var.enabled ? 1 : 0
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.kubernetes_cluster_autoscaler_assume[0].json
}

resource "aws_iam_role_policy_attachment" "kubernetes_cluster_autoscaler" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.kubernetes_cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.kubernetes_cluster_autoscaler[0].arn
}