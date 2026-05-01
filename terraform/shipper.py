import base64
import json
import gzip
import os
import boto3


sqs = boto3.client('sqs')
SQS_URL = os.environ.get('SQS_URL')

def lambda_handler(event, context):

    cw_data = event['awslogs']['data']
    compressed_payload = base64.b64decode(cw_data)
    uncompressed_payload = gzip.decompress(compressed_payload)
    log_data = json.loads(uncompressed_payload)

    log_stream = log_data.get('logStream', '')
    app_id = None

    if "___" in log_stream:
        app_id = log_stream.split("___")[0]
    elif "-i-" in log_stream:
        app_id = log_stream.split("-i-")[0]
    
    if not app_id:
        print(f"Bỏ qua Log Stream không hợp lệ: {log_stream}")
        return {'status': 'ignored', 'reason': 'No valid delimiter found'}

    log_events = log_data.get('logEvents', [])
    batch_entries = []
    total_sent = 0


    for i, log_event in enumerate(log_events):
        raw_message = log_event.get('message', '')
        

        try:
            parsed = json.loads(raw_message)
            level = parsed.get('level', 'INFO').upper()
            message_content = parsed.get('message', raw_message)
        except:
            message_content = raw_message
            msg_upper = raw_message.upper()
            if "ERROR" in msg_upper: level = "ERROR"
            elif "WARN" in msg_upper: level = "WARN"
            else: level = "INFO"

   
        sqs_payload = {
            'appId': app_id,
            'level': level,
            'message': message_content,
            'timestamp': log_event.get('timestamp')
        }

  
        batch_entries.append({
            'Id': str(i), 
            'MessageBody': json.dumps(sqs_payload)
        })


        if len(batch_entries) == 10:
            sqs.send_message_batch(QueueUrl=SQS_URL, Entries=batch_entries)
            total_sent += len(batch_entries)
            batch_entries = [] 


    if batch_entries:
        sqs.send_message_batch(QueueUrl=SQS_URL, Entries=batch_entries)
        total_sent += len(batch_entries)

    print(f"Successfully shipped {total_sent} logs to SQS.")
    return {'status': 'sent', 'count': total_sent}