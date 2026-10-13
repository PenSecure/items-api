variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-1"
}

variable "allowed_account_ids" {
  description = "AWS account IDs this configuration may run against."
  type        = list(string)

  validation {
    condition     = alltrue([for id in var.allowed_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "Each account ID must be 12 digits."
  }
}

variable "project" {
  description = "Project / service name. Also used as the ECR repository name."
  type        = string
  default     = "items-api"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, staging, prod."
  }
}

variable "github_repository" {
  description = "GitHub repository (owner/name) whose main branch may push images."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in 'owner/name' form."
  }
}

variable "create_oidc_provider" {
  description = "Create the account-wide GitHub OIDC provider (false if it already exists)."
  type        = bool
  default     = true
}

variable "keep_tagged_images" {
  description = "Number of tagged images ECR retains."
  type        = number
  default     = 30
}
