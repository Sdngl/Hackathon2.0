from google.genai import types


def file_part(upload):
    upload.seek(0)

    data = upload.read()

    upload.seek(0)

    if not data:
        raise ValueError(
            "Uploaded file is empty."
        )

    mime_type = getattr(
        upload,
        "content_type",
        None,
    )

    if not mime_type:
        raise ValueError(
            "Uploaded file has no content type."
        )

    mime_type = (
        mime_type
        .split(";")[0]
        .strip()
        .lower()
    )

    allowed_mime_types = {
        "application/pdf",
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
    }

    if mime_type not in allowed_mime_types:
        raise ValueError(
            "Unsupported file type."
        )

    return types.Part.from_bytes(
        data=data,
        mime_type=mime_type,
    )