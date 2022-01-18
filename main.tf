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
  }
}

################################################################################
## Resources
################################################################################

# provision lambda function
resource "aws_lambda_function" "this" {
  filename         = "${path.module}/benthos-lambda.zip"
  function_name    = var.name
  handler          = "benthos-lambda"
  layers           = [aws_lambda_layer_version.gomplate.arn]
  role             = var.role_arn != null ? var.role_arn : aws_iam_role.this.0.arn
  runtime          = "go1.x"
  source_code_hash = filebase64sha256("${path.module}/benthos-lambda.zip")
  timeout          = var.timeout

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

  depends_on = [
    aws_cloudwatch_log_group.this
  ]
}

resource "aws_lambda_layer_version" "gomplate" {
  filename            = "${path.module}/gomplate-lambda-extension.zip"
  layer_name          = "${var.name}-gomplate"
  compatible_runtimes = ["go1.x"]
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

