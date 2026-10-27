terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
  }

  # Chicken-and-egg: the state bucket cannot store its own state before it
  # exists. First apply runs with local state; then uncomment this block and
  # run `terraform init -migrate-state` to move state into the bucket.
  #
  # backend "s3" {
  #   bucket       = "REPLACE_ME-tfstate"
  #   key          = "bootstrap/terraform.tfstate"
  #   region       = "eu-west-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}
