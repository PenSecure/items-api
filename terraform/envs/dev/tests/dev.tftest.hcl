# Plan-only tests with a mocked AWS provider: no credentials, no cost, safe for CI.
#   terraform test   (from terraform/envs/dev)

mock_provider "aws" {
  # Mocked data sources return random strings; policy documents must be valid JSON.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  allowed_account_ids = ["123456789012"]
  github_repository   = "your-org/items-api"
}

run "ecr_is_hardened" {
  command = plan

  assert {
    condition     = module.ecr.repository_name == "items-api"
    error_message = "ECR repository should be named after the project."
  }

  assert {
    condition     = output.ci_role_arn != null
    error_message = "CI role ARN must be exported for the GitHub workflow."
  }
}

run "rejects_bad_repository_format" {
  command = plan

  variables {
    github_repository = "not-a-valid-repo"
  }

  expect_failures = [var.github_repository]
}

run "rejects_bad_account_id" {
  command = plan

  variables {
    allowed_account_ids = ["1234"]
  }

  expect_failures = [var.allowed_account_ids]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}
