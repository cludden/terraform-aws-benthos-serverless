<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.72.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_benthos_lambda"></a> [benthos\_lambda](#module\_benthos\_lambda) | ../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ssm_parameter.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_lambda_invocation.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_invocation) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_key"></a> [key](#input\_key) | example credential | `string` | `"foo"` | no |
| <a name="input_name"></a> [name](#input\_name) | function name | `string` | `"benthos-lambda-example"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function"></a> [function](#output\_function) | function outputs |
| <a name="output_result"></a> [result](#output\_result) | function outputs |
<!-- END_TF_DOCS -->