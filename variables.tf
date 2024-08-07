variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-west-2"
}

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
  default     = "random-data-bucket-123"
}

variable "s3_bucket_arn" {
  description = "The arn of the S3 bucket"
  type        = string
  default     = "arn:aws:s3:::random-data-bucket-123"
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate for the custom domain"
  type        = string
  default     = "arn:aws:acm:eu-west-2:975050253939:certificate/24eceba7-4603-49c1-b33a-4463603b7d30"
}