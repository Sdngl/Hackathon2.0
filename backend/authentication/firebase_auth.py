from dataclasses import dataclass

from firebase_admin import (
    auth,
    firestore,
)

from rest_framework.authentication import (
    BaseAuthentication,
    get_authorization_header,
)

from rest_framework.exceptions import (
    AuthenticationFailed,
    APIException,
)

from .firebase_config import initialize_firebase


@dataclass
class FirebaseUser:

    uid: str

    email: str | None = None

    is_authenticated: bool = True

    @property
    def pk(self):
        return self.uid


def _ensure_app():
    return initialize_firebase()


def get_firestore_client():
    app = _ensure_app()

    return firestore.client(
        app=app
    )


class FirebaseAuthentication(BaseAuthentication):

    keyword = b"Bearer"

    def authenticate(self, request):

        header = get_authorization_header(
            request
        ).split()

        if not header:
            return None

        if (
            len(header) != 2
            or header[0].lower() != b"bearer"
        ):

            raise AuthenticationFailed(
                "Malformed Authorization header."
            )

        try:

            token = header[1].decode(
                "utf-8"
            )

        except UnicodeDecodeError:

            raise AuthenticationFailed(
                "Invalid Authorization header."
            )

        try:

            app = _ensure_app()

        except Exception:

            raise APIException(
                "Firebase authentication service "
                "is not configured correctly."
            )

        try:

            decoded = auth.verify_id_token(
                token,
                app=app,
                check_revoked=False,
            )

        except (
            ValueError,
            auth.InvalidIdTokenError,
            auth.ExpiredIdTokenError,
            auth.RevokedIdTokenError,
            auth.CertificateFetchError,
        ):

            raise AuthenticationFailed(
                "Invalid or expired Firebase ID token."
            )

        uid = (
            decoded.get("uid")
            or decoded.get("sub")
        )

        if not uid:

            raise AuthenticationFailed(
                "Firebase token does not contain a UID."
            )

        return (
            FirebaseUser(
                uid=uid,
                email=decoded.get("email"),
            ),
            decoded,
        )

    def authenticate_header(
        self,
        request,
    ):

        return "Bearer"