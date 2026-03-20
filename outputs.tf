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

output "id" {
  description = "The ID of the subscription (same as the subscription ARN)."
  value       = aws_sns_topic_subscription.sns_topic_subscription.id
}

output "arn" {
  description = "The ARN of the subscription."
  value       = aws_sns_topic_subscription.sns_topic_subscription.arn
}

output "owner_id" {
  description = "The AWS account ID of the subscription owner."
  value       = aws_sns_topic_subscription.sns_topic_subscription.owner_id
}

output "pending_confirmation" {
  description = "Whether the subscription is pending confirmation."
  value       = aws_sns_topic_subscription.sns_topic_subscription.pending_confirmation
}

output "endpoint" {
  description = "The subscription endpoint (same as the configured endpoint argument)."
  value       = aws_sns_topic_subscription.sns_topic_subscription.endpoint
}

output "confirmation_was_authenticated" {
  description = "Whether the subscription confirmation request was authenticated."
  value       = aws_sns_topic_subscription.sns_topic_subscription.confirmation_was_authenticated
}
