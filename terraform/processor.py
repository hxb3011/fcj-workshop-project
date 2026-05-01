import boto3
import time
import json
import os
from datetime import datetime
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
sns = boto3.client('sns') 

table_logs = dynamodb.Table('AppLogs')
table_noti = dynamodb.Table('NotiTTL')
table_clients = dynamodb.Table('AppClients') 

BUCKET_NAME = 'fcaj-log-archive'
TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN') 

def lambda_handler(event, context):
    for record in event['Records']:
        try:
            body = json.loads(record['body'])
            
            appId = body.get('appId', body.get('AppID', 'Unknown'))
            level = str(body.get('level', 'INFO')).upper()
            message = body.get('message', '')
            
            ts = int(time.time())
            now = datetime.utcfromtimestamp(ts)
            
            s3_key = f"year={now.strftime('%Y')}/month={now.strftime('%m')}/day={now.strftime('%d')}/appId={appId}/log_{ts}.json"
            log_item = {
                'appId': appId,
                'timestamp': ts,
                'level': level,
                'message': message,
                'expireAt': ts + 86400
            }
            table_logs.put_item(Item=log_item)
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=json.dumps(log_item),
                ContentType='application/json'
            )
            
            if level == 'ERROR':
                try:
                    table_noti.put_item(
                        Item={
                            'appId': appId,
                            'expireAt': ts + 900
                        },
                        ConditionExpression='attribute_not_exists(appId)'
                    )
                    
                    sns.publish(
                        TopicArn=TOPIC_ARN,
                        Subject=f"[ALERT] {appId} System Error",
                        Message=f"Ứng dụng: {appId}\nThời gian: {now}\nNội dung lỗi: {message}\n\nHệ thống tạm ngưng gửi mail trong 15 phút.",
                        MessageAttributes={
                            'appId': {
                                'DataType': 'String',
                                'StringValue': str(appId)
                            }
                        }
                    )
                    print(f"[{appId}] SNS Alert published to Topic.")
                    
                except ClientError as e:
                    if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                        print(f"[{appId}] Silenced (Debounced by NotiTTL table).")
                    else:
                        raise e
                        
        except Exception as e:
            print(f"Error processing record: {str(e)}")

    return {'statusCode': 200}