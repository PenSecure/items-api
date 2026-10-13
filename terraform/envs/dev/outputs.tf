output "ecr_repository_url" {
  description = "Push images here. Set ECR_REPOSITORY in GitHub to the repository name."
  value       = module.ecr.repository_url
}

output "ci_role_arn" {
  description = "Set as the AWS_ROLE_ARN repository variable in GitHub."
  value       = module.ci_role.role_arn
}
