# AWS/Terraform/Python

When User A uploaded a jpg file into Bucket A it will trigger a lambda function which will then remove the EXIF data and put the file into Bucket B. 

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 1.1 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.2.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket_a"></a> [bucket\_a](#module\_bucket\_a) | ./modules/s3_bucket | n/a |
| <a name="module_bucket_b"></a> [bucket\_b](#module\_bucket\_b) | ./modules/s3_bucket | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.remove_image_exif_lambda_function_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.remove_image_exif_lambda_execution_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.remove_image_exif_lambda_execution_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_user.user_a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user.user_b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.user_a_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_iam_user_policy.user_b_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_lambda_function.remove_image_exif_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_bucket_a_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_account_public_access_block.block_public_buckets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_account_public_access_block) | resource |
| [aws_s3_bucket_notification.bucket_a_lambda_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [archive_file.remove_image_exif_lambda_function_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS deployment region | `string` | `"eu-west-2"` | no |
| <a name="input_bucket_a_name_prefix"></a> [bucket\_a\_name\_prefix](#input\_bucket\_a\_name\_prefix) | Bucket A name prefix, to be appened to a random string | `string` | `"bucket-a-"` | no |
| <a name="input_bucket_b_name_prefix"></a> [bucket\_b\_name\_prefix](#input\_bucket\_b\_name\_prefix) | Bucket B name prefix, to be appened to a random string | `string` | `"bucket-b-"` | no |
| <a name="input_remove_image_exif_lambda_function_name"></a> [remove\_image\_exif\_lambda\_function\_name](#input\_remove\_image\_exif\_lambda\_function\_name) | Name of the Lambda function to remove exif data from images uploaded to s3 | `string` | `"RemoveImageExifData"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->