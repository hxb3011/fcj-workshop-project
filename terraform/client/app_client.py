import logging
import json
import os
from fastapi import FastAPI, Query
from logging.handlers import RotatingFileHandler
from dotenv import load_dotenv

load_dotenv()
APP_ID = os.getenv("APP_ID", "default_app")
LOG_PATH = os.getenv("LOG_PATH", "logs/app.log")

app = FastAPI(title=f"Log Generator for {APP_ID}")


os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)


class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "level": record.levelname,
            "message": record.getMessage(),
            "timestamp": int(record.created * 1000)
        }
        return json.dumps(log_record)


logger = logging.getLogger(APP_ID)
logger.setLevel(logging.INFO)

file_handler = RotatingFileHandler(LOG_PATH, maxBytes=5*1024*1024, backupCount=5)
file_handler.setFormatter(JsonFormatter())
logger.addHandler(file_handler)

@app.post("/generate-log/{level}")
async def generate_logs(level: str, count: int = Query(1, ge=1, le=100)):
    level = level.upper()
    results = []
    
    log_func = {
        "INFO": logger.info,
        "WARN": logger.warning,
        "ERROR": logger.error
    }

    if level not in log_func:
        return {"error": "Invalid level. Use INFO, ERROR, or WARN."}

    for i in range(count):
        msg = f"Log message #{i+1} from {APP_ID}"
        log_func[level](msg)
        results.append(msg)

    return {
        "status": "success", 
        "appId": APP_ID, 
        "level": level, 
        "count": count
    }

@app.get("/health")
async def health():
    return {"status": "online", "appId": APP_ID}