################################################################################
## Terraform
################################################################################

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

################################################################################
## Data Sources
################################################################################

# invoke lambda function with sample event
data "aws_lambda_invocation" "test" {
  function_name = module.benthos_lambda.id

  input = jsonencode({
    data = "hello, world!"
  })

  depends_on = [
    module.benthos_lambda
  ]
}

# lookup aws session
data "aws_caller_identity" "current" {}

# lookup aws partition info
data "aws_partition" "current" {}

# lookup aws region info
data "aws_region" "current" {}

################################################################################
## Resources
################################################################################

# store sensitive configuration in ssm parameter store
resource "aws_ssm_parameter" "key" {
  name  = "/${var.name}/key"
  type  = "SecureString"
  value = var.key
}

# deploy benthos lambda function using ssm as config datasource
module "benthos_lambda" {
  source = "../"

  name    = var.name
  timeout = 30

  config = <<-YAML
    pipeline:
      processors:
      # format slack chat.postMessage payload
      - bloblang: |
          root = this
          signature = content().hash("hmac_sha256", "{{ (ds "ssm" "key").Value }}").encode("hex")
      
      # log response
      - log:
          message: "$${!content().string()}"

    output:
      switch:
        retry_until_success: false
        cases:
        - check: errored()
          output:
            reject: "$${!error()}"
        - output:
            sync_response: {}
  YAML

  config_datasources = {
    ssm = "aws+smp:///${var.name}"
  }

  statements = [
    {
      actions   = ["ssm:GetParameter"]
      effect    = "Allow"
      resources = ["arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}/*"]
    }
  ]

  depends_on = [
    aws_ssm_parameter.key
  ]
}
