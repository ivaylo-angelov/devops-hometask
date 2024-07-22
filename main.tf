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