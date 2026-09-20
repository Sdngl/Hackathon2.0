from pathlib import Path

from PIL import Image, UnidentifiedImageError
from django.conf import settings
from rest_framework.exceptions import ValidationError


IMAGE_MIMES = {
    "image/jpeg": {".jpg", ".jpeg"},
    "image/png": {".png"},
    "image/webp": {".webp"},
}


def validate_upload(file, report=False):
    if not file or file.size <= 0:
        raise ValidationError(
            {
                "file": "INVALID_IMAGE: File is empty.",
            }
        )

    max_mb = (
        settings.MAX_REPORT_SIZE_MB
        if report
        else settings.MAX_IMAGE_SIZE_MB
    )

    if file.size > max_mb * 1024 * 1024:
        raise ValidationError(
            {
                "file": (
                    f"FILE_TOO_LARGE: Maximum size is "
                    f"{max_mb} MB."
                ),
            }
        )

    extension = Path(file.name).suffix.lower()

    mime_type = (
        getattr(file, "content_type", "") or ""
    ).lower()

    if (
        report
        and mime_type == "application/pdf"
        and extension == ".pdf"
    ):
        header = file.read(5)
        file.seek(0)

        if header != b"%PDF-":
            raise ValidationError(
                {
                    "file": (
                        "INVALID_REPORT: Invalid PDF."
                    ),
                }
            )

        return file

    allowed_extensions = IMAGE_MIMES.get(
        mime_type
    )

    if (
        allowed_extensions is None
        or extension not in allowed_extensions
    ):
        message = (
            "UNSUPPORTED_FILE_TYPE: "
            "Use JPEG, PNG, WEBP"
        )

        if report:
            message += " or PDF."

        else:
            message += "."

        raise ValidationError(
            {
                "file": message,
            }
        )

    try:
        file.seek(0)

        image = Image.open(file)
        image.verify()

        file.seek(0)

    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
    ):
        file.seek(0)

        raise ValidationError(
            {
                "file": (
                    "INVALID_IMAGE: "
                    "Image is corrupt or unreadable."
                ),
            }
        )

    return file