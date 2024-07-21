variable "coinmarketcap_url" {
  description = "The URL for the CoinMarketCap API"
  type        = string
  default     = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest"
}

variable "coinmarketcap_api_key" {
  description = "The API key for CoinMarketCap"
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "my-random-data-bucket"
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate for the custom domain"
  type        = string
  default     = "arn:aws:acm:eu-west-2:975050253939:certificate/0d304b70-8079-45af-ad1d-2d88f55e3521"
}