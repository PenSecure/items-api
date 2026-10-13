locals {
  oidc_url     = "token.actions.githubusercontent.com"
  provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# The GitHub OIDC provider is a singleton per account. Create it here, or
# look up the existing one so multiple stacks do not fight over it.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.oidc_url}"
  client_id_list = ["sts.amazonaws.com"]
  # AWS validates GitHub's certificate against its trusted CA library, so the
  # thumbprint is not used for verification; the API still accepts a value.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://${local.oidc_url}"
}

# Trust policy: only workflows from the named repo, on the allowed refs,
# requesting the STS audience, can assume this role. No long-lived keys.
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_url}:sub"
      values   = [for s in var.allowed_subjects : "repo:${var.github_repository}:${s}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  description          = "Assumed by GitHub Actions (${var.github_repository}) to push images to ECR."
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = var.max_session_duration

  tags = var.tags
}

# Least privilege: push/pull only, only to the listed repositories.
# No ecr:DeleteRepository, no ecr:SetRepositoryPolicy, no lifecycle changes.
data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid    = "GetAuthToken"
    effect = "Allow"
    # GetAuthorizationToken does not support resource-level permissions,
    # so "*" is required here. It only issues a registry login token.
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushToScopedRepos"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
