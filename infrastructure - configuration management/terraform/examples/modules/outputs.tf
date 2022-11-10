output "website_bucket_arn" {
  description = "ARN of the bucket"
  value       = module.website_s3_bucket.arn
}

output "website_bucket_name" {
  description = "Name (id) of the bucket"
  value       = module.website_s3_bucket.name
}

output "website_bucket_domain" {
  description = "Domain name of the bucket"
  value       = module.website_s3_bucket.domain
}

output "lambda_function_uri" {
  description = "Domain name of the bucket"
  value       = module.sns.lambda_function_uri
}

output "sns_topic_arn" {
  description = "Domain name of the bucket"
  value       = module.sns.sns_topic_arn
}

