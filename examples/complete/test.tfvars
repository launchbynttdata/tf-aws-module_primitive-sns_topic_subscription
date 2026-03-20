logical_product_family  = "launch"
logical_product_service = "sns"
class_env               = "dev"
instance_env            = 1
instance_resource       = 1

resource_names_map = {
  sns_topic = {
    name       = "snstopic1"
    max_length = 80
  }
  sqs_queue = {
    name       = "sqsqueue1"
    max_length = 80
  }
}

topic_arn = null
endpoint  = null
protocol  = "sqs"

confirmation_timeout_in_minutes = null
delivery_policy                 = null
endpoint_auto_confirms          = null
filter_policy                   = null
filter_policy_scope             = null
raw_message_delivery            = true
redrive_policy                  = null
replay_policy                   = null
subscription_role_arn           = null
