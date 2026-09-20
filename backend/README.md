# HealthTech AI Backend

A small Django REST API that acts as a **stateless AI processing service** for a Flutter HealthTech app. Firebase Authentication proves identity; Flutter/Firestore owns persistent app data. Django never saves meal scans, prescriptions, reports, or chat history.

## Architecture

`Flutter -> Firebase Auth -> Firebase ID token -> Django/DRF -> Gemini -> validated JSON -> Flutter -> optional Firestore save`

The backend provides meal-image estimation, medicine/prescription extraction, report extraction/explanation, health-information chat, and medical-specialty suggestions. It does not diagnose, prescribe, book doctors, or invent provider information.

## Requirements

Python 3.12+ is recommended. Create a virtual environment and install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\\Scripts\\activate
python -m pip install --upgrade pip
pip install -r requirements.txt
cp .env.example .env
```

## Environment

Set `DJANGO_SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `GEMINI_API_KEY`, `GEMINI_MODEL`, `FIREBASE_PROJECT_ID`, `GOOGLE_APPLICATION_CREDENTIALS`, `CORS_ALLOWED_ORIGINS`, `MAX_IMAGE_SIZE_MB`, `MAX_REPORT_SIZE_MB`, and optionally `AI_THROTTLE_RATE`.

For Firebase Admin, download a service-account JSON from your Firebase/Google Cloud project, keep it **outside Git**, and set `GOOGLE_APPLICATION_CREDENTIALS` to its absolute path. Django uses Firebase Admin only to verify ID tokens; it does not perform Firestore CRUD.

Create a Gemini API key in Google AI Studio and choose a model that supports image input and structured JSON. The example defaults to `gemini-2.5-flash`; change `GEMINI_MODEL` if your account uses another supported model.

## Run

```bash
python manage.py check
python manage.py runserver
```

No application health-data models or migrations are required. SQLite is configured only for Django/framework compatibility.

## Endpoints

- `GET /api/v1/health/` — public health check
- `POST /api/v1/analyze/meal/` — authenticated multipart image
- `POST /api/v1/analyze/medicine/` — authenticated multipart image
- `POST /api/v1/analyze/report/` — authenticated multipart image/PDF
- `POST /api/v1/chat/` — authenticated JSON chat
- `GET /api/schema/` — OpenAPI schema
- `GET /api/docs/` — Swagger UI

Protected requests require `Authorization: Bearer <firebase_id_token>`.

## Flutter request examples

Meal upload:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/analyze/meal/ \
  -H "Authorization: Bearer $FIREBASE_ID_TOKEN" \
  -F "image=@meal.jpg"
```

Report PDF:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/analyze/report/ \
  -H "Authorization: Bearer $FIREBASE_ID_TOKEN" \
  -F "file=@report.pdf;type=application/pdf"
```

Chat:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/chat/ \
  -H "Authorization: Bearer $FIREBASE_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"What does this result mean?","history":[],"context":{}}'
```

Successful responses use `{"success":true,"data":...,"error":null}`. Controlled errors use `{"success":false,"data":null,"error":{"code":"...","message":"..."}}`.

## Upload rules

JPEG, PNG and WEBP are accepted for image analyzers. Reports additionally accept PDFs with a valid PDF signature. MIME type, extension, size, emptiness, and image decodability are checked. Files are read from Django's temporary upload object and are not deliberately persisted by this project.

## AI safety behavior

Meal nutrition is explicitly approximate. Medicine analysis extracts visible information and does not invent dose/timing. Reports separate printed data from an informational explanation and do not diagnose. Chat gives general health information and may suggest a specialty, never a named doctor/clinic. Flutter should require confirmation before saving extracted medicine data.

## Tests

Gemini is mocked; tests do not call the real API.

```bash
python manage.py test
python manage.py check
python manage.py spectacular --file schema.yml --validate
```

Tests cover Firebase auth, JPEG/PNG validation, unsupported/empty files, AI failures/malformed output, medicine uncertainty, report image/PDF handling, chat history/context limits, and specialty output.

## Security notes

Never commit `.env` or Firebase service-account JSON. Never log bearer tokens, API keys, medical document contents, or image bytes. Use HTTPS in deployment. Keep `DEBUG=False`, configure explicit hosts/CORS origins, rotate secrets if exposed, and place a production reverse proxy/platform request-size limit in front of Django as defense in depth.

## Manual setup still required

1. Create/configure the Firebase project and enable Email/Password + Google sign-in.
2. Create a Firebase Admin service account and set its credential path.
3. Create a Gemini API key and set a supported multimodal model.
4. Set production secret key, hosts, CORS origins, HTTPS/proxy settings, and deployment-specific limits.
5. Flutter must obtain the Firebase ID token and decide what AI output to save to Firestore.
