import boto3
import time
import json
import os
from datetime import datetime, timezone
from botocore.exceptions import ClientError
from concurrent.futures import ThreadPoolExecutor

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
sns = boto3.client('sns')

TABLE_LOGS = os.environ.get('TABLE_LOGS', 'AppLogs')
TABLE_NOTI = os.environ.get('TABLE_NOTI', 'NotiTTL')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'fcaj-log-archive')
TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

table_logs = dynamodb.Table(TABLE_LOGS)
table_noti = dynamodb.Table(TABLE_NOTI)

def process_record(record):
    """Xử lý đơn lẻ: Ghi S3 và Alert"""
    try:
        body = json.loads(record['body'])
        app_id = body.get('appId')
        level = body.get('level', 'INFO').upper()
        ts = body.get('timestamp') or int(time.time() * 1000)
        ts_s = ts // 1000
        
        item = {
            'appId': app_id,
            'timestamp': ts,
            'level': level,
            'message': body.get('message', ''),
            'expireAt': ts_s + 86400 # TTL 24h
        }

        # 1. Ghi S3 (Cold Storage - Hive Partition)
        dt = datetime.fromtimestamp(ts_s, tz=timezone.utc)
        key = f"year={dt.year}/month={dt.month:02d}/day={dt.day:02d}/appId={app_id}/log_{ts}.json"
        
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=key,
            Body=json.dumps(item),
            ContentType='application/json'
        )

        # 2. Check Alert nếu là ERROR
        if level == 'ERROR':
            handle_alert(app_id, item['message'], dt)

        return item
    except Exception as e:
        print(f"Error: {e}")
        return None

def lambda_handler(event, context):
    logs_by_app = {}
    items_for_dynamo = []

    for record in event['Records']:
        body = json.loads(record['body'])
        app_id = body.get('appId', 'unknown')
        
        ts = body.get('timestamp') or int(time.time() * 1000)
        item = {
            'appId': app_id,
            'timestamp': ts,
            'level': body.get('level', 'INFO').upper(),
            'message': body.get('message', ''),
            'expireAt': (ts // 1000) + 86400
        }
        items_for_dynamo.append(item)

        if app_id not in logs_by_app:
            logs_by_app[app_id] = []
        logs_by_app[app_id].append(item)

    dt = datetime.now(timezone.utc)
    for app_id, logs in logs_by_app.items():
        key = f"year={dt.year}/month={dt.month:02d}/day={dt.day:02d}/appId={app_id}/batch_{int(time.time())}.json"
        
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=key,
            Body=json.dumps(logs),
            ContentType='application/json'
        )

    if items_for_dynamo:
        with table_logs.batch_writer() as batch:
            for i in items_for_dynamo:
                batch.put_item(Item=i)
                
    return {'processed': len(items_for_dynamo)}

def handle_alert(app_id, msg, dt):
    """Gửi SNS kèm cơ chế chống spam (Debounce 15p)"""
    try:
        # Check TTL record để khống chế tần suất
        table_noti.put_item(
            Item={'appId': app_id, 'expireAt': int(time.time()) + 900},
            ConditionExpression='attribute_not_exists(appId)'
        )
        
        # Publish tới SNS
        sns.publish(
                TopicArn=TOPIC_ARN,
                Subject=f"[ALERT] {app_id}",
                Message=f"Time: {dt}\nMsg: {msg}",
                MessageAttributes={
                    'appId': {  
                        'DataType': 'String',
                        'StringValue': str(app_id)
                    }
                }
            )
    except ClientError as e:
        if e.response['Error']['Code'] != 'ConditionalCheckFailedException':
            print(f"SNS Error: {e}")
