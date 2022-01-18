variable "name" {
  description = "function name"
  type        = string
  default     = "benthos-lambda-example"
}

variable "slack_channel" {
  description = "slack channel"
  type        = string
  sensitive   = true
}

variable "slack_token" {
  description = "slack api token"
  type        = string
  sensitive   = true
}
