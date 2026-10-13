output "role_arn" {
  description = "ARN of the CI role. Set as the AWS_ROLE_ARN repository variable in GitHub."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the CI role."
  value       = aws_iam_role.this.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider used in the trust policy."
  value       = local.provider_arn
}
