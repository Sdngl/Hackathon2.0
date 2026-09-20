from .client import generate_json
from .common import file_part
from .prompts import MEDICINE_PROMPT
from .schemas import MEDICINE_SCHEMA


def _clean_text(value):
    if value is None:
        return None

    text = str(value).strip()

    if not text:
        return None

    if text.lower() in {
        "null",
        "none",
        "unknown",
        "not available",
        "n/a",
    }:
        return None

    return text


def _clean_list(value):
    if not isinstance(value, list):
        return []

    cleaned = []

    for item in value:
        if isinstance(item, str):
            text = _clean_text(item)

            if text is not None:
                cleaned.append(text)

        elif isinstance(item, dict):
            cleaned.append(item)

    return cleaned


def _normalize_medicine(data):
    medicine = data.get("medicine")

    if not isinstance(medicine, dict):
        medicine = {}

    data["medicine"] = {
        "name": _clean_text(medicine.get("name")),
        "generic_name": _clean_text(
            medicine.get("generic_name")
        ),
        "strength": _clean_text(
            medicine.get("strength")
        ),
        "form": _clean_text(
            medicine.get("form")
        ),
    }


def _normalize_instructions(data):
    instructions = data.get("instructions")

    if not isinstance(instructions, dict):
        instructions = {}

    explicit_times = instructions.get(
        "explicit_times"
    )

    if not isinstance(explicit_times, list):
        explicit_times = []

    cleaned_times = []

    for item in explicit_times:
        text = _clean_text(item)

        if text is not None:
            cleaned_times.append(text)

    data["instructions"] = {
        "dose": _clean_text(
            instructions.get("dose")
        ),
        "frequency": _clean_text(
            instructions.get("frequency")
        ),
        "duration": _clean_text(
            instructions.get("duration")
        ),
        "meal_relation": _clean_text(
            instructions.get("meal_relation")
        ),
        "explicit_times": cleaned_times,
    }


def _normalize_schedule(data):
    schedule = data.get("suggested_schedule")

    if not isinstance(schedule, list):
        data["suggested_schedule"] = []
        return

    cleaned_schedule = []

    for item in schedule:
        if not isinstance(item, dict):
            continue

        time = _clean_text(
            item.get("time")
        )

        label = _clean_text(
            item.get("label")
        )

        basis = _clean_text(
            item.get("basis")
        )

        if (
            time is None
            and label is None
            and basis is None
        ):
            continue

        cleaned_schedule.append(
            {
                "time": time,
                "label": label,
                "basis": basis,
            }
        )

    data["suggested_schedule"] = cleaned_schedule


def _normalize_uncertainty(data):
    uncertain_fields = data.get(
        "uncertain_fields"
    )

    if not isinstance(uncertain_fields, list):
        uncertain_fields = []

    cleaned = []

    for item in uncertain_fields:
        text = _clean_text(item)

        if text is not None:
            cleaned.append(text)

    data["uncertain_fields"] = cleaned


def _normalize_general_information(data):
    information = data.get(
        "general_information"
    )

    data["general_information"] = _clean_list(
        information
    )


def _calculate_confirmation(data):
    medicine = data["medicine"]
    instructions = data["instructions"]

    critical_missing = [
        medicine.get("name") is None,
        instructions.get("dose") is None,
        instructions.get("frequency") is None,
    ]

    has_uncertainty = bool(
        data.get("uncertain_fields")
    )

    return (
        any(critical_missing)
        or has_uncertainty
        or bool(
            data.get(
                "requires_user_confirmation",
                True,
            )
        )
    )


def analyze_medicine(upload):
    data = generate_json(
        [
            MEDICINE_PROMPT,
            file_part(upload),
        ],
        MEDICINE_SCHEMA,
    )

    if not isinstance(data, dict):
        raise ValueError(
            "Medicine analysis did not return a valid JSON object."
        )

    _normalize_medicine(data)
    _normalize_instructions(data)
    _normalize_schedule(data)
    _normalize_uncertainty(data)
    _normalize_general_information(data)

    data["type"] = "medicine"

    data["schedule_note"] = _clean_text(
        data.get("schedule_note")
    )

    data["doctor_name"] = _clean_text(
        data.get("doctor_name")
    )

    confidence = data.get("confidence")

    if isinstance(confidence, (int, float)):
        data["confidence"] = max(
            0.0,
            min(
                1.0,
                float(confidence),
            ),
        )
    else:
        data["confidence"] = None

    data["requires_user_confirmation"] = (
        _calculate_confirmation(data)
    )

    return data