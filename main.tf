################################################################################
## Terraform
################################################################################

terraform {
  required_version = ">= 1.0.0"
  experiments      = [module_variable_optional_attrs]

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
    get = {
      source  = "cludden/get"
      version = "0.1.0"
    }
  }
}

################################################################################
## Resources
################################################################################

# provision lambda function
resource "aws_lambda_function" "this" {
  description                    = var.description
  filename                       = get_artifact.benthos.dest
  function_name                  = var.name
  handler                        = "benthos-lambda"
  layers                         = [aws_lambda_layer_version.gomplate.arn]
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = var.role_arn != null ? var.role_arn : aws_iam_role.this.0.arn
  runtime                        = "go1.x"
  source_code_hash               = get_artifact.benthos.sum64
  timeout                        = var.timeout

  environment {
    variables = merge(
      var.environment,
      {
        BENTHOS_CONFIG_PATH = "/tmp/benthos.yml"
        GOMPLATE_INPUT      = var.config
        GOMPLATE_OUTPUT     = "/tmp/benthos.yml"
      },
      {
        for dsk, dsv in var.config_datasources :
        "GOMPLATE_DATASOURCE_${dsk}" => dsv
      }
    )
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []

    content {
      security_group_ids = var.security_group_ids
      subnet_ids         = var.subnet_ids
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
  ]
}

# provision gomplate extension lambda layer
resource "aws_lambda_layer_version" "gomplate" {
  filename            = get_artifact.gomplate.dest
  layer_name          = "${var.name}-gomplate"
  compatible_runtimes = ["go1.x"]

  depends_on = [
    get_artifact.gomplate,
  ]
}

##############################
## Artifacts
##############################

# download benthos-serverless distribution
resource "get_artifact" "benthos" {
  url      = "https://github.com/Jeffail/benthos/releases/download/v${var.benthos_version}/benthos-lambda_${var.benthos_version}_linux_amd64.zip"
  checksum = "file:https://github.com/Jeffail/benthos/releases/download/v${var.benthos_version}/benthos_${var.benthos_version}_checksums.txt"
  dest     = "benthos-lambda_${var.benthos_version}_linux_amd64.zip"
  mode     = "file"
  archive  = false
  workdir  = abspath(path.root)
}

# download gomplate-lambda-extension distribution
resource "get_artifact" "gomplate" {
  url      = "https://github.com/cludden/gomplate-lambda-extension/releases/download/v${var.gomplate_version}/gomplate-lambda-extension_${var.gomplate_version}_linux_amd64.zip"
  checksum = "file:https://github.com/cludden/gomplate-lambda-extension/releases/download/v${var.gomplate_version}/checksums.txt"
  dest     = "gomplate-lambda-extension_${var.gomplate_version}_linux_amd64.zip"
  mode     = "file"
  archive  = false
  workdir  = abspath(path.root)
}

##############################
## CloudWatch
##############################

# provision log group for function logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.retention_in_days
}

##############################
## IAM
##############################

# provision execution role
resource "aws_iam_role" "this" {
  count              = var.role_arn != null ? 0 : 1
  name               = coalesce(var.role_name, var.name)
  assume_role_policy = data.aws_iam_policy_document.trust.0.json

  inline_policy {
    name   = "inline"
    policy = data.aws_iam_policy_document.this.0.json
  }

  tags = {
    Name = coalesce(var.role_name, var.name)
  }
}

# define execution role trust policy
data "aws_iam_policy_document" "trust" {
  count = var.role_arn != null ? 0 : 1

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# define execution role policy statements
data "aws_iam_policy_document" "this" {
  count = var.role_arn != null ? 0 : 1

  # allow function to push logs to cloudwatch
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.this.arn}*"]
  }

  # render dynamic policy statements
  dynamic "statement" {
    for_each = var.statements

    content {
      actions   = statement.value.actions
      effect    = coalesce(statement.value.effect, "Allow")
      resources = statement.value.resources

      dynamic "condition" {
        for_each = statement.value.conditions != null ? statement.value.conditions : []

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

