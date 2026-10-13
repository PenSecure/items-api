output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ARN of the ECR repository (used to scope IAM policies)."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "Repository URL to tag and push images to."
  value       = aws_ecr_repository.this.repository_url
}
