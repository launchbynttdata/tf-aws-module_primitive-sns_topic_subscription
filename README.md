# tf-aws-module_primitive-sns_topic_subscription

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

## Overview

Terraform primitive module that wraps a single [`aws_sns_topic_subscription`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) resource. It exposes the arguments and attributes supported by the AWS provider so callers can configure subscriptions without losing functionality.

## Usage

```hcl
module "sns_topic_subscription" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/sns_topic_subscription/aws"
  version = "~> 1.0"

  topic_arn = aws_sns_topic.example.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.example.arn

  raw_message_delivery = true
}
```

## Examples

See [`examples/complete/`](./examples/complete/) for an end-to-end subscription from an SNS topic to an encrypted SQS queue.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.100 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic_subscription.sns_topic_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_confirmation_timeout_in_minutes"></a> [confirmation\_timeout\_in\_minutes](#input\_confirmation\_timeout\_in\_minutes) | Integer indicating the wait time for confirmation of an HTTP or HTTPS subscription. Only applicable when protocol is http or https. | `number` | `null` | no |
| <a name="input_delivery_policy"></a> [delivery\_policy](#input\_delivery\_policy) | JSON string for the subscription delivery policy (HTTP/S, SQS, etc.). | `string` | `null` | no |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Endpoint to send data to. The contents vary by protocol (e.g., SQS queue ARN, HTTPS URL, Lambda function ARN). | `string` | n/a | yes |
| <a name="input_endpoint_auto_confirms"></a> [endpoint\_auto\_confirms](#input\_endpoint\_auto\_confirms) | Whether the endpoint is capable of auto-confirming the subscription (e.g., some HTTPS endpoints). | `bool` | `null` | no |
| <a name="input_filter_policy"></a> [filter\_policy](#input\_filter\_policy) | JSON string for the subscription filter policy. | `string` | `null` | no |
| <a name="input_filter_policy_scope"></a> [filter\_policy\_scope](#input\_filter\_policy\_scope) | Whether filter\_policy applies to MessageAttributes or MessageBody. | `string` | `null` | no |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | Protocol to use. Valid values include application, firehose, http, https, lambda, sms, sqs, email, email-json. | `string` | n/a | yes |
| <a name="input_raw_message_delivery"></a> [raw\_message\_delivery](#input\_raw\_message\_delivery) | Whether to enable raw message delivery (supported for SQS, HTTP/S, and Firehose subscriptions). | `bool` | `null` | no |
| <a name="input_redrive_policy"></a> [redrive\_policy](#input\_redrive\_policy) | JSON string for the dead-letter queue redrive policy (SQS subscriptions). | `string` | `null` | no |
| <a name="input_replay_policy"></a> [replay\_policy](#input\_replay\_policy) | JSON string for FIFO topic message replay policy. | `string` | `null` | no |
| <a name="input_subscription_role_arn"></a> [subscription\_role\_arn](#input\_subscription\_role\_arn) | IAM role ARN for Kinesis Firehose delivery to a subscription. | `string` | `null` | no |
| <a name="input_topic_arn"></a> [topic\_arn](#input\_topic\_arn) | ARN of the SNS topic to subscribe to. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the subscription. |
| <a name="output_confirmation_was_authenticated"></a> [confirmation\_was\_authenticated](#output\_confirmation\_was\_authenticated) | Whether the subscription confirmation request was authenticated. |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | The subscription endpoint (same as the configured endpoint argument). |
| <a name="output_id"></a> [id](#output\_id) | The ID of the subscription (same as the subscription ARN). |
| <a name="output_owner_id"></a> [owner\_id](#output\_owner\_id) | The AWS account ID of the subscription owner. |
| <a name="output_pending_confirmation"></a> [pending\_confirmation](#output\_pending\_confirmation) | Whether the subscription is pending confirmation. |
<!-- END_TF_DOCS -->

## Module Development

### Pre-Requisites

The following commands should be available on your system:

- `asdf` or `mise`
- `make`
- `python3` (for pre-commit)

Additionally, your `git` user and email must be configured. Run the `make configure` command from the root of the repository to ensure that you meet these requirements.

### Pre-Commit hooks

The [.pre-commit-config.yaml](.pre-commit-config.yaml) file defines certain `pre-commit` hooks that are relevant to Terraform and Golang, as well as some common linting tasks. These will be configured for you when you run `make configure`.

### Local Validation

You should validate the changes you make to any module locally, prior to pushing your changes in a branch to GitHub.

1. Ensure that you have run `make configure` successfully.

2. Ensure you are signed into the appropriate cloud provider (e.g. AWS or Azure) for the module under test in your current console session.

3. Run the Terraform and Golang linters with the following command:

```
make lint
```

4. Once you have satisfied the linters, the following command will build example infrastructure in your configured cloud, run the tests, and then tear down the infrastructure it created:

```
make test
```

The pre-commit validations, as well as the `make lint` and `make test` targets, will all be performed in CI. Running these validations locally prior to opening a PR helps ensure a smooth review and merge process.

### Review & Merge Process

Once your change has been tested locally and your branch pushed up, open a new Pull Request for your branch to the default (main) branch of this repository.

The title of your Pull Request will determine the version bump for this change, and the title must be in [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) format in order to merge. A breaking change will trigger a major version bump, a feature will trigger a minor version bump, and all other types will trigger a patch version bump.

Ensure your CI workflows are passing; seek approval from teammates and address any feedback; seek any explicit approvals required by the CODEOWNERS file. You may merge the PR as soon as all requirements are met, and a new release and tag will be automatically created for you.

### Automatic Updates

The shared configuration and workflow files in this repository are largely managed through the [launch-terraform-skeleton](https://github.com/launchbynttdata/launch-terraform-skeleton) repository. Outside of perhaps the `.gitignore` to account for specific files being generated by certain Terraform modules (e.g. Lambda functions), there should not be much cause to update these files on a per-repo basis, and making changes to them individually is discouraged.

If desired, you can check for and run these updates locally in a branch if you have the `copier` tool installed. Some example commands are included below:

```
# Check for updates, optionally checking prerelease versions
copier check-update [--prereleases]

# Run an update, using default answers if there are any. We use tasks, which requires --trust to be set.
copier update --defaults --trust [--prereleases]

# Recopy from the source, and --overwrite all templated files in the process
copier recopy --defaults --trust --overwrite [--prereleases]
```

Automatic updates will run through a scheduled workflow, and if the post-update tests are successful, the Pull Request created will automatically merge. Conflicts in the update or failures to test may leave a Pull Request outstanding, which needs to be addressed by a Launch Engineer.
