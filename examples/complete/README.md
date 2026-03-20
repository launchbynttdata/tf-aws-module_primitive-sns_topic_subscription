# Complete example: SNS topic subscription to SQS

This example provisions (unless overridden) an SNS topic, a customer-managed KMS key, an encrypted SQS queue, a queue policy allowing the topic to publish, and an `aws_sns_topic_subscription` via the root module.

## Usage

```hcl
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  sqs_cmk_alias_name = "alias/sns-topic-subscription-example-${data.aws_caller_identity.current.account_id}"
  sqs_cmk_alias_arn  = "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.sqs_cmk_alias_name}"
}

module "resource_names" {
  source  = "terraform.registry.launch.nttdata.com/module_library/resource_name/launch"
  version = "~> 2.0"

  for_each = var.resource_names_map

  logical_product_family  = var.logical_product_family
  logical_product_service = var.logical_product_service
  class_env               = var.class_env
  instance_env            = var.instance_env
  instance_resource       = var.instance_resource
  cloud_resource_type     = each.value.name
  maximum_length          = each.value.max_length

  region = join("", split("-", data.aws_region.current.name))
}

resource "aws_sns_topic" "this" {
  count = var.topic_arn == null ? 1 : 0

  name = module.resource_names["sns_topic"].standard
}

data "aws_iam_policy_document" "kms_sqs" {
  count = var.endpoint == null ? 1 : 0

  statement {
    sid    = "EnableAccountRootPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowSNSEncryption"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.topic_arn == null ? aws_sns_topic.this[0].arn : var.topic_arn]
    }
  }

  statement {
    sid    = "AllowSQSUse"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sqs.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "sqs" {
  count = var.endpoint == null ? 1 : 0

  description             = "CMK for SNS subscription example SQS queue"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_sqs[0].json
}

resource "aws_kms_alias" "sqs" {
  count = var.endpoint == null ? 1 : 0

  name          = local.sqs_cmk_alias_name
  target_key_id = aws_kms_key.sqs[0].key_id
}

resource "aws_sqs_queue" "this" {
  count = var.endpoint == null ? 1 : 0

  name                              = module.resource_names["sqs_queue"].standard
  kms_master_key_id                 = local.sqs_cmk_alias_arn
  kms_data_key_reuse_period_seconds = 300

  depends_on = [aws_kms_alias.sqs]
}

data "aws_iam_policy_document" "sqs" {
  count = var.endpoint == null ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this[0].arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.topic_arn == null ? aws_sns_topic.this[0].arn : var.topic_arn]
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  count = var.endpoint == null ? 1 : 0

  queue_url = aws_sqs_queue.this[0].id
  policy    = data.aws_iam_policy_document.sqs[0].json
}

locals {
  topic_arn = coalesce(var.topic_arn, try(aws_sns_topic.this[0].arn, null))
  endpoint  = coalesce(var.endpoint, try(aws_sqs_queue.this[0].arn, null))
}

module "sns_topic_subscription" {
  source = "../.."

  topic_arn = local.topic_arn
  endpoint  = local.endpoint
  protocol  = var.protocol

  confirmation_timeout_in_minutes = var.confirmation_timeout_in_minutes
  delivery_policy                 = var.delivery_policy
  endpoint_auto_confirms          = var.endpoint_auto_confirms
  filter_policy                   = var.filter_policy
  filter_policy_scope             = var.filter_policy_scope
  raw_message_delivery            = var.raw_message_delivery
  redrive_policy                  = var.redrive_policy
  replay_policy                   = var.replay_policy
  subscription_role_arn           = var.subscription_role_arn

  depends_on = [aws_sqs_queue_policy.this]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.100 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_resource_names"></a> [resource\_names](#module\_resource\_names) | terraform.registry.launch.nttdata.com/module_library/resource_name/launch | ~> 2.0 |
| <a name="module_sns_topic_subscription"></a> [sns\_topic\_subscription](#module\_sns\_topic\_subscription) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sqs_queue.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_logical_product_family"></a> [logical\_product\_family](#input\_logical\_product\_family) | Logical product family for resource naming. | `string` | n/a | yes |
| <a name="input_logical_product_service"></a> [logical\_product\_service](#input\_logical\_product\_service) | Logical product service for resource naming. | `string` | n/a | yes |
| <a name="input_class_env"></a> [class\_env](#input\_class\_env) | Environment class for resource naming. | `string` | n/a | yes |
| <a name="input_instance_env"></a> [instance\_env](#input\_instance\_env) | Instance environment number for resource naming (0-999). | `number` | n/a | yes |
| <a name="input_instance_resource"></a> [instance\_resource](#input\_instance\_resource) | Instance resource number for resource naming (0-100). | `number` | n/a | yes |
| <a name="input_resource_names_map"></a> [resource\_names\_map](#input\_resource\_names\_map) | Map of resource name keys used by the resource\_name module (must include sns\_topic and sqs\_queue when this example creates those resources). | <pre>map(object({<br/>    name       = string<br/>    max_length = number<br/>  }))</pre> | n/a | yes |
| <a name="input_topic_arn"></a> [topic\_arn](#input\_topic\_arn) | When null, this example creates an SNS topic. When set, that topic ARN is used. | `string` | `null` | no |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | When null, this example creates an encrypted SQS queue. When set, that subscription endpoint is used. | `string` | `null` | no |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | Protocol to use for the subscription. | `string` | n/a | yes |
| <a name="input_confirmation_timeout_in_minutes"></a> [confirmation\_timeout\_in\_minutes](#input\_confirmation\_timeout\_in\_minutes) | Integer indicating the wait time for confirmation of an HTTP or HTTPS subscription. Only applicable when protocol is http or https. | `number` | `null` | no |
| <a name="input_delivery_policy"></a> [delivery\_policy](#input\_delivery\_policy) | JSON string for the subscription delivery policy (HTTP/S, SQS, etc.). | `string` | `null` | no |
| <a name="input_endpoint_auto_confirms"></a> [endpoint\_auto\_confirms](#input\_endpoint\_auto\_confirms) | Whether the endpoint is capable of auto-confirming the subscription (e.g., some HTTPS endpoints). | `bool` | `null` | no |
| <a name="input_filter_policy"></a> [filter\_policy](#input\_filter\_policy) | JSON string for the subscription filter policy. | `string` | `null` | no |
| <a name="input_filter_policy_scope"></a> [filter\_policy\_scope](#input\_filter\_policy\_scope) | Whether filter\_policy applies to MessageAttributes or MessageBody. | `string` | `null` | no |
| <a name="input_raw_message_delivery"></a> [raw\_message\_delivery](#input\_raw\_message\_delivery) | Whether to enable raw message delivery (supported for SQS, HTTP/S, and Firehose subscriptions). | `bool` | `null` | no |
| <a name="input_redrive_policy"></a> [redrive\_policy](#input\_redrive\_policy) | JSON string for the dead-letter queue redrive policy (SQS subscriptions). | `string` | `null` | no |
| <a name="input_replay_policy"></a> [replay\_policy](#input\_replay\_policy) | JSON string for FIFO topic message replay policy. | `string` | `null` | no |
| <a name="input_subscription_role_arn"></a> [subscription\_role\_arn](#input\_subscription\_role\_arn) | IAM role ARN for Kinesis Firehose delivery to a subscription. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | AWS region where this example applied resources (matches the Terraform AWS provider region). |
| <a name="output_topic_arn"></a> [topic\_arn](#output\_topic\_arn) | ARN of the SNS topic used by the subscription. |
| <a name="output_queue_arn"></a> [queue\_arn](#output\_queue\_arn) | ARN of the SQS queue when this example creates the queue. |
| <a name="output_queue_url"></a> [queue\_url](#output\_queue\_url) | URL of the SQS queue when this example creates the queue. |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the KMS key used for SQS encryption when this example creates the queue. |
| <a name="output_subscription_arn"></a> [subscription\_arn](#output\_subscription\_arn) | ARN of the SNS topic subscription. |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | ID of the SNS topic subscription. |
| <a name="output_subscription_owner_id"></a> [subscription\_owner\_id](#output\_subscription\_owner\_id) | AWS account ID of the subscription owner. |
| <a name="output_subscription_pending_confirmation"></a> [subscription\_pending\_confirmation](#output\_subscription\_pending\_confirmation) | Whether the subscription is pending confirmation. |
| <a name="output_subscription_endpoint"></a> [subscription\_endpoint](#output\_subscription\_endpoint) | Subscription endpoint. |
| <a name="output_subscription_confirmation_was_authenticated"></a> [subscription\_confirmation\_was\_authenticated](#output\_subscription\_confirmation\_was\_authenticated) | Whether the subscription confirmation was authenticated. |
| <a name="output_protocol"></a> [protocol](#output\_protocol) | Subscription protocol. |
| <a name="output_raw_message_delivery"></a> [raw\_message\_delivery](#output\_raw\_message\_delivery) | Raw message delivery setting passed to the module. |
<!-- END_TF_DOCS -->
