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

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = var.topic_arn
  protocol  = var.protocol
  endpoint  = var.endpoint

  confirmation_timeout_in_minutes = var.confirmation_timeout_in_minutes
  delivery_policy                 = var.delivery_policy
  endpoint_auto_confirms          = var.endpoint_auto_confirms
  filter_policy                   = var.filter_policy
  filter_policy_scope             = var.filter_policy_scope
  raw_message_delivery            = var.raw_message_delivery
  redrive_policy                  = var.redrive_policy
  replay_policy                   = var.replay_policy
  subscription_role_arn           = var.subscription_role_arn
}
