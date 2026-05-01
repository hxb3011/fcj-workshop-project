import boto3
import os
import json
from datetime import datetime

# Khởi tạo các AWS Clients
dynamodb = boto3.resource('dynamodb')
athena = boto3.client('athena')

# Biến môi trường
TABLE_LOGS = os.environ.get('TABLE_LOGS', 'AppLogs')
DATABASE = os.environ.get('GLUE_DATABASE', 'app_logs_database')
WORKGROUP = os.environ.get('ATHENA_WORKGROUP', 'log_project_workgroup')

def lambda_handler(event, context):
    app_id = event.get('appId')
    mode = event.get('mode', 'hot') 

    if not app_id:
        return {'statusCode': 400, 'body': 'Missing appId'}

    # Lấy thời gian hiện tại để làm mặc định
    now = datetime.now()
    current_year = str(now.year)
    current_month = f"{now.month:02d}"
    current_day = f"{now.day:02d}"

    if mode == 'hot':
        # TRUY VẤN LOG NÓNG TỪ DYNAMODB
        table = dynamodb.Table(TABLE_LOGS)
        response = table.query(
            KeyConditionExpression="appId = :id",
            ExpressionAttributeValues={":id": app_id},
            Limit=50,
            ScanIndexForward=False 
        )
        return {
            'status': 'success', 
            'source': 'DynamoDB (Hot)', 
            'date_queried': f"{current_year}-{current_month}-{current_day}",
            'data': response.get('Items', [])
        }

    else:
        # TRUY VẤN LOG CŨ VỚI ATHENA + GLUE
        # Lấy tham số ngày từ event, nếu không có thì dùng ngày hiện tại
        year = event.get('year', current_year)
        month = event.get('month', current_month)
        day = event.get('day', current_day)

        query = f"""
            SELECT * FROM app_logs 
            WHERE appid = '{app_id}' 
            AND year = '{year}' 
            AND month = '{month}' 
            AND day = '{day}'
            ORDER BY timestamp DESC 
            LIMIT 100
        """
        
        try:
            response = athena.start_query_execution(
                QueryString=query,
                QueryExecutionContext={'Database': DATABASE},
                WorkGroup=WORKGROUP
            )
            
            return {
                'status': 'success', 
                'source': 'Athena (Old)', 
                'partition_targeted': f"year={year}/month={month}/day={day}",
                'query_execution_id': response['QueryExecutionId']
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': str(e)
            }