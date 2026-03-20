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

# Required

variable "topic_arn" {
  description = "ARN of the SNS topic to subscribe to."
  type        = string
}

variable "protocol" {
  description = "Protocol to use. Valid values include application, firehose, http, https, lambda, sms, sqs, email, email-json."
  type        = string
}

variable "endpoint" {
  description = "Endpoint to send data to. The contents vary by protocol (e.g., SQS queue ARN, HTTPS URL, Lambda function ARN)."
  type        = string
}

# Optional

variable "confirmation_timeout_in_minutes" {
  description = "Integer indicating the wait time for confirmation of an HTTP or HTTPS subscription. Only applicable when protocol is http or https."
  type        = number
  default     = null

  validation {
    condition     = var.confirmation_timeout_in_minutes == null ? true : (var.confirmation_timeout_in_minutes >= 1 && var.confirmation_timeout_in_minutes <= 60)
    error_message = "When set, confirmation_timeout_in_minutes must be between 1 and 60."
  }
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

  validation {
    condition     = var.filter_policy_scope == null ? true : contains(["MessageAttributes", "MessageBody"], var.filter_policy_scope)
    error_message = "filter_policy_scope must be MessageAttributes or MessageBody."
  }
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
