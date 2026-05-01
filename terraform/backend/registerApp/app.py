import os
import uuid
import json
import boto3
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, EmailStr
from botocore.exceptions import ClientError

app = FastAPI(title="LogSystem Registration API")


cognito = boto3.client('cognito-idp')
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')


USER_POOL_ID = os.environ.get('USER_POOL_ID')
TABLE_NAME = os.environ.get('APP_CLIENTS_TABLE', 'AppClients')
TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

table = dynamodb.Table(TABLE_NAME)

class RegisterRequest(BaseModel):
    appName: str
    email: EmailStr
    password: str

@app.post("/register", status_code=status.HTTP_201_CREATED)
async def register_new_app(request: RegisterRequest):
    app_id = f"app_{uuid.uuid4().hex[:8]}"
    
    try:
        cognito.admin_create_user(
            UserPoolId=USER_POOL_ID,
            Username=app_id,
            UserAttributes=[
                {'Name': 'email', 'Value': request.email},
                {'Name': 'email_verified', 'Value': 'true'}
            ],
            MessageAction='SUPPRESS'
        )

        cognito.admin_set_user_password(
            UserPoolId=USER_POOL_ID,
            Username=app_id,
            Password=request.password,
            Permanent=True
        )

        table.put_item(
            Item={
                'appId': app_id,
                'appName': request.appName,
                'email': request.email,
                'createdAt': int(uuid.time.time()),
                'status': 'ACTIVE'
            }
        )

        sns.subscribe(
            TopicArn=TOPIC_ARN,
            Protocol='email',
            Endpoint=request.email,
            Attributes={
                'FilterPolicy': json.dumps({"appId": [app_id]})
            }
        )

        return {
            "status": "success",
            "data": {
                "appId": app_id,
                "appName": request.appName,
                "email": request.email,
                "note": "Kiểm tra email để 'Confirm Subscription' từ AWS SNS."
            }
        }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'UsernameExistsException':
            raise HTTPException(status_code=400, detail="App ID đã tồn tại.")
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi hệ thống: {str(e)}")

@app.get("/health")
async def health():
    return {"status": "healthy"}