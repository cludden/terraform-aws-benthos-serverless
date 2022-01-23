variable "benthos_version" {
  description = "benthos artifact version"
  type        = string
  default     = "3.62.0"
}

variable "config" {
  description = "gomplate templated benthos config (YAML format)"
  type        = string
}

variable "config_datasources" {
  description = "map of gomplate datasources referenced by config"
  type        = map(string)
  default     = {}
}

variable "description" {
  description = "lambda function description"
  type        = string
  default     = "benthos-lambda"
}

variable "environment" {
  description = "map of additional environment variables"
  type        = map(string)
  default     = {}
}

variable "gomplate_version" {
  description = "gomplate-lambda-extension artifact version"
  type        = string
  default     = "0.1.1"
}

variable "memory_size" {
  description = "amount of memory in MB your Lambda Function can use at runtime"
  type        = number
  default     = 128
}

variable "name" {
  description = "function name"
  type        = string
}

variable "retention_in_days" {
  description = "function log retention in days"
  type        = number
  default     = 7
}

variable "reserved_concurrent_executions" {
  description = "amount of reserved concurrent executions for this lambda function"
  type        = number
  default     = -1
}

variable "role_arn" {
  description = "execution role arn"
  type        = string
  default     = null
}

variable "role_name" {
  description = "override default execution role name"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "list of vpc security group ids"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "list of vpc subnet ids"
  type        = list(string)
  default     = []
}

variable "statements" {
  description = "customize role policy statements"
  type = list(object({
    actions = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })))
    effect    = optional(string)
    resources = list(string)
  }))
  default = []
}

variable "timeout" {
  description = "function timeout in seconds"
  type        = number
  default     = 3
}
