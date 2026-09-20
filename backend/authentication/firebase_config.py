
import json
import os

import firebase_admin
from firebase_admin import credentials


def initialize_firebase():
    """
    Initialize Firebase Admin using Railway credentials.
    """

    # Return the existing Firebase app if initialized.
    try:
        return firebase_admin.get_app()
    except ValueError:
        pass

    # Get Firebase credentials from Railway.
    service_account_json = os.getenv(
        "FIREBASE_SERVICE_ACCOUNT_JSON"
    )

    project_id = os.getenv(
        "FIREBASE_PROJECT_ID"
    )

    options = (
        {"projectId": project_id}
        if project_id
        else {}
    )

    if service_account_json:

        service_account_info = json.loads(
            service_account_json
        )

        credential = credentials.Certificate(
            service_account_info
        )

        return firebase_admin.initialize_app(
            credential,
            options=options,
        )

    # Fallback for local development when
    # Application Default Credentials are configured.
    return firebase_admin.initialize_app(
        options=options,
    )