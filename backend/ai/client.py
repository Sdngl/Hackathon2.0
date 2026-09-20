import json

from django.conf import settings
from google import genai
from google.genai import types


class AIServiceError(Exception):
    pass


class AIInvalidResponse(AIServiceError):
    pass


class AIRateLimited(AIServiceError):
    pass


_client = None


def get_client():
    global _client

    if _client is None:
        if not settings.GEMINI_API_KEY:
            raise AIServiceError(
                "Gemini API key is not configured."
            )

        _client = genai.Client(
            api_key=settings.GEMINI_API_KEY,
            http_options=types.HttpOptions(
                timeout=30_000
            ),
        )

    return _client


def generate_json(contents, schema):
    try:
        response = get_client().models.generate_content(
            model=settings.GEMINI_MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=schema,
                temperature=0.1,
            ),
        )

        parsed = getattr(response, "parsed", None)

        if isinstance(parsed, dict):
            return parsed

        text = getattr(response, "text", None)

        if not text:
            raise AIInvalidResponse(
                "Gemini returned an empty response."
            )

        data = json.loads(text)

        if not isinstance(data, dict):
            raise AIInvalidResponse(
                "Gemini did not return a JSON object."
            )

        return data

    except AIServiceError:
        raise

    except json.JSONDecodeError as exc:
        raise AIInvalidResponse(
            "Gemini returned invalid JSON."
        ) from exc

    except Exception as exc:
        message = str(exc).lower()

        if (
            "429" in message
            or "quota" in message
            or "rate limit" in message
        ):
            raise AIRateLimited(
                "Gemini quota or rate limit reached."
            ) from exc

        # Keep the real exception chained so DEBUG traceback
        # tells us exactly what Gemini rejected.
        raise AIServiceError(
            f"Gemini request failed: {exc}"
        ) from exc