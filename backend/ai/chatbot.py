import json
from .client import generate_json
from .prompts import CHAT_PROMPT
from .schemas import CHAT_SCHEMA
def chat(message,history,context):
    payload=json.dumps({'message':message,'history':history,'context':context},ensure_ascii=False)
    return generate_json([CHAT_PROMPT,payload],CHAT_SCHEMA)
