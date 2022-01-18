output "arn" {
  description = "function arn"
  value       = aws_lambda_function.this.arn
}

output "id" {
  description = "function name"
  value       = aws_lambda_function.this.function_name
}

output "role_arn" {
  description = "function role arn"
  value       = var.role_arn != null ? var.role_arn : aws_iam_role.this.0.arn
}

output "role_id" {
  description = "function role name"
  value       = var.role_arn != null ? "" : aws_iam_role.this.0.id
}
