output "api_gateway_invoke_url" {
  description = "The URL to invoke the API Gateway endpoint"
  value       = "https://${aws_api_gateway_domain_name.api_domain.domain_name}/${aws_api_gateway_deployment.api_deployment.stage_name}${aws_api_gateway_resource.api_resource.path}"
}