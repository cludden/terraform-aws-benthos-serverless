variable "config" {
  description = "gomplate templated benthos config (YAML format)"
  type        = string
}

variable "config_datasources" {
  description = "map of gomplate datasources referenced by config"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "map of additional environment variables"
  type        = map(string)
  default     = {}
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
