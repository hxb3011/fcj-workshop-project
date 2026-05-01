import boto3
import os
import json
from datetime import datetime

# Khởi tạo các AWS Clients
dynamodb = boto3.resource('dynamodb')
athena = boto3.client('athena')

# Biến môi trường được cấu hình từ Terraform
TABLE_LOGS = os.environ.get('TABLE_LOGS', 'AppLogs')
DATABASE = os.environ.get('GLUE_DATABASE', 'app_logs_database')
WORKGROUP = os.environ.get('ATHENA_WORKGROUP', 'log_project_workgroup')

def lambda_handler(event, context):
    # Lấy tham số từ request (ví dụ qua API Gateway)
    app_id = event.get('appId')
    mode = event.get('mode', 'hot') # 'hot' cho DynamoDB, 'old' cho Athena

    if not app_id:
        return {'statusCode': 400, 'body': 'Missing appId'}

    if mode == 'hot':
        # TRUY VẤN LOG NÓNG TỪ DYNAMODB
        table = dynamodb.Table(TABLE_LOGS)
        response = table.query(
            KeyConditionExpression="appId = :id",
            ExpressionAttributeValues={":id": app_id},
            Limit=20,
            ScanIndexForward=False # Lấy log mới nhất trước
        )
        return {'status': 'success', 'source': 'DynamoDB (Hot)', 'data': response.get('Items', [])}

    else:
        # TRUY VẤN LOG CŨ TỪ ATHENA + GLUE
        # Athena sử dụng Partition Projection đã định nghĩa trong glue.tf
        query = f"SELECT * FROM app_logs WHERE appId = '{app_id}' ORDER BY timestamp DESC LIMIT 100"
        
        response = athena.start_query_execution(
            QueryString=query,
            QueryExecutionContext={'Database': DATABASE},
            WorkGroup=WORKGROUP
        )
        
        return {
            'status': 'success', 
            'source': 'Athena (Old)', 
            'query_execution_id': response['QueryExecutionId'],
            'note': 'Use execution_id to get results once finished'
        }