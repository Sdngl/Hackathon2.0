from .client import generate_json
from .common import file_part
from .prompts import REPORT_PROMPT
from .schemas import REPORT_SCHEMA


def analyze_report(upload):
    data = generate_json(
        [
            REPORT_PROMPT,
            file_part(upload),
        ],
        REPORT_SCHEMA,
    )

    data["type"] = "report"

    return data