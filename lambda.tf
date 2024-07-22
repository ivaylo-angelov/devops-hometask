resource "aws_iam_role" "lambda_role" {
  name = "random_data_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "random_data_lambda_policy"
  description = "IAM policy for Lambda execution, allowing access to S3, Secrets Manager, and CloudWatch Logs"

  policy = templatefile("${path.module}/lambda_policy.json.tpl", {
    s3_bucket_arn     = var.s3_bucket_arn,
    secretsmanager_arn = aws_secretsmanager_secret.coinmarketcap_api_key.arn
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

resource "aws_lambda_function" "random_data_lambda" {
  function_name = "random_data_lambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 60
  memory_size   = 128

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      COINMARKETCAP_URL = var.coinmarketcap_url
      BUCKET_NAME       = var.s3_bucket_name
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "event_invoke_config" {
  function_name = aws_lambda_function.random_data_lambda.function_name
  maximum_retry_attempts = 0
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowMyDemoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.random_data_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.random_data_api.execution_arn}/*"
}