from datetime import datetime, timezone

from firebase_admin import firestore

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from drf_spectacular.utils import extend_schema

from .serializers import ChatSerializer

from ai.chatbot import chat
from ai.client import (
    AIServiceError,
    AIInvalidResponse,
    AIRateLimited,
)


# ---------------------------------------------------------
# Doctor recommendation intent
# ---------------------------------------------------------

def _is_doctor_recommendation_request(message: str) -> bool:
    """
    Detect when the user is explicitly asking SEVA
    to recommend/suggest a doctor or specialist.
    """

    text = message.lower().strip()

    phrases = [
        "suggest me a doctor",
        "recommend me a doctor",
        "recommend a doctor",
        "suggest a doctor",
        "which doctor should i see",
        "which doctor should i consult",
        "what doctor should i see",
        "what doctor should i consult",
        "what type of doctor",
        "which specialist should i see",
        "which specialist should i consult",
        "suggest me a specialist",
        "recommend me a specialist",
        "doctor recommendation",
        "recommend doctor",
        "suggest doctor",
    ]

    if any(phrase in text for phrase in phrases):
        return True

    # Slightly broader fallback.
    has_doctor_word = (
        "doctor" in text
        or "specialist" in text
    )

    has_recommendation_word = any(
        word in text
        for word in [
            "recommend",
            "suggest",
            "which",
            "what type",
        ]
    )

    return (
        has_doctor_word
        and has_recommendation_word
    )


# ---------------------------------------------------------
# Subscription helpers
# ---------------------------------------------------------

def _to_datetime(value):
    if value is None:
        return None

    if isinstance(value, datetime):
        if value.tzinfo is None:
            return value.replace(
                tzinfo=timezone.utc,
            )

        return value

    if isinstance(value, str):
        try:
            parsed = datetime.fromisoformat(
                value.replace(
                    "Z",
                    "+00:00",
                )
            )

            if parsed.tzinfo is None:
                parsed = parsed.replace(
                    tzinfo=timezone.utc,
                )

            return parsed

        except ValueError:
            return None

    return None


def _has_active_premium(
    user_data: dict,
) -> bool:
    """
    Uses the same subscription structure as your Flutter app:

    isPaid == true
    AND
    subscriptionExpiresAt is still in the future.
    """

    if user_data.get("isPaid") is not True:
        return False

    expires_at = _to_datetime(
        user_data.get(
            "subscriptionExpiresAt"
        )
    )

    if expires_at is None:
        return False

    return expires_at > datetime.now(
        timezone.utc
    )


# ---------------------------------------------------------
# Firestore health context
# ---------------------------------------------------------

def _make_json_safe(value):
    """
    Remove data we should not send to the AI,
    especially Base64 images.
    """

    if isinstance(value, datetime):
        return value.isoformat()

    if isinstance(value, firestore.DocumentReference):
        return value.path

    if isinstance(value, dict):
        cleaned = {}

        ignored_keys = {
            "imagebase64",
            "base64",
            "imagedata",
            "image_data",
            "imageurl",
            "image_url",
        }

        for key, item in value.items():
            normalized_key = (
                str(key)
                .replace("_", "")
                .lower()
            )

            if normalized_key in ignored_keys:
                continue

            cleaned[str(key)] = (
                _make_json_safe(item)
            )

        return cleaned

    if isinstance(value, list):
        return [
            _make_json_safe(item)
            for item in value
        ]

    # Firestore timestamp values normally behave
    # like datetime, but this safely handles objects
    # providing isoformat().
    if hasattr(value, "isoformat"):
        try:
            return value.isoformat()
        except Exception:
            pass

    return value


def _load_collection(
    db,
    uid: str,
    collection_name: str,
    limit: int = 5,
):
    """
    Load a small number of recent saved health records.
    """

    reference = (
        db.collection("users")
        .document(uid)
        .collection(collection_name)
    )

    try:
        documents = (
            reference
            .order_by(
                "createdAt",
                direction=firestore.Query.DESCENDING,
            )
            .limit(limit)
            .stream()
        )

        return [
            {
                "id": document.id,
                **_make_json_safe(
                    document.to_dict() or {}
                ),
            }
            for document in documents
        ]

    except Exception:
        # Fallback for older documents that may not
        # contain createdAt.
        documents = (
            reference
            .limit(limit)
            .stream()
        )

        return [
            {
                "id": document.id,
                **_make_json_safe(
                    document.to_dict() or {}
                ),
            }
            for document in documents
        ]


def _build_doctor_context(
    db,
    uid: str,
):
    """
    Personalized context used only for Premium
    doctor recommendations.
    """

    reports = _load_collection(
        db=db,
        uid=uid,
        collection_name="reports",
        limit=5,
    )

    medicines = _load_collection(
        db=db,
        uid=uid,
        collection_name="medicines",
        limit=5,
    )

    return {
        "doctor_recommendation_request": True,
        "reports": reports,
        "medicines": medicines,
    }


# ---------------------------------------------------------
# Doctor matching
# ---------------------------------------------------------

def _normalize_speciality(value: str) -> str:
    return (
        value
        .strip()
        .lower()
        .replace("-", " ")
        .replace("_", " ")
    )


def _doctor_specializations(
    doctor_data: dict,
):
    value = doctor_data.get(
        "specialization"
    )

    if isinstance(value, list):
        return [
            str(item).strip()
            for item in value
            if str(item).strip()
        ]

    if isinstance(value, str):
        return [
            item.strip()
            for item in value.split("·")
            if item.strip()
        ]

    return []


def _doctor_matches_speciality(
    doctor_data: dict,
    speciality: str,
) -> bool:
    wanted = _normalize_speciality(
        speciality
    )

    specializations = (
        _doctor_specializations(
            doctor_data
        )
    )

    for specialization in specializations:
        candidate = _normalize_speciality(
            specialization
        )

        if candidate == wanted:
            return True

        if (
            wanted in candidate
            or candidate in wanted
        ):
            return True

    return False


def _doctor_response(
    doctor_id: str,
    data: dict,
):
    """
    Only return fields Flutter needs for
    the recommendation card / doctor page.
    """

    return {
        "id": doctor_id,
        "name": data.get("name")
        or "Doctor",

        "specialization":
            data.get("specialization")
            or [],

        "specialties":
            data.get("specialties")
            or [],

        "hospital":
            data.get("hospital")
            or "",

        "clinicName":
            data.get("clinicName"),

        "clinicAddress":
            data.get("clinicAddress"),

        "clinicHours":
            data.get("clinicHours"),

        "qualification":
            data.get("qualification"),

        "about":
            data.get("about"),

        "imageUrl":
            data.get("imageUrl")
            or "",

        "consultationFee":
            data.get(
                "consultationFee"
            ),

        "rating":
            data.get("rating"),

        "reviewCount":
            data.get(
                "reviewCount"
            ),

        "experienceYears":
            data.get(
                "experienceYears"
            ),

        "patientCount":
            data.get(
                "patientCount"
            ),

        "phone":
            data.get("phone"),

        "email":
            data.get("email"),

        "available":
            data.get(
                "available",
                False,
            ),

        "isActive":
            data.get(
                "isActive",
                True,
            ),

        "availableSlots":
            data.get(
                "availableSlots"
            )
            or [],

        "languages":
            data.get(
                "languages"
            )
            or [],

        "verified":
            data.get(
                "verified",
                False,
            ),
    }


def _find_doctor(
    db,
    speciality: str,
):
    """
    Match Gemini's specialty against REAL
    Firestore doctors.

    For the hackathon-sized doctor collection,
    filtering in Python avoids needing extra
    Firestore composite indexes.
    """

    matches = []

    for document in (
        db.collection("doctors")
        .stream()
    ):
        data = document.to_dict() or {}

        if data.get(
            "isActive",
            True,
        ) is not True:
            continue

        if data.get(
            "available",
            False,
        ) is not True:
            continue

        if not _doctor_matches_speciality(
            doctor_data=data,
            speciality=speciality,
        ):
            continue

        rating = data.get(
            "rating"
        )

        try:
            rating_value = float(
                rating or 0
            )
        except (
            TypeError,
            ValueError,
        ):
            rating_value = 0

        matches.append(
            (
                rating_value,
                document.id,
                data,
            )
        )

    if not matches:
        return None

    # Highest-rated matching doctor first.
    matches.sort(
        key=lambda item: item[0],
        reverse=True,
    )

    _, doctor_id, doctor_data = (
        matches[0]
    )

    return _doctor_response(
        doctor_id,
        doctor_data,
    )


# ---------------------------------------------------------
# Chat API
# ---------------------------------------------------------

class ChatView(APIView):
    permission_classes = [
        IsAuthenticated,
    ]

    @extend_schema(
        request=ChatSerializer,
        responses={
            200: dict,
        },
    )
    def post(
        self,
        request,
    ):
        serializer = ChatSerializer(
            data=request.data,
        )

        serializer.is_valid(
            raise_exception=True,
        )

        validated = (
            serializer.validated_data
        )

        message = validated[
            "message"
        ]

        history = validated.get(
            "history",
            [],
        )

        supplied_context = (
            validated.get(
                "context",
                {},
            )
        )

        try:
            # -----------------------------------
            # Normal health chat
            # -----------------------------------

            if not _is_doctor_recommendation_request(
                message
            ):
                data = chat(
                    message=message,
                    history=history,
                    context=supplied_context,
                )

                return Response(
                    {
                        "success": True,
                        "data": data,
                        "error": None,
                    }
                )

            # -----------------------------------
            # Doctor recommendation request
            # -----------------------------------

            uid = request.user.uid

            db = firestore.client()

            user_document = (
                db.collection("users")
                .document(uid)
                .get()
            )

            user_data = (
                user_document.to_dict()
                or {}
            )

            # -----------------------------------
            # Premium gate
            # -----------------------------------

            if not _has_active_premium(
                user_data
            ):
                return Response(
                    {
                        "success": True,
                        "data": {
                            "message":
                                "Personalized doctor recommendations are available with **SEVA Premium**. Upgrade to Premium to let SEVA review your saved medicines and medical reports and suggest a suitable specialist.",

                            "premium_required":
                                True,

                            "doctor_recommendation":
                                None,
                        },
                        "error": None,
                    }
                )

            # -----------------------------------
            # Build personalized context
            # -----------------------------------

            doctor_context = (
                _build_doctor_context(
                    db=db,
                    uid=uid,
                )
            )

            # Include any manually supplied
            # context without replacing the
            # trusted server-side health data.
            combined_context = {
                **supplied_context,
                **doctor_context,
            }

            # -----------------------------------
            # Ask AI for SPECIALTY only
            # -----------------------------------

            ai_result = chat(
                message=message,
                history=history,
                context=combined_context,
            )

            recommendation = (
                ai_result.get(
                    "doctor_recommendation"
                )
            )

            if not isinstance(
                recommendation,
                dict,
            ):
                recommendation = {
                    "needed": False,
                    "speciality": None,
                    "reason": None,
                }

            recommendation[
                "doctor"
            ] = None

            # -----------------------------------
            # Find real Firestore doctor
            # -----------------------------------

            if recommendation.get(
                "needed"
            ) is True:
                speciality = (
                    recommendation
                    .get(
                        "speciality"
                    )
                )

                if (
                    isinstance(
                        speciality,
                        str,
                    )
                    and speciality.strip()
                ):
                    doctor = _find_doctor(
                        db=db,
                        speciality=speciality,
                    )

                    recommendation[
                        "doctor"
                    ] = doctor

            ai_result[
                "doctor_recommendation"
            ] = recommendation

            ai_result[
                "premium_required"
            ] = False

            # If AI selected a specialty but
            # there is currently no matching
            # available doctor in Firestore,
            # keep the specialty recommendation
            # but do not invent a doctor.
            if (
                recommendation.get(
                    "needed"
                ) is True
                and recommendation.get(
                    "doctor"
                ) is None
            ):
                speciality = (
                    recommendation.get(
                        "speciality"
                    )
                )

                ai_result[
                    "message"
                ] += (
                    "\n\n"
                    f"I recommend reviewing this with a "
                    f"**{speciality or 'medical'} specialist**, "
                    "but I couldn't find an available matching "
                    "doctor in SEVA right now."
                )

            return Response(
                {
                    "success": True,
                    "data": ai_result,
                    "error": None,
                }
            )

        except AIServiceError as error:
            code = (
                "AI_SERVICE_UNAVAILABLE"
            )

            status_code = 503

            if isinstance(
                error,
                AIInvalidResponse,
            ):
                code = (
                    "AI_INVALID_RESPONSE"
                )
                status_code = 502

            if isinstance(
                error,
                AIRateLimited,
            ):
                code = (
                    "AI_RATE_LIMITED"
                )
                status_code = 429

            return Response(
                {
                    "success": False,
                    "data": None,
                    "error": {
                        "code": code,
                        "message": str(
                            error
                        ),
                    },
                },
                status=status_code,
            )

        except Exception as error:
            # Do not expose internal server
            # details to the mobile app.
            print(
                "Chat error:",
                error,
            )

            return Response(
                {
                    "success": False,
                    "data": None,
                    "error": {
                        "code":
                            "CHAT_ERROR",
                        "message":
                            "Could not process the chat request.",
                    },
                },
                status=500,
            )
