variable "name" {
  description = "Name of the ECR repository."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*$", var.name))
    error_message = "Repository name must be lowercase alphanumerics separated by '.', '_', '-' or '/'."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for image encryption. Null uses the AWS-managed ECR key."
  type        = string
  default     = null
}

variable "keep_tagged_images" {
  description = "Number of most recent tagged images to retain."
  type        = number
  default     = 30

  validation {
    condition     = var.keep_tagged_images >= 1
    error_message = "keep_tagged_images must be at least 1."
  }
}

variable "untagged_expiry_days" {
  description = "Days after which untagged images (e.g. orphaned layers from failed pushes) expire."
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_expiry_days >= 1
    error_message = "untagged_expiry_days must be at least 1."
  }
}

variable "force_delete" {
  description = "Allow deleting the repository while it still contains images. Keep false outside sandboxes."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to the repository."
  type        = map(string)
  default     = {}
}
