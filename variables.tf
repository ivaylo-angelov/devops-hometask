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
  default     = "random-data-bucket2024"
}
