output "state_bucket_name" {
  description = "State bucket name. Put this in envs/*/backend.hcl."
  value       = module.state_bucket.bucket_name
}

output "state_kms_key_arn" {
  description = "KMS key encrypting state. Put this in envs/*/backend.hcl as kms_key_id."
  value       = module.state_bucket.kms_key_arn
}
