import base64
import binascii

from django.core.files.uploadedfile import (
    SimpleUploadedFile,
)

from rest_framework.views import APIView
from rest_framework.permissions import (
    AllowAny,
    IsAuthenticated,
)
from rest_framework.response import Response

from drf_spectacular.utils import extend_schema

from firebase_admin import firestore

from .serializers import (
    AnalyzeSavedImageSerializer,
    AnalyzeReportSerializer,
)
from .validators import validate_upload

from authentication.firebase_auth import (
    get_firestore_client,
)

from ai.meal import analyze_meal
from ai.medicine import analyze_medicine
from ai.report import analyze_report

from ai.client import (
    AIServiceError,
    AIInvalidResponse,
    AIRateLimited,
)


def ok(data):
    return Response(
        {
            "success": True,
            "data": data,
            "error": None,
        }
    )


def api_error(
    *,
    code,
    message,
    status_code,
):
    return Response(
        {
            "success": False,
            "data": None,
            "error": {
                "code": code,
                "message": message,
            },
        },
        status=status_code,
    )


def ai_error(error):
    code = "AI_SERVICE_UNAVAILABLE"
    status_code = 503

    if isinstance(
        error,
        AIInvalidResponse,
    ):
        code = "AI_INVALID_RESPONSE"
        status_code = 502

    elif isinstance(
        error,
        AIRateLimited,
    ):
        code = "AI_RATE_LIMITED"
        status_code = 429

    return api_error(
        code=code,
        message=str(error),
        status_code=status_code,
    )


class HealthView(APIView):
    permission_classes = [
        AllowAny,
    ]

    authentication_classes = []
    throttle_classes = []

    @extend_schema(
        responses={
            200: {
                "type": "object",
                "properties": {
                    "success": {
                        "type": "boolean",
                    },
                    "data": {
                        "type": "object",
                        "properties": {
                            "status": {
                                "type": "string",
                            },
                        },
                    },
                    "error": {
                        "nullable": True,
                    },
                },
            }
        }
    )
    def get(
        self,
        request,
    ):
        return ok(
            {
                "status": "ok",
            }
        )


class BaseAnalyzeView(APIView):
    permission_classes = [
        IsAuthenticated,
    ]

    serializer_class = (
        AnalyzeSavedImageSerializer
    )

    fn = None
    collection_name = None
    scan_type = None

    @extend_schema(
        request=AnalyzeSavedImageSerializer,
        responses={
            200: dict,
        },
    )
    def post(
        self,
        request,
    ):
        serializer = self.serializer_class(
            data=request.data,
        )

        serializer.is_valid(
            raise_exception=True,
        )

        record_id = (
            serializer.validated_data[
                "record_id"
            ]
        )

        uid = request.user.uid

        db = get_firestore_client()

        document_ref = (
            db.collection("users")
            .document(uid)
            .collection(
                self.collection_name
            )
            .document(record_id)
        )

        snapshot = document_ref.get()

        if not snapshot.exists:
            return api_error(
                code="SCAN_NOT_FOUND",
                message=(
                    "The saved scan could not "
                    "be found."
                ),
                status_code=404,
            )

        document_data = (
            snapshot.to_dict()
            or {}
        )

        stored_type = (
            document_data.get("type")
        )

        if (
            stored_type is not None
            and stored_type != self.scan_type
        ):
            return api_error(
                code="INVALID_SCAN_TYPE",
                message=(
                    "The saved scan type does not "
                    "match this analyzer."
                ),
                status_code=400,
            )

        image_base64 = (
            document_data.get(
                "imageBase64"
            )
        )

        if not image_base64:
            return api_error(
                code="IMAGE_NOT_FOUND",
                message=(
                    "The saved scan does not "
                    "contain an image."
                ),
                status_code=400,
            )

        if not isinstance(
            image_base64,
            str,
        ):
            return api_error(
                code="INVALID_IMAGE_DATA",
                message=(
                    "The stored image data "
                    "is invalid."
                ),
                status_code=400,
            )

        try:
            image_bytes = (
                base64.b64decode(
                    image_base64,
                    validate=True,
                )
            )

        except (
            ValueError,
            TypeError,
            binascii.Error,
        ):
            return api_error(
                code="INVALID_IMAGE_DATA",
                message=(
                    "The stored image data "
                    "is invalid."
                ),
                status_code=400,
            )

        if not image_bytes:
            return api_error(
                code="EMPTY_IMAGE",
                message=(
                    "The stored image is empty."
                ),
                status_code=400,
            )

        image_mime_type = (
            document_data.get(
                "imageMimeType"
            )
        )

        if not isinstance(
            image_mime_type,
            str,
        ):
            return api_error(
                code="INVALID_IMAGE_TYPE",
                message=(
                    "The stored image type "
                    "is invalid."
                ),
                status_code=400,
            )

        image_mime_type = (
            image_mime_type
            .strip()
            .lower()
        )

        extension = self._extension_for_mime(
            image_mime_type
        )

        if extension is None:
            return api_error(
                code="UNSUPPORTED_IMAGE_TYPE",
                message=(
                    "The stored image must be "
                    "JPEG, PNG, or WEBP."
                ),
                status_code=400,
            )

        upload = SimpleUploadedFile(
            name=(
                f"{record_id}.{extension}"
            ),
            content=image_bytes,
            content_type=image_mime_type,
        )

        try:
            validate_upload(
                upload,
                report=False,
            )

            document_ref.update(
                {
                    "status": "processing",
                    "analysisError": (
                        firestore.DELETE_FIELD
                    ),
                    "updatedAt": (
                        firestore.SERVER_TIMESTAMP
                    ),
                }
            )

            result = self.fn(
                upload
            )

            if not isinstance(
                result,
                dict,
            ):
                raise AIInvalidResponse(
                    "Analyzer returned an invalid result."
                )

            if (
                result.get("type")
                != self.scan_type
            ):
                raise AIInvalidResponse(
                    "Analyzer returned an invalid scan type."
                )

            document_ref.update(
                {
                    "status": "completed",
                    "analysis": result,
                    "analysisError": (
                        firestore.DELETE_FIELD
                    ),
                    "updatedAt": (
                        firestore.SERVER_TIMESTAMP
                    ),
                }
            )

            return ok(
                result
            )

        except AIServiceError as error:
            document_ref.update(
                {
                    "status": "failed",
                    "analysisError": {
                        "code": (
                            error.__class__.__name__
                        ),
                        "message": str(
                            error
                        ),
                    },
                    "updatedAt": (
                        firestore.SERVER_TIMESTAMP
                    ),
                }
            )

            return ai_error(
                error
            )

        except Exception:
            document_ref.update(
                {
                    "status": "failed",
                    "analysisError": {
                        "code": (
                            "ANALYSIS_FAILED"
                        ),
                        "message": (
                            "Unexpected analysis "
                            "error."
                        ),
                    },
                    "updatedAt": (
                        firestore.SERVER_TIMESTAMP
                    ),
                }
            )

            return api_error(
                code="ANALYSIS_FAILED",
                message=(
                    "The scan could not be analyzed."
                ),
                status_code=500,
            )

    def _extension_for_mime(
        self,
        mime_type,
    ):
        mapping = {
            "image/jpeg": "jpg",
            "image/jpg": "jpg",
            "image/png": "png",
            "image/webp": "webp",
        }

        return mapping.get(
            mime_type.lower()
        )
class MealView(
    BaseAnalyzeView,
):
    collection_name = "meals"
    scan_type = "meal"

    fn = staticmethod(
        analyze_meal
    )


class MedicineView(
    BaseAnalyzeView,
):
    collection_name = "medicines"
    scan_type = "medicine"

    fn = staticmethod(
        analyze_medicine
    )


class ReportView(
    BaseAnalyzeView,
):
    collection_name = "reports"
    scan_type = "report"

    fn = staticmethod(
        analyze_report
    )

    serializer_class = (
        AnalyzeReportSerializer
    )

    @extend_schema(
        request=AnalyzeReportSerializer,
        responses={
            200: dict,
        },
    )
    def post(
        self,
        request,
    ):
        serializer = self.serializer_class(
            data=request.data,
        )

        serializer.is_valid(
            raise_exception=True,
        )

        upload = (
            serializer.validated_data.get(
                "file"
            )
        )

        if upload is not None:
            return self._analyze_uploaded_file(
                request=request,
                upload=upload,
            )

        return super().post(
            request
        )

    def _analyze_uploaded_file(
        self,
        *,
        request,
        upload,
    ):
        uid = request.user.uid

        file_name = (
            upload.name
            or "medical_report"
        )

        content_type = (
            upload.content_type
            or ""
        ).lower()

        try:
            file_bytes = upload.read()

        except Exception:
            return api_error(
                code="INVALID_FILE",
                message=(
                    "The selected report could "
                    "not be read."
                ),
                status_code=400,
            )

        if not file_bytes:
            return api_error(
                code="EMPTY_FILE",
                message=(
                    "The selected report is empty."
                ),
                status_code=400,
            )

        max_size = (
            12 * 1024 * 1024
        )

        if len(file_bytes) > max_size:
            return api_error(
                code="FILE_TOO_LARGE",
                message=(
                    "The report must be smaller "
                    "than 12 MB."
                ),
                status_code=400,
            )

        is_pdf = (
            file_bytes.startswith(
                b"%PDF-"
            )
        )

        is_image = (
            content_type
            in {
                "image/jpeg",
                "image/jpg",
                "image/png",
                "image/webp",
            }
        )

        if not is_pdf and not is_image:
            return api_error(
                code="UNSUPPORTED_REPORT_FILE",
                message=(
                    "Please upload a PDF, JPG, "
                    "PNG, or WEBP report."
                ),
                status_code=400,
            )

        if is_pdf:
            mime_type = (
                "application/pdf"
            )

            extension = "pdf"

        else:
            mime_type = (
                content_type
            )

            extension = (
                self._extension_for_mime(
                    mime_type
                )
            )

        safe_upload = (
            SimpleUploadedFile(
                name=(
                    f"report.{extension}"
                ),
                content=file_bytes,
                content_type=mime_type,
            )
        )

        db = (
            get_firestore_client()
        )

        document_ref = (
            db.collection("users")
            .document(uid)
            .collection("reports")
            .document()
        )

        document_ref.set(
            {
                "type": "report",
                "status": "processing",
                "sourceType": (
                    "pdf"
                    if is_pdf
                    else "image"
                ),
                "fileName": file_name,
                "analysis": None,
                "createdAt": (
                    firestore.SERVER_TIMESTAMP
                ),
                "updatedAt": (
                    firestore.SERVER_TIMESTAMP
                ),
            }
        )

        try:
            result = analyze_report(
                safe_upload
            )

            document_ref.update(
                {
                    "status": "completed",
                    "analysis": result,
                    "updatedAt": (
                        firestore.SERVER_TIMESTAMP
                    ),
                }
            )

            response_data = dict(
                result
            )

            response_data[
                "record_id"
            ] = document_ref.id

            return ok(
                response_data
            )

        except AIServiceError as error:
            document_ref.update(
                {
                    "status": "failed",
                    "analysisError": {
                        "message": str(
                            error
                        ),
                    },
                    "updatedAt": (
                        firestore.SERVER_TIMESTAMP
                    ),
                }
            )

            return ai_error(
                error
            )

        except Exception as error:
            document_ref.update(
                {
                    "status": "failed",
                    "analysisError": {
                        "message": (
                            "Unexpected analysis "
                            "error."
                        ),
                    },
                    "updatedAt": (
                        firestore.SERVER_TIMESTAMP
                    ),
                }
            )

            return api_error(
                code="ANALYSIS_FAILED",
                message=str(
                    error
                ),
                status_code=500,
            )