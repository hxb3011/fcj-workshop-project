import os
import time
import boto3
import requests
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException, Header
from pydantic import BaseModel
from boto3.dynamodb.conditions import Key
from jose import jwt

app = FastAPI(title="FCAJ GSVN Log System API")

# --- 1. CONFIGURATION ---
REGION = os.environ.get("AWS_REGION", "ap-southeast-1")
USER_POOL_ID = os.environ.get("USER_POOL_ID")
CLIENT_ID = os.environ.get("CLIENT_ID")
TABLE_LOGS = os.environ.get("TABLE_LOGS", "AppLogs")
ATHENA_DB = os.environ.get("GLUE_DATABASE_NAME")
ATHENA_WG = os.environ.get("ATHENA_WORKGROUP_NAME")
ATHENA_OUTPUT = os.environ.get("ATHENA_OUTPUT_S3")

# AWS Clients
cognito = boto3.client("cognito-idp", region_name=REGION)
dynamodb = boto3.resource("dynamodb", region_name=REGION)
athena = boto3.client("athena", region_name=REGION)
log_table = dynamodb.Table(TABLE_LOGS)

# Tải JWKS từ Cognito để verify Token (chỉ tải khi khởi động app)
JWKS_URL = f"https://cognito-idp.{REGION}.amazonaws.com/{USER_POOL_ID}/.well-known/jwks.json"
jwks = requests.get(JWKS_URL).json()

# --- 2. MODELS ---
class LoginRequest(BaseModel):
    username: str
    password: str

# --- 3. AUTH MIDDLEWARE ---
def verify_token(authorization: str = Header(...)):
    """Giải mã và xác thực Access Token từ Header"""
    try:
        token = authorization.split(" ")[1]
        header = jwt.get_unverified_header(token)
        key = [k for k in jwks["keys"] if k["kid"] == header["kid"]][0]
        
        payload = jwt.decode(
            token, key, algorithms=["RS256"],
            audience=None, # Access Token không có audience, Id Token mới có
            issuer=f"https://cognito-idp.{REGION}.amazonaws.com/{USER_POOL_ID}"
        )
        return payload
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Unauthorized: {str(e)}")

# --- 4. ENDPOINTS ---

@app.post("/auth/login")
async def login(req: LoginRequest):
    """
    Người dùng đăng nhập để lấy Access Token
    """
    try:
        response = cognito.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": req.username,
                "PASSWORD": req.password
            }
        )
        auth_result = response["AuthenticationResult"]
        return {
            "access_token": auth_result["AccessToken"],
            "id_token": auth_result["IdToken"],
            "refresh_token": auth_result["RefreshToken"],
            "expires_in": auth_result["ExpiresIn"]
        }
    except cognito.exceptions.NotAuthorizedException:
        raise HTTPException(status_code=401, detail="Sai tên đăng nhập hoặc mật khẩu")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/logs/hot/{app_id}")
async def get_hot_logs(app_id: str, user=Depends(verify_token)):
    """
    Lệnh 1: Truy vấn DynamoDB lấy log mới nhất (trong vòng 24h)
    """
    try:
        # Query sử dụng Partition Key là appId
        response = log_table.query(
            KeyConditionExpression=Key("appId").eq(app_id),
            ScanIndexForward=False, # Mới nhất lên đầu
            Limit=50
        )
        return {
            "source": "DynamoDB (Hot)",
            "user": user.get("username"),
            "data": response.get("Items", [])
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/logs/cold/{app_id}")
async def get_cold_logs(app_id: str, date: str, user=Depends(verify_token)):
    """
    Lệnh 2: Truy vấn Athena lấy log lịch sử theo ngày (YYYY-MM-DD)
    """
    try:
        year, month, day = date.split("-")
        
        # SQL query tối ưu theo Partition của Glue
        query = f"""
            SELECT * FROM "{ATHENA_DB}"."{TABLE_LOGS.lower()}"
            WHERE appId = '{app_id}' 
              AND year = '{year}' AND month = '{month}' AND day = '{day}'
            ORDER BY timestamp DESC
            LIMIT 100
        """

        # Thực thi Athena
        response = athena.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": ATHENA_DB},
            WorkGroup=ATHENA_WG,
            ResultConfiguration={"OutputLocation": ATHENA_OUTPUT}
        )
        query_id = response["QueryExecutionId"]

        # Polling kết quả
        while True:
            status = athena.get_query_execution(QueryExecutionId=query_id)
            state = status["QueryExecution"]["Status"]["State"]
            if state in ["SUCCEEDED", "FAILED", "CANCELLED"]:
                break
            time.sleep(1)

        if state != "SUCCEEDED":
            raise Exception(f"Athena query failed: {status['QueryExecution']['Status'].get('StateChangeReason')}")

        # Lấy dữ liệu và parse sang JSON
        results = athena.get_query_results(QueryExecutionId=query_id)
        columns = [col["Name"] for col in results["ResultSet"]["ResultSetMetadata"]["ColumnInfo"]]
        data = []
        for row in results["ResultSet"]["Rows"][1:]: # Bỏ qua dòng header
            data.append(dict(zip(columns, [v.get("VarCharValue") for v in row["Data"]])))

        return {
            "source": "Athena (Cold)",
            "appId": app_id,
            "date": date,
            "data": data
        }
    except ValueError:
        raise HTTPException(status_code=400, detail="Định dạng ngày phải là YYYY-MM-DD")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
@app.get("/health")
async def health():
    return {"status": "healthy"}
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)