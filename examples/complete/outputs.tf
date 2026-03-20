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

output "aws_region" {
  description = "AWS region where this example applied resources (matches the Terraform AWS provider region)."
  value       = data.aws_region.current.name
}

output "topic_arn" {
  description = "ARN of the SNS topic used by the subscription."
  value       = local.topic_arn
}

output "queue_arn" {
  description = "ARN of the SQS queue when this example creates the queue."
  value       = try(aws_sqs_queue.this[0].arn, null)
}

output "queue_url" {
  description = "URL of the SQS queue when this example creates the queue."
  value       = try(aws_sqs_queue.this[0].id, null)
}

output "kms_key_id" {
  description = "ID of the KMS key used for SQS encryption when this example creates the queue."
  value       = try(aws_kms_key.sqs[0].id, null)
}

output "subscription_arn" {
  description = "ARN of the SNS topic subscription."
  value       = module.sns_topic_subscription.arn
}

output "subscription_id" {
  description = "ID of the SNS topic subscription."
  value       = module.sns_topic_subscription.id
}

output "subscription_owner_id" {
  description = "AWS account ID of the subscription owner."
  value       = module.sns_topic_subscription.owner_id
}

output "subscription_pending_confirmation" {
  description = "Whether the subscription is pending confirmation."
  value       = module.sns_topic_subscription.pending_confirmation
}

output "subscription_endpoint" {
  description = "Subscription endpoint."
  value       = module.sns_topic_subscription.endpoint
}

output "subscription_confirmation_was_authenticated" {
  description = "Whether the subscription confirmation was authenticated."
  value       = module.sns_topic_subscription.confirmation_was_authenticated
}

output "protocol" {
  description = "Subscription protocol."
  value       = var.protocol
}

output "raw_message_delivery" {
  description = "Raw message delivery setting passed to the module."
  value       = var.raw_message_delivery
}
