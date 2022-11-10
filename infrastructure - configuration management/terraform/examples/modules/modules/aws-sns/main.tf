resource "aws_sns_topic" "results_updates" {
  name = "results-updates-topic"
}

resource "aws_sqs_queue" "results_updates_queue" {
  name                       = "results-updates-queue"
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.results_updates_dl_queue.arn}\",\"maxReceiveCount\":5}"
  visibility_timeout_seconds = 300

  tags = {
    Environment = "dev"
  }
}

resource "aws_sqs_queue" "results_updates_dl_queue" {
  name = "results-updates-dl-queue"
}

resource "aws_sns_topic_subscription" "results_updates_sqs_target" {
  topic_arn = aws_sns_topic.results_updates.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.results_updates_queue.arn
}

resource "aws_sqs_queue_policy" "results_updates_queue_policy" {
  queue_url = aws_sqs_queue.results_updates_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.results_updates_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.results_updates.arn}"
        }
      }
    }
  ]
}
POLICY
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/function.py"
  output_path = "${path.module}/lambda/function.zip"
}

resource "aws_lambda_function" "results_updates_lambda" {
  filename         = "${path.module}/lambda/function.zip"
  function_name    = "hello_world_example"
  role             = aws_iam_role.lambda_role.arn
  handler          = "example.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
}

resource "aws_iam_role" "lambda_role" {
  name               = "LambdaRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_role_sqs_policy" {
  name   = "AllowSQSPermissions"
  role   = aws_iam_role.lambda_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_role_logs_policy" {
  name   = "LambdaRolePolicy"
  role   = aws_iam_role.lambda_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_lambda_function_url" "test_latest" {
  function_name      = aws_lambda_function.results_updates_lambda.function_name
  authorization_type = "NONE"
}

resource "aws_api_gateway_rest_api" "api_gw" {
  name = "My API Gateway"
}

resource "aws_api_gateway_resource" "proxy" {
  parent_id     = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part     = "lambda"
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
}

resource "aws_api_gateway_method" "proxy" {
  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.proxy.id
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
}

resource "aws_api_gateway_integration" "lambda" {
  integration_http_method = "POST"
  resource_id             = aws_api_gateway_resource.proxy.id
  rest_api_id             = aws_api_gateway_rest_api.api_gw.id
  http_method             = aws_api_gateway_method.proxy.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.results_updates_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "api_gw_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda]
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  stage_name  = "test"
}

resource "aws_lambda_permission" "api_gw" {
  action        = "lambda:InvokeFunction"
  statement_id  = "AllowAPIGatewayInvoke"
  function_name = aws_lambda_function.results_updates_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gw.execution_arn}/*/*"
}