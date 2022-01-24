output "function" {
  description = "function outputs"
  value       = module.benthos_lambda
}

output "result" {
  description = "function outputs"
  value       = jsondecode(data.aws_lambda_invocation.test.result)
}
