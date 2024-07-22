provider "aws" {
  region = "eu-west-2"
}

resource "aws_secretsmanager_secret" "coinmarketcap_api_key" {
  name = "coinmarketcap_api_key"
}

resource "aws_secretsmanager_secret_version" "coinmarketcap_api_key_version" {
  secret_id     = aws_secretsmanager_secret.coinmarketcap_api_key.id
  secret_string = jsonencode({ api_key = var.coinmarketcap_api_key })
}

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

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Effect   = "Allow",
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.coinmarketcap_api_key.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
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

resource "aws_api_gateway_rest_api" "random_data_api" {
  name        = "RandomDataAPI"
  description = "API Gateway to trigger Lambda for random data"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.random_data_api.id
  parent_id   = aws_api_gateway_rest_api.random_data_api.root_resource_id
  path_part   = "populate"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.random_data_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.random_data_api.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.random_data_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.random_data_api.id
  stage_name  = "prod"
}

resource "aws_api_gateway_domain_name" "api_domain" {
  domain_name    = "api.example.com"
  regional_certificate_arn  = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "path_mapping" {
  api_id      = aws_api_gateway_rest_api.random_data_api.id
  stage_name  = aws_api_gateway_deployment.api_deployment.stage_name
  domain_name = aws_api_gateway_domain_name.api_domain.domain_name
}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
  rest_api_id = aws_api_gateway_rest_api.random_data_api.id

  policy = templatefile("${path.module}/api_policy.json.tpl", {
    rest_api_id = aws_api_gateway_rest_api.random_data_api.id
  })
}