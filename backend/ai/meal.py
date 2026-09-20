from .client import generate_json
from .common import file_part
from .prompts import MEAL_PROMPT
from .schemas import MEAL_SCHEMA


def analyze_meal(upload):
    data = generate_json(
        [
            MEAL_PROMPT,
            file_part(upload),
        ],
        MEAL_SCHEMA,
    )

    data["type"] = "meal"
    data["is_estimate"] = True

    return data