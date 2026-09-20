# SEVA — Smart Everyday Vital Assistance

**Your health, in your hands.**

SEVA is a full-stack HealthTech platform for Nepal. It gives people one place to scan medicines, meals and lab reports, understand their saved health information, talk to an AI health assistant, find a suitable **real** doctor, and manage consultations. Doctors and administrators get their own web portals.

Built for **Hackathon 2.0 — HealthTech & Wellbeing** with Flutter, Django REST Framework, Firebase, Gemini, React, Railway and eSewa.

> ⚠️ **Medical disclaimer:** SEVA is for information and education. It is not a doctor, pharmacist or emergency service, and does not diagnose, prescribe or replace professional medical advice.

---

## Contents

**Part 1 — About SEVA**
1. [The problem](#1-the-problem)
2. [What SEVA does](#2-what-seva-does)
3. [Who uses what](#3-who-uses-what)
4. [Architecture](#4-architecture)
5. [How doctor recommendation works](#5-how-doctor-recommendation-works)
6. [Plans & Premium](#6-plans--premium)
7. [Medical safety](#7-medical-safety)

**Part 2 — Developer guide**

8. [Tech stack](#8-tech-stack)
9. [Repositories & layout](#9-repositories--layout)
10. [Firebase setup (shared)](#10-firebase-setup-shared)
11. [Mobile app (Flutter)](#11-mobile-app-flutter)
12. [Backend (Django REST Framework)](#12-backend-django-rest-framework)
13. [Website: landing, admin & doctor portals (React)](#13-website-landing-admin--doctor-portals-react)
14. [Firestore data model](#14-firestore-data-model)
15. [Security](#15-security)
16. [Testing checklist](#16-testing-checklist)
17. [Git workflow](#17-git-workflow)
18. [Troubleshooting](#18-troubleshooting)
19. [Roadmap](#19-roadmap)

---

# Part 1 — About SEVA

## 1. The problem

Non-communicable diseases such as diabetes, hypertension and heart disease cause most deaths in Nepal, and managing them is a daily job. In practice, people forget doses, don't know what they eat, can't read their own lab reports, and don't know which doctor to see.

## 2. What SEVA does

| Feature | What it does |
|---|---|
| **Medicine scan** | Reads visible label information (name, strength, dose, frequency, meal relation) without inventing missing instructions |
| **Meal scan** | Identifies foods and estimates portions, calories, protein, carbs and fat |
| **Report scan** | Extracts tests, values, units, reference ranges and flags, with a plain-language summary |
| **Health history** | Saved medicines, meals and reports in the user's profile |
| **AI Health Assistant** | Chat that can use the user's saved reports, medicines and meals as context |
| **Doctor recommendation** *(Premium)* | AI picks a specialty; the backend matches a **real, active, available** doctor |
| **Doctors & booking** | Doctor profiles, clinic visits and video consultations *(Premium)*, report sharing, appointment history |
| **Emergency call** | Opens the phone dialer with the doctor's number (never calls silently) |
| **Subscriptions** | Premium plans paid with eSewa |
| **Doctor portal** | Doctors set clinic appointment times, manage status and read shared reports |
| **Admin dashboard** | Users, doctors, applications, revenue, scans, suggestion rules, content, notifications and app settings |

## 3. Who uses what

| User | Where | Main tasks |
|---|---|---|
| **Patients** | Flutter app | Scan, chat with the AI, get recommendations, book doctors, share reports, subscribe |
| **Doctors** | Website → `/doctor` | Set times for clinic bookings, reschedule, change status, view shared reports, edit profile & availability |
| **Admin** | Website → `/admin` | Manage the whole platform |
| **Public** | Website → `/` | Landing page, "Join as a doctor" application |

## 4. Architecture

```
┌────────────────────┐      ┌──────────────────────────────────────────────┐
│  Flutter app       │      │  Website (React + Vite)                      │
│  patients          │      │  landing · /admin dashboard · /doctor portal │
└───┬───────────┬────┘      └───────────────────────┬──────────────────────┘
    │           │ HTTPS + Firebase ID token          │ Firebase JS SDK
    │           ▼                                    │
    │   ┌───────────────────────┐    ┌──────────┐    │
    │   │ Django REST API       │───►│ Gemini   │    │
    │   │ (Railway)             │    │ API      │    │
    │   └───────────┬───────────┘    └──────────┘    │
    │               │ Firebase Admin SDK             │
    ▼               ▼                                ▼
┌──────────────────────────────────────────────────────────────────────────┐
│  Firebase — Authentication + Firestore (protected by security rules)     │
│  users/{uid}/{appointments,medicines,meals,reports} · doctors/ · …       │
└──────────────────────────────────────────────────────────────────────────┘
                              ▲
                        eSewa payments (Flutter)
```

| Layer | Responsible for |
|---|---|
| **Flutter** | UI, navigation, Firebase login state, reading/writing the user's Firestore data, calling Django with an ID token, rendering AI results, doctor cards, booking and subscription UI |
| **Django** | Verifying Firebase ID tokens, AI requests to Gemini, JSON schema validation, **server-side Premium checks**, loading trusted health data from Firestore, matching AI specialties to real doctors, safe structured responses |
| **Website** | Public landing page and doctor applications, the admin dashboard and the doctor portal, reading/writing Firestore directly (it does not need the Django API) |
| **Firebase** | One shared project for authentication and data, protected by Firestore security rules |

## 5. How doctor recommendation works

The key design choice: **Gemini recommends a specialty → Django selects a real doctor → Flutter displays that doctor.** The AI never invents doctors, hospitals or appointments.

```
User: "Suggest me a doctor"
        │
        ▼
Django verifies the Firebase token → loads users/{uid}
        │
        ├── Not Premium ──► premium_required: true ──► Flutter shows the Premium card
        │
        └── Premium
              │
              ▼
        Load latest 5 reports + 5 medicines (images removed)
              │
              ▼
        Gemini → { needed, speciality, reason }
              │
              ▼
        Search doctors/ where isActive && available && specialization matches
        (highest rating wins)
              │
              ▼
        Return the real doctor → Flutter renders a doctor card
```

Allowed AI specialties: General Medicine, Cardiology, Dermatology, Endocrinology, Gastroenterology, Orthopedics, Pediatrics, Gynecology, Ophthalmology, ENT.

> **Important:** matching compares these names with each doctor's `specialization` list. A doctor saved as `"Cardiologist"` will **not** match `"Cardiology"`. Use the specialty names above when adding doctors (see [§14](#14-firestore-data-model)).

## 6. Plans & Premium

| Plan | Price |
|---|---|
| Free | 5 scans a day, basic AI assistant, reminders, meal & report log |
| Plus Monthly | Rs. 149 / month |
| Plus 6 Months | Rs. 799 |
| Plus Yearly | Rs. 1,499 / year |

Premium unlocks unlimited scans, more AI, **personalised doctor recommendations** and **video consultations**.

Premium is valid only when `isPaid == true` **and** `subscriptionExpiresAt` is in the future. Flutter may show or hide Premium UI, but **Django is the final authority** for Premium-only features, so a modified app can't bypass them.

## 7. Medical safety

The AI is instructed to act as a health-information assistant and must not:

- diagnose diseases or invent treatment plans
- prescribe, change or stop medication
- invent doctors, hospitals or appointments

It recommends only one allowed specialty, uses only the user's supplied data for personal answers, encourages prompt professional care when something looks urgent, and points to local emergency help for emergencies.

---

# Part 2 — Developer guide

## 8. Tech stack

| Part | Stack |
|---|---|
| Mobile app | Flutter, Dart, Firebase Auth, Cloud Firestore, Dio, url_launcher, eSewa |
| Backend | Python, Django, Django REST Framework, Firebase Admin SDK, Gemini API, drf-spectacular, deployed on Railway |
| Website | React 19, Vite 8, Tailwind CSS v4, React Router v7, Firebase JS SDK v12, Recharts, lucide-react, ESLint |
| Data | Firebase Authentication + Firestore |

## 9. Repositories & layout

| Component | Location |
|---|---|
| Website (landing, admin, doctor portal) | this repo → `website/` |
| Firestore security rules | this repo → `firestore.rules` |
| Flutter app | *add repository link* |
| Django backend | *add repository link* |
| Production API | `https://backend-seva-production.up.railway.app/api/v1/` |

## 10. Firebase setup (shared)

One Firebase project is shared by the app, the backend and the website. These steps are done **once** in the Firebase console.

**Authentication**
1. Authentication → Sign-in method → enable **Email/Password**.
2. Authentication → Users → add the **admin** account (same email as the website's `VITE_ADMIN_EMAIL`).
3. Project settings → General → set the **Public-facing name** to `SEVA` (used in Firebase emails).
4. Doctors get their login from the admin dashboard (**Doctor → Create login & send email**) and choose their own password via Firebase's reset email.

**Firestore indexes** — Firestore → Indexes → Single field → **Add exemption**, enable **Ascending** under *Collection group scope*:

| Collection ID | Field | Used by |
|---|---|---|
| `medicines` | `createdAt` | Admin scans |
| `meals` | `createdAt` | Admin scans |
| `reports` | `createdAt` | Admin scans |
| `appointments` | `doctorId` | Doctor portal |

If one is missing, the website shows an error containing a link that creates it.

**Security rules** — copy [`firestore.rules`](./firestore.rules) into Firestore → Rules, set the admin email in `isAdmin()`, and **Publish**. Then test the app, the admin dashboard and the doctor portal.

## 11. Mobile app (Flutter)

### Run

```bash
flutter pub get
flutter run

# if something is stuck
flutter clean && flutter pub get && flutter run
```

### Structure

```
lib/
├── main.dart
├── service/
│   ├── analysis_api_service.dart     Dio client for the Django API
│   ├── notification_repository.dart
│   └── health_scan_repository.dart
├── payment/
│   └── esewa_payment_page.dart
└── features/
    ├── assistant/
    │   ├── models/                   assistant_message.dart, context_resolution.dart
    │   ├── services/                 health_context_resolver.dart
    │   └── presentation/             health_assistant_screen.dart
    ├── profile/                      doctor detail, booking, appointments, premium, history, profile
    ├── theme/                        apptheme.dart
    └── widgets/                      subscription_card.dart
```

### Talking to the backend

`lib/service/analysis_api_service.dart` uses Dio with the production base URL and sends the Firebase ID token on every request:

```dart
final token = await FirebaseAuth.instance.currentUser!.getIdToken();

await _dio.post(
  'chat/',
  data: {'message': message, 'history': history, 'context': context},
  options: Options(headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  }),
);
```

Main methods: `analyzeImage()`, `analyzeReportFile()`, `analyzeSavedImage()`, `sendMessage()`.

### AI Health Assistant

`health_assistant_screen.dart` supports user/assistant messages, Markdown, quick suggestions, Premium upgrade cards and doctor recommendation cards. One `AssistantMessage` can hold normal text, a Premium-required state, or a doctor recommendation.

**Context resolution** — for questions like *"Explain my latest report"*, the resolver returns one of `general`, `ready`, `missing` or `needsSelection` (the user picks when several items match). Users can also attach a report, medicine or meal manually. Before sending, large image fields (`imageBase64`, `base64`, `imageData`, `image_data`) are removed.

### Doctors & booking

- **Doctor detail page:** image, name, specialization, experience, rating, patients, about, specialties, qualification, clinic, availability, fee, **Book Consultation**, and an emergency call button when `phone` exists.
- **Doctor images** may be a URL or `data:image/jpeg;base64,…`; both are supported (`Image.network` / `Image.memory`).
- **Booking:** clinic visit or video consultation *(Premium)*, with report sharing and a booking summary.
  - **Clinic visits** are sent as a request **without a date**; the doctor confirms the date and time in the doctor portal.
  - **Video consultations** use date and time-slot selection in the app.
- **Cooldown:** after a booking, the user must wait **1 hour** (`nextBookingAllowedAt` on the user). Ideally enforce this in a transaction or on the backend.
- **Appointment history:** 0 → empty state; 1 → opens the detail directly; 2+ → list, then detail.

### Premium

`premium_page.dart` takes `onSubscribe(SubscriptionPlan plan)`, runs the eSewa flow, and on success updates the user document (`isPaid`, `subscriptionPlan`, `subscriptionTitle`, `subscriptionMonths`, `subscriptionPrice`, `subscriptionStartedAt`, `subscriptionExpiresAt`, `subscriptionCancelAtPeriodEnd`, `paymentProvider`, `paymentMode`).

## 12. Backend (Django REST Framework)

### Run locally

```bash
python -m venv .venv
.venv\Scripts\activate            # Windows
# source .venv/bin/activate       # macOS / Linux
pip install -r requirements.txt
python manage.py check
python manage.py runserver                  # local
python manage.py runserver 0.0.0.0:8000     # test from a phone on the same Wi-Fi
```

### Environment variables

```bash
DJANGO_SECRET_KEY=your_secret_key
DEBUG=False
GEMINI_API_KEY=your_gemini_key
FIREBASE_PROJECT_ID=your_firebase_project_id
# + Firebase service-account credentials for the Admin SDK
```

Never commit API keys, service-account private keys or production secrets.

### Authentication

A custom DRF authentication class reads `Authorization: Bearer <token>`, verifies it with `firebase_admin.auth.verify_id_token(...)`, and exposes the user as `request.user.uid`.

### Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/v1/analyze/meal/` | Meal image → foods, portions, calories, macros, notes |
| `POST` | `/api/v1/analyze/medicine/` | Label image → name, generic, strength, form, dose, frequency, duration, meal relation |
| `POST` | `/api/v1/analyze/report/` | Report file → title, lab, date, tests, values, units, ranges, flags, summary, suggested specialty |
| `POST` | `/api/v1/chat/` | AI assistant, including Premium doctor recommendations |

**Chat request** (validated by `ChatSerializer`, which limits message, history and context size):

```json
{ "message": "Suggest me a doctor", "history": [], "context": {} }
```

**Chat response** (Gemini must return JSON matching `CHAT_SCHEMA`; Django adds the matched doctor):

```json
{
  "success": true,
  "data": {
    "message": "Based on your saved health information, an **Orthopedics** review may be appropriate.",
    "premium_required": false,
    "doctor_recommendation": {
      "needed": true,
      "speciality": "Orthopedics",
      "reason": "Your saved information may benefit from orthopedic review.",
      "doctor": {
        "id": "doctor_123",
        "name": "DR. PRAKASH ADHIKARI",
        "specialization": ["Orthopedics", "Trauma Surgery"],
        "hospital": "Grande International Hospital",
        "imageUrl": "data:image/jpeg;base64,...",
        "rating": 4.9,
        "available": true
      }
    }
  },
  "error": null
}
```

For free users, `premium_required` is `true` and `doctor_recommendation` is `null`.

### Error codes

| Code | Meaning |
|---|---|
| 400 | Bad request |
| 401 / 403 | Unauthorized / forbidden |
| 404 | Not found |
| 408 / 504 | Timeout |
| 413 | File too large |
| 429 | AI rate limit |
| 500 | Backend error |
| 502 | AI returned an invalid response |
| 503 | AI service unavailable |

Flutter turns these into friendly messages.

### Deployment (Railway)

Railway redeploys automatically when the connected branch is pushed:

```bash
git add .
git commit -m "Update SEVA backend"
git push
```

Afterwards, test `/api/v1/chat/` through the app.

## 13. Website: landing, admin & doctor portals (React)

### Run

```bash
cd website
npm install
npm run dev        # http://localhost:3000
npm run build      # production build (a "chunks larger than 500 kB" warning is normal)
npm run lint       # must show no errors before committing
```

Requires **Node.js 20.19+ or 22.12+**.

### Environment variables

Create `website/.env` (git-ignored; get the values privately from the team):

```bash
# Firebase console → Project settings → General → Your apps → Web app
VITE_FIREBASE_API_KEY=
VITE_FIREBASE_AUTH_DOMAIN=
VITE_FIREBASE_PROJECT_ID=
VITE_FIREBASE_STORAGE_BUCKET=
VITE_FIREBASE_MESSAGING_SENDER_ID=
VITE_FIREBASE_APP_ID=
VITE_ADMIN_EMAIL=            # admin account email, never the password
```

### Pages

| URL | Page |
|---|---|
| `/` | Landing page (features, pricing, "Join as a doctor") |
| `/portal` | Choose Admin or Doctor |
| `/join-doctor` | Public doctor application form |
| `/admin/login` → `/admin` | **Admin:** Overview, Users, Doctors (+ applications), Clinics, Appointments, Subscriptions & Revenue, Scans & AI Usage, Suggestion Rules, Content, Notifications, Settings |
| `/doctor/login` → `/doctor` | **Doctor:** Overview, Appointments (set date & time, reschedule, status), Patients, Shared Reports, Availability, My Profile, Settings |

Also: global search (⌘K), date-range picker, live notification badge, CSV export, doctor photo upload (compressed base64), and a readable view of AI report analysis.

### Structure

```
website/src/
├── App.jsx             routes (public, /admin/*, /doctor/*)
├── index.css           Tailwind + SEVA theme colours
├── components/         landing sections, shared pickers; admin/ and doctor/ UI
├── context/            AuthContext (admin/doctor), AdminContext, DoctorContext
├── hooks/              Firestore hooks (useCollection, useDocument, …)
├── lib/                plain logic: stats, revenue, appointments, rules, access passes…
└── pages/              Landing, PortalSelect, DoctorApplication; admin/*; doctor/*
```

Rule of thumb: `pages/` = a screen at a URL, `components/` = pieces inside screens, `lib/` = logic without UI. To add a page, add it to `components/admin/navItems.js` (or `components/doctor/navItems.js`), create it in `pages/`, and register it in `App.jsx`.

## 14. Firestore data model

```
users/{uid}
  displayName, email, age, city, emergencyContact, createdAt, lastLoginAt
  isPaid, subscriptionPlan, subscriptionTitle, subscriptionMonths, subscriptionPrice,
  subscriptionStartedAt, subscriptionExpiresAt, subscriptionCancelAtPeriodEnd,
  paymentProvider, paymentMode, nextBookingAllowedAt
  ├── medicines/{id}      (createdAt)
  ├── meals/{id}          (createdAt)
  ├── reports/{id}        (createdAt, analysis …)
  └── appointments/{id}
        doctorId, doctorName, doctorSpecialization, doctorImageUrl,
        consultationType ("clinic" | "video"), status, lastNotifiedStatus,
        appointmentDate (Timestamp), appointmentTime ("10:30 AM"),
        reportShared, reportId, clinicName, clinicAddress, createdAt, scheduledAt

doctors/{id}
  name, specialization[], specialties[], qualification, about, hospital,
  clinicName, clinicAddress, clinicHours, phone, email, languages[], availableSlots[],
  imageUrl (URL or base64), rating, reviewCount, patientCount, experienceYears,
  consultationFee, available, isActive, verified, licenseNumber,
  authUid, loginEmail   ← set when the admin creates the doctor's login

doctorApplications/{id}   public "Join as a doctor" form, reviewed by the admin
doctorAccess/{id}          access pass: a doctor may read a patient's profile
reportAccess/{id}          access pass: a doctor may read one shared report
suggestionRules/{id}       report → specialist / tip rules (admin)
content/{id}               articles, tips, banners, FAQs (admin)
announcements/{id}         in-app messages (admin)
appConfig/general          default language, support contact, maintenance mode (admin)
adminSettings/{uid}        admin dashboard preferences
```

**Doctor specialization names must match the AI's allowed specialties** (Cardiology, Dermatology, Orthopedics, …) for recommendations to find them.

## 15. Security

- Every Django request is authenticated with a verified Firebase ID token.
- Premium is enforced on the server, not only in the app.
- Firestore rules give each user their own data; the admin manages the platform; doctors see only appointments booked with them, and only the reports patients chose to share (through access passes the rules verify).
- AI requests exclude image/base64 fields and are limited to recent data (5 reports, 5 medicines).
- Secrets live in environment variables, never in Git.
- **Known gap:** the app currently writes `isPaid` and subscription fields itself after eSewa. Before real payments, verify eSewa on the server and block users from editing those fields in the rules.

## 16. Testing checklist

| Test | Expected |
|---|---|
| Free user asks *"Suggest me a doctor"* | Premium upgrade card |
| Premium user asks *"Suggest me a doctor"* | Reports + medicines loaded, specialty chosen, real doctor matched, doctor card shown |
| *"What foods contain vitamin D?"* | Normal answer, no Premium card |
| *"Explain my latest report"* | Saved report resolved and explained simply |
| Clinic booking with a shared report | Appears in the doctor portal under **Needs a date**, with **View report** |
| Doctor sets date & time | Appointment moves to Upcoming in the portal and the app shows the time |
| Book twice within an hour | Second booking blocked with a wait message |
| Website | `npm run build` and `npm run lint` pass; admin and doctor logins work |

## 17. Git workflow

Never work directly on `main`.

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature
# …changes…
git status                                   # no .env or secret files listed
git add <your folder>
git commit -m "Short description"
git push -u origin feature/your-feature      # plain `git push` afterwards
```

Open a **Pull Request** (base `main` ← compare your branch), merge when there are no conflicts, then everyone runs `git pull origin main`.

## 18. Troubleshooting

| Problem | Fix |
|---|---|
| Website: `auth/invalid-api-key` | `website/.env` missing or misplaced; restart `npm run dev` |
| "The query requires an index" | Click the link in the error, save, wait 1–2 minutes (§10) |
| "Missing or insufficient permissions" | Check `firestore.rules` is published and the admin email is right |
| Doctor portal shows "Unknown patient" | The doctor has no login (`authUid`) yet, or the patient profile has no `displayName` |
| AI recommends a specialty but no doctor is returned | No active, available doctor has that exact specialty name (§14) |
| App gets 401 from the API | ID token missing or expired; sign in again |
| App gets 429 / 503 | Gemini rate limit or outage; retry later |

## 19. Roadmap

**Done:** admin dashboard, doctor-side appointment dashboard, doctor applications & verification, report sharing with doctors.

**Next:** appointment cancellation · push notifications and real-time status · server-side booking cooldown · server-verified eSewa payments · doctor availability calendar · richer doctor search and specialty matching · video consultation integration · encrypted sensitive health fields · audit logging · emergency contacts · personalised notification scheduling.

---

**SEVA — Smart Everyday Vital Assistance.** Built with Flutter, Firebase, Django REST Framework, Firestore, Gemini, React, Railway and eSewa.
