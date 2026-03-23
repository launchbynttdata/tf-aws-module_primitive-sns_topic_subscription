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

# Resource naming (example infrastructure)

variable "logical_product_family" {
  description = "Logical product family for resource naming."
  type        = string
}

variable "logical_product_service" {
  description = "Logical product service for resource naming."
  type        = string
}

variable "class_env" {
  description = "Environment class for resource naming."
  type        = string
}

variable "instance_env" {
  description = "Instance environment number for resource naming (0-999)."
  type        = number
}

variable "instance_resource" {
  description = "Instance resource number for resource naming (0-100)."
  type        = number
}

variable "resource_names_map" {
  description = "Map of resource name keys used by the resource_name module (must include sns_topic and sqs_queue when this example creates those resources)."
  type = map(object({
    name       = string
    max_length = number
  }))
}

# Optional: use an existing topic and/or queue instead of creating them

variable "topic_arn" {
  description = "When null, this example creates an SNS topic. When set, that topic ARN is used."
  type        = string
  default     = null
}

variable "endpoint" {
  description = "When null, this example creates an encrypted SQS queue. When set, that subscription endpoint is used."
  type        = string
  default     = null
}

# Root module variables (pass-through)

variable "protocol" {
  description = "Protocol to use for the subscription."
  type        = string
}

variable "confirmation_timeout_in_minutes" {
  description = "Integer indicating the wait time for confirmation of an HTTP or HTTPS subscription. Only applicable when protocol is http or https."
  type        = number
  default     = null
}

variable "delivery_policy" {
  description = "JSON string for the subscription delivery policy (HTTP/S, SQS, etc.)."
  type        = string
  default     = null
}

variable "endpoint_auto_confirms" {
  description = "Whether the endpoint is capable of auto-confirming the subscription (e.g., some HTTPS endpoints)."
  type        = bool
  default     = null
}

variable "filter_policy" {
  description = "JSON string for the subscription filter policy."
  type        = string
  default     = null
}

variable "filter_policy_scope" {
  description = "Whether filter_policy applies to MessageAttributes or MessageBody."
  type        = string
  default     = null
}

variable "raw_message_delivery" {
  description = "Whether to enable raw message delivery (supported for SQS, HTTP/S, and Firehose subscriptions)."
  type        = bool
  default     = null
}

variable "redrive_policy" {
  description = "JSON string for the dead-letter queue redrive policy (SQS subscriptions)."
  type        = string
  default     = null
}

variable "replay_policy" {
  description = "JSON string for FIFO topic message replay policy."
  type        = string
  default     = null
}

variable "subscription_role_arn" {
  description = "IAM role ARN for Kinesis Firehose delivery to a subscription."
  type        = string
  default     = null
}
