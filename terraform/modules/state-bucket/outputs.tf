output "bucket_name" {
  description = "Name of the state bucket (use in backend configuration)."
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.state.arn
}

output "kms_key_arn" {
  description = "KMS key ARN used to encrypt state (use as backend kms_key_id)."
  value       = local.kms_key_arn
}
