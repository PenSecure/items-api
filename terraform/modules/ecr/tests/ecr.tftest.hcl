mock_provider "aws" {}

variables {
  name = "items-api"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "Tags must be immutable."
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push
    error_message = "Scan on push must be enabled."
  }

  assert {
    condition     = aws_ecr_repository.this.force_delete == false
    error_message = "force_delete must default to false."
  }

  assert {
    condition     = length(jsondecode(aws_ecr_lifecycle_policy.this.policy).rules) == 2
    error_message = "Lifecycle policy should have untagged-expiry and keep-last-N rules."
  }
}

run "rejects_uppercase_name" {
  command = plan

  variables {
    name = "Items-API"
  }

  expect_failures = [var.name]
}
