import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.getenv(
    "DJANGO_SECRET_KEY",
    "dev-only-insecure-key",
)

DEBUG = os.getenv(
    "DEBUG",
    "False",
).lower() == "true"

RAILWAY_DOMAIN = "backend-seva-production.up.railway.app"

DEFAULT_ALLOWED_HOSTS = [
    "localhost",
    "127.0.0.1",
    RAILWAY_DOMAIN,
]

EXTRA_ALLOWED_HOSTS = [
    host.strip()
    for host in os.getenv(
        "ALLOWED_HOSTS",
        "",
    ).split(",")
    if host.strip()
]

ALLOWED_HOSTS = list(
    dict.fromkeys(
        DEFAULT_ALLOWED_HOSTS + EXTRA_ALLOWED_HOSTS
    )
)

SECURE_PROXY_SSL_HEADER = (
    "HTTP_X_FORWARDED_PROTO",
    "https",
)

SECURE_SSL_REDIRECT = (
    not DEBUG
    and os.getenv("RAILWAY_ENVIRONMENT") is not None
)

SESSION_COOKIE_SECURE = not DEBUG

CSRF_COOKIE_SECURE = not DEBUG

SECURE_CONTENT_TYPE_NOSNIFF = True

X_FRAME_OPTIONS = "DENY"

INSTALLED_APPS = [
    "django.contrib.contenttypes",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "drf_spectacular",
    "authentication.apps.AuthenticationConfig",
    "analyzer",
    "chatbot",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
]

ROOT_URLCONF = "config.urls"

WSGI_APPLICATION = "config.wsgi.application"

TEMPLATES = [
    {
        "BACKEND": (
            "django.template.backends.django.DjangoTemplates"
        ),
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [],
        },
    },
]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

STATIC_URL = "/static/"

STATIC_ROOT = BASE_DIR / "staticfiles"

STORAGES = {
    "staticfiles": {
        "BACKEND": (
            "whitenoise.storage."
            "CompressedManifestStaticFilesStorage"
        ),
    },
}

DEFAULT_CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:5173",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:5173",
]

EXTRA_CORS_ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ALLOWED_ORIGINS",
        "",
    ).split(",")
    if origin.strip()
]

CORS_ALLOWED_ORIGINS = list(
    dict.fromkeys(
        DEFAULT_CORS_ALLOWED_ORIGINS
        + EXTRA_CORS_ALLOWED_ORIGINS
    )
)

DEFAULT_CSRF_TRUSTED_ORIGINS = [
    "https://backend-seva-production.up.railway.app",
]

EXTRA_CSRF_TRUSTED_ORIGINS = [
    origin.strip()
    for origin in os.getenv(
        "CSRF_TRUSTED_ORIGINS",
        "",
    ).split(",")
    if origin.strip()
]

CSRF_TRUSTED_ORIGINS = list(
    dict.fromkeys(
        DEFAULT_CSRF_TRUSTED_ORIGINS
        + EXTRA_CSRF_TRUSTED_ORIGINS
    )
)

MAX_IMAGE_SIZE_MB = int(
    os.getenv(
        "MAX_IMAGE_SIZE_MB",
        "10",
    )
)

MAX_REPORT_SIZE_MB = int(
    os.getenv(
        "MAX_REPORT_SIZE_MB",
        "15",
    )
)

GEMINI_API_KEY = os.getenv(
    "GEMINI_API_KEY",
    "",
)

GEMINI_MODEL = os.getenv(
    "GEMINI_MODEL",
    "gemini-3.5-flash-lite",
)

FIREBASE_PROJECT_ID = os.getenv(
    "FIREBASE_PROJECT_ID",
    "",
)

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "authentication.firebase_auth.FirebaseAuthentication",
    ],
    "DEFAULT_SCHEMA_CLASS": (
        "drf_spectacular.openapi.AutoSchema"
    ),
    "DEFAULT_THROTTLE_CLASSES": [
        "authentication.throttling.FirebaseUIDThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "ai": os.getenv(
            "AI_THROTTLE_RATE",
            "30/hour",
        ),
    },
    "UNAUTHENTICATED_USER": None,
}

SPECTACULAR_SETTINGS = {
    "TITLE": "HealthTech AI API",
    "DESCRIPTION": (
        "Stateless AI processing API for the "
        "HealthTech application."
    ),
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": [
            "console",
        ],
        "level": os.getenv(
            "LOG_LEVEL",
            "INFO",
        ),
    },
}

if not DEBUG and SECRET_KEY == "dev-only-insecure-key":
    raise RuntimeError(
        "DJANGO_SECRET_KEY must be configured "
        "for production deployment."
    )