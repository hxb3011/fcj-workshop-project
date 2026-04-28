import boto3
import os
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns = boto3.client('sns')
TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    try:
        appId = event.get('appId')
        appName = event.get('appName', 'Unknown App')
        subject = event.get('subject', f"Alert from {appName}")
        messageContent = event.get('message')
        
        if not appId or not messageContent:
            return {
                "statusCode": 400, 
                "body": json.dumps({"error": "Missing AppId or Message content"})
            }

        full_message = f"App Name: {appName}\nApp ID: {appId}\n\nContent: {messageContent}"

        response = sns.publish(
            TopicArn=TOPIC_ARN,
            Message=full_message,
            Subject=subject,
            MessageAttributes={
                'appId': {  
                    'DataType': 'String',
                    'StringValue': str(appId)
                }
            }
        )

        logger.info(f"Published message {response['MessageId']} for AppId: {appId}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": "Success",
                "message_id": response['MessageId']
            })
        }

    except Exception as e:
        logger.error(f"Error publishing: {str(e)}")
        return {
            "statusCode": 500, 
            "body": json.dumps({"error": "Internal Server Error"})
        }