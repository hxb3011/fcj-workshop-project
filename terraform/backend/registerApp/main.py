import os
import uuid
import json
import boto3
import time # Thêm import time bị thiếu
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, EmailStr
from botocore.exceptions import ClientError

app = FastAPI(title="LogSystem Registration API")

# Khởi tạo client với region lấy từ môi trường hoặc mặc định
region = os.environ.get('AWS_REGION', 'ap-southeast-1')
cognito = boto3.client('cognito-idp', region_name=region)
dynamodb = boto3.resource('dynamodb', region_name=region)
sns = boto3.client('sns', region_name=region)
iam = boto3.client('iam')

# Biến môi trường được truyền từ Terraform
USER_POOL_ID = os.environ.get('USER_POOL_ID')
TABLE_NAME = os.environ.get('APP_CLIENTS_TABLE')
TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
LOG_POLICY_ARN = os.environ.get('LOG_POLICY_ARN')

table = dynamodb.Table(TABLE_NAME)

class RegisterRequest(BaseModel):
    appName: str
    email: EmailStr
    password: str

@app.post("/register", status_code=status.HTTP_201_CREATED)
async def register_new_app(request: RegisterRequest):
    # Tạo ID duy nhất với tiền tố app_ như đã phân quyền trong IAM module
    app_id = f"app_{uuid.uuid4().hex[:8]}"
    
    try:
        # 1. Tạo User trên Cognito để quản lý login vào Dashboard
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

        # 2. Tạo IAM User cho Client để đẩy log từ server của họ
        iam.create_user(UserName=app_id)
        
        # Attach policy có sẵn từ module monitoring để client có quyền ghi log
        iam.attach_user_policy(
            UserName=app_id,
            PolicyArn=LOG_POLICY_ARN
        )
        
        # Tạo Access Key/Secret Key
        iam_response = iam.create_access_key(UserName=app_id)
        access_key = iam_response['AccessKey']['AccessKeyId']
        secret_key = iam_response['AccessKey']['SecretAccessKey']

        # 3. Lưu thông tin vào DynamoDB
        table.put_item(
            Item={
                'appId': app_id,
                'appName': request.appName,
                'email': request.email,
                'accessKeyId': access_key, 
                'createdAt': int(time.time()),
                'status': 'ACTIVE'
            }
        )

        # 4. Subscribe SNS để nhận thông báo qua email khi có log lỗi
        sns.subscribe(
            TopicArn=TOPIC_ARN,
            Protocol='email',
            Endpoint=request.email,
            Attributes={'FilterPolicy': json.dumps({"appId": [app_id]})}
        )

        return {
            "status": "success",
            "data": {
                "appId": app_id,
                "credentials": {
                    "access_key": access_key,
                    "secret_key": secret_key,
                    "region": region
                },
                "note": "LƯU LẠI Secret Key ngay bây giờ. Nó sẽ không hiển thị lại lần sau."
            }
        }

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'UsernameExistsException':
            raise HTTPException(status_code=400, detail="App ID đã tồn tại.")
        raise HTTPException(status_code=500, detail=f"AWS Error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi hệ thống: {str(e)}")

@app.get("/health")
async def health():
    return {"status": "healthy"}