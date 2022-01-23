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

  input = <<-JSON
    {
      "version": "0",
      "id": "12345678-1234-1234-1234-123456789012",
      "detail-type": "EC2 Instance-launch Lifecycle Action",
      "source": "aws.autoscaling",
      "account": "123456789012",
      "time": "yyyy-mm-ddThh:mm:ssZ",
      "region": "us-west-2",
      "resources": [
        "auto-scaling-group-arn"
      ],
      "detail": { 
        "LifecycleActionToken": "87654321-4321-4321-4321-210987654321", 
        "AutoScalingGroupName": "my-asg", 
        "LifecycleHookName": "my-lifecycle-hook", 
        "EC2InstanceId": "i-1234567890abcdef0", 
        "LifecycleTransition": "autoscaling:EC2_INSTANCE_TERMINATING",
        "NotificationMetadata": "additional-info"
      } 
    }
  JSON

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
resource "aws_ssm_parameter" "secrets" {
  for_each = {
    "slack-channel" = var.slack_channel
    "slack-token"   = var.slack_token
  }
  name  = "/${var.name}/${each.key}"
  type  = "SecureString"
  value = each.value
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
          channel = "{{ (ds "ssm" "slack-channel").Value }}"
          text = "EC2 Instance %s has been terminated.".format(detail.EC2InstanceId)
          blocks = [{
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "EC2 Instance `%s` has been terminated.".format(detail.EC2InstanceId)
            }
          }, {
            "type": "context",
            "elements": [{
              "type": "mrkdwn",
              "text": "*account:* %s".format(account)
            }, {
              "type": "mrkdwn",
              "text": "*region:* %s".format(region)
            }, {
              "type": "mrkdwn",
              "text": "*group:* %s".format(detail.AutoScalingGroupName)
            }]
          }]

    output:
      switch:
        retry_until_success: false
        cases:
        - check: errored()
          output:
            reject: "$${!error()}"
        - output:
            http_client:
              url: https://slack.com/api/chat.postMessage
              propagate_response: true
              headers:
                Authorization: Bearer {{ (ds "ssm" "slack-token").Value }}
                Content-Type: application/json; charset=utf-8
  YAML

  config_datasources = {
    ssm = "aws+smp:///${var.name}"
  }

  statements = [{
    actions   = ["ssm:GetParameter"]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}/*"]
  }]
}
