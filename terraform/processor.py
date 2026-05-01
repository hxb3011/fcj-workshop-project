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
    """Main handler: Chạy song song I/O và Batch write DB"""
    # Xử lý song song S3/SNS (max 10 threads)
    with ThreadPoolExecutor(max_workers=10) as exe:
        results = list(exe.map(process_record, event['Records']))
    
    items = [i for i in results if i]

    # 3. Ghi DynamoDB theo Batch (25 items/lượt)
    if items:
        with table_logs.batch_writer() as batch:
            for i in items:
                batch.put_item(Item=i)

    return {'processed': len(items)}

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
