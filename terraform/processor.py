import boto3
import time
import json
import os
from datetime import datetime, timezone
from botocore.exceptions import ClientError

# Khởi tạo Resource
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
sns = boto3.client('sns')


TABLE_LOGS = os.environ.get('TABLE_LOGS', 'AppLogs')
TABLE_NOTI = os.environ.get('TABLE_NOTI', 'NotiTTL')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'fcaj-log-archive')
TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

RETENTION_SECONDS = int(os.environ.get('RETENTION_DAYS', '2')) * 86400

table_logs = dynamodb.Table(TABLE_LOGS)
table_noti = dynamodb.Table(TABLE_NOTI)

def lambda_handler(event, context):
    logs_by_app = {}
    items_for_dynamo = []
    
    # Lấy thời gian hiện tại để tính TTL đồng nhất cho cả đợt (batch)
    now_ts = int(time.time())
    expire_at = now_ts + RETENTION_SECONDS

    for record in event['Records']:
        try:
            body = json.loads(record['body'])
            app_id = body.get('appId', 'unknown')
            level = body.get('level', 'INFO').upper()
            
            # Timestamp gốc từ log (ms)
            ts_original = body.get('timestamp') or int(time.time() * 1000)
            
            # Tạo Item chuẩn để ghi DynamoDB
            item = {
                'appId': app_id,
                'timestamp': ts_original,
                'level': level,
                'message': body.get('message', ''),
                'expireAt': expire_at  # Tự động xóa sau 2 ngày tính từ lúc xử lý
            }
            
            items_for_dynamo.append(item)

            # Phân loại theo appId để ghi batch vào S3 (Giữ nguyên logic của bạn)
            if app_id not in logs_by_app:
                logs_by_app[app_id] = []
            logs_by_app[app_id].append(item)
            
            # Kiểm tra Alert nếu là ERROR
            if level == 'ERROR':
                dt_obj = datetime.fromtimestamp(ts_original // 1000, tz=timezone.utc)
                handle_alert(app_id, item['message'], dt_obj)
                
        except Exception as e:
            print(f"Error parsing record: {e}")

    # 1. Ghi vào S3 theo từng cụm appId (Hive Partitioning)
    dt_now = datetime.fromtimestamp(now_ts, tz=timezone.utc)
    for app_id, logs in logs_by_app.items():
        s3_key = f"year={dt_now.year}/month={dt_now.month:02d}/day={dt_now.day:02d}/appId={app_id}/batch_{now_ts}.json"
        try:
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=json.dumps(logs),
                ContentType='application/json'
            )
        except Exception as e:
            print(f"S3 Upload Error for {app_id}: {e}")

    # 2. Ghi vào DynamoDB sử dụng Batch Writer (Tối ưu performance)
    if items_for_dynamo:
        try:
            with table_logs.batch_writer() as batch:
                for item in items_for_dynamo:
                    batch.put_item(Item=item)
        except Exception as e:
            print(f"DynamoDB Batch Write Error: {e}")

    return {'processed': len(items_for_dynamo)}

def handle_alert(app_id, msg, dt):
    """Gửi SNS kèm cơ chế chống spam (Debounce 15p)"""
    try:
        # Check TTL record trong bảng NotiTTL
        table_noti.put_item(
            Item={'appId': app_id, 'expireAt': int(time.time()) + 900},
            ConditionExpression='attribute_not_exists(appId)'
        )
        
        # Nếu pass condition (chưa có appId hoặc đã hết hạn 15p) thì gửi SNS
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
        # Nếu lỗi là do bản ghi đã tồn tại (spam), ta bỏ qua
        if e.response['Error']['Code'] != 'ConditionalCheckFailedException':
            print(f"SNS Error: {e}")