# tf-aws-module_primitive-sns_topic_subscription

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

## Overview

Terraform primitive module that wraps a single [`aws_sns_topic_subscription`](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/sns_topic_subscription) resource. It exposes the arguments and attributes supported by the AWS provider so callers can configure subscriptions without losing functionality.

## Usage

```hcl
module "sns_topic_subscription" {
  source = "path/to/module"

  topic_arn = aws_sns_topic.example.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.example.arn

  raw_message_delivery = true
}
```

## Requirements

- Terraform `~> 1.9`
- AWS provider `~> 5.100` (see [`versions.tf`](./versions.tf))

## Examples

See [`examples/complete/`](./examples/complete/) for an end-to-end subscription from an SNS topic to an encrypted SQS queue.

## Contributing

Run `make configure` once to sync shared automation components, then use the standard targets from the included Makefile (for example `make lint`, `make check`).

Pre-commit hooks enforce formatting and documentation. Install with `pre-commit install` after `make configure`.

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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic_subscription.sns_topic_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_topic_arn"></a> [topic\_arn](#input\_topic\_arn) | ARN of the SNS topic to subscribe to. | `string` | n/a | yes |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | Protocol to use. Valid values include application, firehose, http, https, lambda, sms, sqs, email, email-json. | `string` | n/a | yes |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Endpoint to send data to. The contents vary by protocol (e.g., SQS queue ARN, HTTPS URL, Lambda function ARN). | `string` | n/a | yes |
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
| <a name="output_id"></a> [id](#output\_id) | The ID of the subscription (same as the subscription ARN). |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the subscription. |
| <a name="output_owner_id"></a> [owner\_id](#output\_owner\_id) | The AWS account ID of the subscription owner. |
| <a name="output_pending_confirmation"></a> [pending\_confirmation](#output\_pending\_confirmation) | Whether the subscription is pending confirmation. |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | The subscription endpoint (same as the configured endpoint argument). |
| <a name="output_confirmation_was_authenticated"></a> [confirmation\_was\_authenticated](#output\_confirmation\_was\_authenticated) | Whether the subscription confirmation request was authenticated. |
<!-- END_TF_DOCS -->
