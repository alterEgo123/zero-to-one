output "lambda_function_uri" {
  value = aws_lambda_function_url.test_latest.function_url
}

output "sns_topic_arn" {
  value = aws_sns_topic.results_updates.arn
}
