terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
  }

  # Partial configuration: environment-specific values live in backend.hcl
  # so nothing account-specific is hardcoded here.
  #   terraform init -backend-config=backend.hcl
  #
  # use_lockfile enables S3-native state locking (Terraform >= 1.10),
  # so no DynamoDB lock table is needed.
  backend "s3" {
    key          = "envs/dev/items-api.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
