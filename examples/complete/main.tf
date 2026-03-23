// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

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

# Alias ARN must be known at plan time (data sources + variable-derived names only) so tf-plan
# scanners (FG_R00070) see a concrete kms_master_key_id on aws_sqs_queue. The suffix comes from the
# same resource_name output as the queue so the alias stays unique per naming inputs without random_id
# (which would be unknown at plan time and would break that check).
locals {
  sqs_cmk_alias_slug = var.endpoint == null ? replace(replace(module.resource_names["sqs_queue"].standard, "/", "-"), ".", "-") : null
  sqs_cmk_alias_name = var.endpoint == null ? "alias/sns-topic-subscription-example-${data.aws_caller_identity.current.account_id}-${local.sqs_cmk_alias_slug}" : null
  sqs_cmk_alias_arn  = var.endpoint == null ? "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.sqs_cmk_alias_name}" : null
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
