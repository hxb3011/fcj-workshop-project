import gzip
import base64
import json
import random
import time

def generate_aws_logs_test_event(app_id, log_message, stream_suffix="server-prod-01"):
    log_stream_name = f"{app_id}___{stream_suffix}"
    
    data_payload = {
        "messageType": "DATA_MESSAGE",
        "owner": "123456789012",
        "logGroup": "/app/log-project",
        "logStream": log_stream_name,
        "subscriptionFilters": ["test-filter"],
        "logEvents": [
            {
                "id": str(random.randint(10**55, 10**56 - 1)),
                "timestamp": int(time.time() * 1000),
                "message": log_message
            }
        ]
    }

    json_bytes = json.dumps(data_payload).encode('utf-8')
    compressed_data = gzip.compress(json_bytes)
    base64_encoded = base64.b64encode(compressed_data).decode('utf-8')
    
    return base64_encoded

def get_random_info_log():
    messages = [
        "User logged in successfully",
        "Database connection established",
        "Request processed in 150ms",
        "Cache hit for key: user_session_123",
        "File uploaded to S3: profile_picture.jpg",
        "Background task 'CleanupTempFiles' started",
        "API health check passed"
    ]
    
    log_content = {
        "level": "INFO",
        "message": random.choice(messages),
        "request_id": f"req-{uuid_short()}"
    }
    return json.dumps(log_content)

def uuid_short():
    import uuid
    return uuid.uuid4().hex[:8]

if __name__ == "__main__":
   
    MY_APP_ID = "app_c4f82f13" 

    try:
     
        MY_LOG = get_random_info_log()
        
        result = generate_aws_logs_test_event(MY_APP_ID, MY_LOG)
        
        print(f"\n--- LOG GENERATED (LEVEL: INFO) ---")
        print(f"Content: {MY_LOG}")
        print("\n--- COPY BASE64 BELOW FOR LAMBDA TEST ---")
        print(result)
        print("--- END ---\n")
        
    except Exception as e:
        print(f"Error: {e}")