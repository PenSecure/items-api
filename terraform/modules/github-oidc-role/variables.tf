variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the role, in owner/name form."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in 'owner/name' form."
  }
}

variable "allowed_subjects" {
  description = <<-EOT
    OIDC 'sub' claim patterns (relative to repo:<owner>/<name>:) allowed to assume
    the role. Default: only the main branch, so PRs (including from forks) can never push.
  EOT
  type        = list(string)
  default     = ["ref:refs/heads/main"]
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the CI pipeline may push to."
  type        = list(string)

  validation {
    condition     = length(var.ecr_repository_arns) > 0
    error_message = "At least one ECR repository ARN is required."
  }
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if the account already has one (it is account-wide)."
  type        = bool
  default     = true
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for the assumed role."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Additional tags applied to created resources."
  type        = map(string)
  default     = {}
}
