package testimpl

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/kms"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	sqstypes "github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// awsRegionForDeployedInfra returns the region Terraform used for the example. Prefer the explicit
// aws_region output; if absent, derive it from the subscription ARN (arn:aws:sns:<region>:...) so tests never assume a default region.
func awsRegionForDeployedInfra(t *testing.T, ctx types.TestContext) string {
	t.Helper()
	opts := ctx.TerratestTerraformOptions()
	out, err := terraform.OutputE(t, opts, "aws_region")
	if err == nil && strings.TrimSpace(out) != "" {
		return strings.TrimSpace(out)
	}
	subArn := terraform.Output(t, opts, "subscription_arn")
	parts := strings.Split(subArn, ":")
	require.GreaterOrEqual(t, len(parts), 7, "subscription_arn must be a valid SNS subscription ARN to infer region: %s", subArn)
	return parts[3]
}

// assertSQSQueueUsesTerraformCMK checks that the queue's KmsMasterKeyId refers to the same customer
// managed key as terraformKeyID. SQS may return the key id, key ARN, or an alias ARN/name; KMS DescribeKey
// accepts all of those and returns canonical KeyId for comparison.
func assertSQSQueueUsesTerraformCMK(t *testing.T, kmsClient *kms.Client, terraformKeyID, sqsKmsMasterKeyID string) {
	t.Helper()
	ctx := context.Background()

	descTF, err := kmsClient.DescribeKey(ctx, &kms.DescribeKeyInput{
		KeyId: aws.String(terraformKeyID),
	})
	require.NoError(t, err)
	require.NotNil(t, descTF.KeyMetadata)
	wantKeyID := aws.ToString(descTF.KeyMetadata.KeyId)
	tfArn := aws.ToString(descTF.KeyMetadata.Arn)

	if sqsKmsMasterKeyID == wantKeyID || sqsKmsMasterKeyID == tfArn {
		return
	}

	descSQS, err := kmsClient.DescribeKey(ctx, &kms.DescribeKeyInput{
		KeyId: aws.String(sqsKmsMasterKeyID),
	})
	require.NoError(t, err)
	require.NotNil(t, descSQS.KeyMetadata)
	gotKeyID := aws.ToString(descSQS.KeyMetadata.KeyId)
	assert.Equal(t, wantKeyID, gotKeyID,
		"SQS encryption key must resolve to the Terraform CMK (DescribeKey by Terraform id vs by SQS attribute)")
}

// TestComposableComplete deploys the example, verifies subscription and encryption via the AWS API,
// publishes an SNS message, and asserts it is delivered to the subscribed SQS queue.
func TestComposableComplete(t *testing.T, ctx types.TestContext) {
	region := awsRegionForDeployedInfra(t, ctx)
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(region))
	require.NoError(t, err)
	snsClient := sns.NewFromConfig(cfg)
	sqsClient := sqs.NewFromConfig(cfg)
	kmsClient := kms.NewFromConfig(cfg)

	subArn := terraform.Output(t, ctx.TerratestTerraformOptions(), "subscription_arn")
	topicArn := terraform.Output(t, ctx.TerratestTerraformOptions(), "topic_arn")
	queueURL := terraform.Output(t, ctx.TerratestTerraformOptions(), "queue_url")
	queueArn := terraform.Output(t, ctx.TerratestTerraformOptions(), "queue_arn")
	kmsKeyID := terraform.Output(t, ctx.TerratestTerraformOptions(), "kms_key_id")
	expectedProtocol := terraform.Output(t, ctx.TerratestTerraformOptions(), "protocol")

	subOut, err := snsClient.GetSubscriptionAttributes(context.Background(), &sns.GetSubscriptionAttributesInput{
		SubscriptionArn: aws.String(subArn),
	})
	require.NoError(t, err)
	require.NotNil(t, subOut.Attributes)
	attrs := subOut.Attributes
	assert.Equal(t, expectedProtocol, attrs["Protocol"])
	assert.Equal(t, queueArn, attrs["Endpoint"])
	rawAttr, ok := attrs["RawMessageDelivery"]
	require.True(t, ok, "RawMessageDelivery must be present in subscription attributes")
	assert.Equal(t, "true", rawAttr, "Raw message delivery should match configuration")

	qOut, err := sqsClient.GetQueueAttributes(context.Background(), &sqs.GetQueueAttributesInput{
		QueueUrl:       aws.String(queueURL),
		AttributeNames: []sqstypes.QueueAttributeName{sqstypes.QueueAttributeNameAll},
	})
	require.NoError(t, err)
	require.NotNil(t, qOut.Attributes)
	kmsFromAPI, ok := qOut.Attributes[string(sqstypes.QueueAttributeNameKmsMasterKeyId)]
	require.True(t, ok, "KmsMasterKeyId must be present on the queue")
	assertSQSQueueUsesTerraformCMK(t, kmsClient, kmsKeyID, kmsFromAPI)

	msg := "terratest-sns-subscription-" + time.Now().UTC().Format(time.RFC3339Nano)
	_, err = snsClient.Publish(context.Background(), &sns.PublishInput{
		TopicArn: aws.String(topicArn),
		Message:  aws.String(msg),
	})
	require.NoError(t, err)

	deadline := time.Now().Add(60 * time.Second)
	var receivedBody string
	for time.Now().Before(deadline) {
		recvOut, err := sqsClient.ReceiveMessage(context.Background(), &sqs.ReceiveMessageInput{
			QueueUrl:            aws.String(queueURL),
			MaxNumberOfMessages: 1,
			WaitTimeSeconds:     20,
		})
		require.NoError(t, err)
		if len(recvOut.Messages) > 0 {
			receivedBody = aws.ToString(recvOut.Messages[0].Body)
			_, delErr := sqsClient.DeleteMessage(context.Background(), &sqs.DeleteMessageInput{
				QueueUrl:      aws.String(queueURL),
				ReceiptHandle: recvOut.Messages[0].ReceiptHandle,
			})
			require.NoError(t, delErr)
			break
		}
	}
	assert.Equal(t, msg, receivedBody, "Received SQS message body should match published message")
}

// TestComposableCompleteReadonly verifies subscription attributes and SQS encryption using read-only API calls only.
func TestComposableCompleteReadonly(t *testing.T, ctx types.TestContext) {
	region := awsRegionForDeployedInfra(t, ctx)
	cfg, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(region))
	require.NoError(t, err)
	snsClient := sns.NewFromConfig(cfg)
	sqsClient := sqs.NewFromConfig(cfg)
	kmsClient := kms.NewFromConfig(cfg)

	subArn := terraform.Output(t, ctx.TerratestTerraformOptions(), "subscription_arn")
	queueURL := terraform.Output(t, ctx.TerratestTerraformOptions(), "queue_url")
	queueArn := terraform.Output(t, ctx.TerratestTerraformOptions(), "queue_arn")
	kmsKeyID := terraform.Output(t, ctx.TerratestTerraformOptions(), "kms_key_id")
	expectedProtocol := terraform.Output(t, ctx.TerratestTerraformOptions(), "protocol")

	subOut, err := snsClient.GetSubscriptionAttributes(context.Background(), &sns.GetSubscriptionAttributesInput{
		SubscriptionArn: aws.String(subArn),
	})
	require.NoError(t, err)
	require.NotNil(t, subOut.Attributes)
	attrs := subOut.Attributes
	assert.Equal(t, expectedProtocol, attrs["Protocol"])
	assert.Equal(t, queueArn, attrs["Endpoint"])
	rawAttr, ok := attrs["RawMessageDelivery"]
	require.True(t, ok, "RawMessageDelivery must be present in subscription attributes")
	assert.Equal(t, "true", rawAttr)

	qOut, err := sqsClient.GetQueueAttributes(context.Background(), &sqs.GetQueueAttributesInput{
		QueueUrl:       aws.String(queueURL),
		AttributeNames: []sqstypes.QueueAttributeName{sqstypes.QueueAttributeNameAll},
	})
	require.NoError(t, err)
	require.NotNil(t, qOut.Attributes)
	kmsFromAPI, ok := qOut.Attributes[string(sqstypes.QueueAttributeNameKmsMasterKeyId)]
	require.True(t, ok, "KmsMasterKeyId must be present on the queue")
	assertSQSQueueUsesTerraformCMK(t, kmsClient, kmsKeyID, kmsFromAPI)
}
