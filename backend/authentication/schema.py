from drf_spectacular.extensions import OpenApiAuthenticationExtension


class FirebaseAuthenticationScheme(OpenApiAuthenticationExtension):
    target_class = "authentication.firebase_auth.FirebaseAuthentication"
    name = "FirebaseBearer"

    def get_security_definition(self, auto_schema):
        return {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "Firebase ID token",
            "description": "Firebase Authentication ID token",
        }