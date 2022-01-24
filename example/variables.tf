variable "name" {
  description = "function name"
  type        = string
  default     = "benthos-lambda-example"
}

variable "key" {
  description = "example credential"
  type        = string
  sensitive   = true
  default     = "foo"
}
