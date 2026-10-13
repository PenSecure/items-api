variable "aws_region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Project name, used for tagging."
  type        = string
  default     = "items-api"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
}
