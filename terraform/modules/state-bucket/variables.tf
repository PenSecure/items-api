variable "bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid S3 bucket name."
  }
}

variable "kms_key_arn" {
  description = "Existing KMS key ARN for state encryption. Null creates a dedicated key."
  type        = string
  default     = null
}

variable "noncurrent_version_retention_days" {
  description = "Days to keep noncurrent state versions (your rollback window)."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags applied to created resources."
  type        = map(string)
  default     = {}
}
