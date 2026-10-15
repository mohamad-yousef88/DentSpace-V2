# DentSpace

**Backend + Admin Panel powering a dental-care platform that connects patients with supervised dentistry students.**

[![Python](https://img.shields.io/badge/Python-3.11%2B-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688.svg)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791.svg)](https://www.postgresql.org/)
[![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-2.0_async-red.svg)](https://www.sqlalchemy.org/)
[![Tailwind](https://img.shields.io/badge/Tailwind_CSS-3.4-38BDF8.svg)](https://tailwindcss.com/)
[![Jinja2](https://img.shields.io/badge/Jinja2-3.x-B41717.svg)](https://jinja.palletsprojects.com/)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey.svg)](#license)

---

## Overview

**DentSpace** is a dental-care platform that connects patients who need affordable treatment with supervised dentistry students who need hands-on clinical training.

The project delivers **two interfaces** on top of a single FastAPI application:

1. **REST API** for the Flutter mobile app (patients & doctors).
2. **Admin Panel** — a Jinja2-rendered web UI for platform administrators, served from the same FastAPI process at `/admin`.

Both interfaces consume the **same application services**, share the **same domain model**, and are deployed as **one process** — no CORS, no second server, no duplicated business logic.

Full coverage includes:

- **Patient onboarding** with email OTP verification.
- **Smart symptom triage** using a MYCIN-style certainty-factor engine.
- **Case lifecycle** from complaint to admin-verified completion.
- **Appointment matching** between patients and student doctors.
- **Peer-to-peer tool marketplace** for dental equipment.
- **Push and in-app notifications** via Firebase Cloud Messaging.
- **Admin oversight** — users, doctors, cases, verification, dashboard.

The architecture is **Clean Architecture** (Domain → Application → Infrastructure → Presentation), fully asynchronous, and production-ready.

---

## Core Features

### Authentication & Authorization
- Email/password registration with **6-digit OTP verification**.
- **JWT access & refresh tokens** (HS256, configurable TTL).
- **Password reset** via OTP.
- **Session revocation** — `/auth/logout-all` invalidates every previously issued token.
- **Role-based access control**: `patient`, `doctor`, `admin`.
- **Strong password policy**: minimum 12 chars, letter + digit, blacklist check.
- **Rate-limited** auth endpoints via `slowapi`.
- **Admin sessions**: signed-cookie sessions (`SessionMiddleware`) separate from the JWT flow, scoped to the `/admin` panel.

### Patient Case Management
- Patients submit symptoms, pain/swelling severity, location, optional images.
- A **deterministic diagnostic engine** returns:
  - **Differential diagnosis** (top-3 conditions with confidence %).
  - **Triage urgency** (`routine` → `emergency`).
  - **Red-flag detection** (e.g. trismus, fever, spreading swelling).
  - **Patient-facing Arabic guidance** per condition.
- Rules: max 3 pending cases per patient, per-image size limit, magic-byte validation.
- Booked cases are **locked** against edits/deletes.

### Appointment Lifecycle
- Doctors send requests; patients approve/reject.
- On approval the case becomes **booked** and other pending requests are **auto-rejected**.
- Full lifecycle: `pending → approved → completed`, with `rejected` / `cancelled` branches.
- **Row-level locking** (`SELECT ... FOR UPDATE`) prevents concurrent double-approval.
- Limits: max 3 active appointments per patient **and** per doctor.

### Notifications
- In-app notification center with read/unread state and deletion.
- **FCM push delivery** with auto-cleanup of stale tokens (`UnregisteredError`).
- Push delivery is **best-effort** — a failing FCM call never breaks the request.

### Tools Marketplace
- Doctors publish dental tools with images (Cloudinary-hosted).
- Full order flow: `pending → approved → completed`, plus `rejected` / `cancelled`.
- **Auto-rejection** of competing orders on approve/complete.
- Tool deletion cascades to Cloudinary asset cleanup (best-effort).
- Limits: 5 available tools per seller, 5 active orders per buyer.

### Admin Console (Web UI)

The admin panel is a **server-rendered Jinja2 application** built with **Tailwind CSS**, **Alpine.js**, and **vanilla JS enhancements**. It ships with the following features:

#### Dashboard
- **4 KPI cards**: users, cases, appointments, pending reviews (with count-up animation).
- **Line chart** — cases created over the last 7 days.
- **Doughnut chart** — users by role (patients / doctors / admins).
- **Bar chart** — cases by status (pending / booked / completed / verified).
- **Quick action tiles** linking to common workflows.

#### Users Management
- **Searchable & filterable** table (by name, email, phone; by role; by active status).
- **Toggle account status** (enable / disable) with self-lockout protection.
- **Reset password** via modal dialog.
- **Delete user** with confirm modal.
- **User detail page** with full profile and actions.

#### Doctors Management
- **Searchable list** of all doctors.
- **Create doctor** form with: full name, email, phone, password (min 12 chars), university ID, age, gender.
- Server-side and client-side validation.
- **Doctor detail page** with contact info, status toggle, password reset.
- **Toggle status** and **reset password** directly from the list.

#### Cases Review
- **Filter tabs**: All / Awaiting review / Verified / Booked / Pending.
- **Table** with patient, doctor, condition, status, action.
- **Case detail page** with:
  - Patient + doctor cards.
  - Symptoms chips.
  - Image gallery (clickable thumbnails).
  - **Verify treatment** / **Reject** form with notes (only for `completed` cases).

#### Profile
- **Avatar upload** (JPEG / PNG / WEBP, max 5 MB) with old file cleanup.
- **Edit form** for name, phone, gender, age.
- **Conflict detection** on phone number.

#### UX Features
- **Bilingual**: Arabic (RTL) + English (LTR), toggle in the topbar.
- **Dark mode** with `localStorage` + cookie persistence and FOUC prevention.
- **Responsive**: mobile-first, works down to 375 px with a slide-in drawer.
- **Toast notifications** for flash messages (auto-dismiss).
- **Confirm modal** (native `<dialog>`) for destructive actions.
- **Loading states** on form submission (spinner + disabled button).
- **Fade-in-up** entrance animations, respecting `prefers-reduced-motion`.
- **Cairo font** (Google Fonts) with Arabic-optimized typography.

### Operations
- **Background cleanup jobs** (APScheduler):
  - Read notifications > 7 days.
  - Unread notifications > 90 days.
  - Cancelled/rejected appointments > 30 days.
  - Cancelled/rejected orders > 30 days.
  - Used/expired OTPs > 24 hours.
- **Rotating file logs** (10 MB × 5 backups).
- **Health endpoints**: `/health` (liveness) and `/health/ready` (DB readiness).
- **Request-ID middleware** for end-to-end traceability.
- **Rate-limiter cleanup task** (in-process, every 6 hours).

---

## Tech Stack

### Backend

| Layer | Technology |
|---|---|
| Runtime | Python 3.11+ |
| Web Framework | FastAPI 0.115 |
| ASGI Server | Uvicorn |
| ORM | SQLAlchemy 2.0 (async) |
| Driver | asyncpg |
| Database | PostgreSQL 15+ |
| Migrations | Alembic |
| Validation | Pydantic v2 + pydantic-settings |
| Auth (API) | python-jose (JWT), passlib[bcrypt] |
| Auth (Admin) | itsdangerous + Starlette SessionMiddleware |
| Rate Limiting | slowapi |
| Scheduler | APScheduler |
| Media | Cloudinary SDK |
| Push | firebase-admin |
| Email | aiosmtplib (SMTP) |
| Testing | pytest + pytest-asyncio + httpx |

### Admin Panel

| Layer | Technology |
|---|---|
| Templating | Jinja2 (built into FastAPI) |
| CSS | Tailwind CSS 3.4 (CLI build) |
| JS (interactivity) | Vanilla ES2019 + Alpine.js (optional) |
| Charts | Chart.js 4 (CDN) |
| Fonts | Cairo (Google Fonts) |
| Icons | Lucide (inline SVG) |
| Animations | CSS keyframes + count-up via `requestAnimationFrame` |
| Build | Tailwind CLI + PostCSS + Autoprefixer |

---

## Architecture

### Layered (Clean Architecture)

```
+---------------------------------------------------------------+
|                        PRESENTATION                           |
|  API Routers (Jinja) — Middleware — Exception handlers — DTOs |
+---------------------------------------------------------------+
|                       APPLICATION                             |
|  Services (AuthService, AdminService, CaseService, ...)       |
|  Orchestrates use cases. Owns transaction boundaries.         |
+---------------------------------------------------------------+
|                         DOMAIN                                |
|  Entities — Repository interfaces — Domain services           |
|  Pure Python. No framework, no I/O.                           |
+---------------------------------------------------------------+
|                     INFRASTRUCTURE                            |
|  SQLAlchemy models — Repositories — External clients          |
|  (Cloudinary, FCM, SMTP) — Scheduled jobs                     |
+---------------------------------------------------------------+
```

**Dependency rule:** outer layers depend on inner ones, never the reverse.
The domain layer imports nothing from FastAPI, SQLAlchemy, or any SDK.

### Dual Presentation

```
                    +---------------------+
                    |  FastAPI Application|
                    +----------+----------+
                               |
        +----------------------+----------------------+
        |                                             |
   /api/v1/*                                     /admin/*
   (Mobile REST API)                         (Admin UI — Jinja2)
        |                                             |
        +----------------------+----------------------+
                               |
                    +----------v----------+
                    |  Domain + Application|
                    |  + Infrastructure    |
                    |  (shared services)   |
                    +----------------------+
```

- **`/api/v1/*`** → JSON for the Flutter app.
- **`/admin/*`** → HTML for the admin panel.
- **`/static/*`** → CSS, JS, fonts, images for the admin panel.

Both use the same `AuthService`, `AdminService`, `CaseService`, etc. No business logic is duplicated.

**Key patterns used:**

- **Repository pattern** — interfaces in `domain/repositories/`, implementations in `infrastructure/repositories/`.
- **Application services** — business orchestration, one class per bounded concern.
- **Domain services** — pure logic (e.g. the symptom analyzer).
- **Dependency injection** — FastAPI `Depends` with typed aliases (`AuthSvc`, `CaseSvc`, ...).

---

## Project Structure

```
BackEnd/
│
├── app/
│   ├── main.py                       # App factory, lifespan, middleware wiring
│   ├── core/
│   │   ├── config.py                 # Pydantic Settings (reads .env)
│   │   ├── security.py               # JWT + password hashing
│   │   ├── exceptions.py             # Domain exceptions + handlers
│   │   ├── dependencies.py           # FastAPI DI: current user, services
│   │   ├── logging.py                # Rotating file + console logging
│   │   ├── rate_limit.py             # Shared slowapi limiter
│   │   └── validators.py             # Password strength, reusable validators
│   ├── domain/
│   │   ├── entities/                 # Pure dataclasses: User, PatientCase, ...
│   │   ├── repositories/             # Abstract interfaces
│   │   └── services/
│   │       └── symptom_analyzer.py   # MYCIN-style diagnostic engine
│   ├── application/
│   │   ├── services/                 # AuthService, CaseService, ...
│   │   └── dtos/                     # Pydantic request/response schemas
│   ├── infrastructure/
│   │   ├── database/
│   │   │   ├── base.py               # Declarative base + TimestampMixin
│   │   │   ├── session.py            # Async engine + session factory
│   │   │   └── models/               # SQLAlchemy ORM models
│   │   ├── repositories/             # Concrete repository implementations
│   │   ├── external/
│   │   │   ├── cloudinary_client.py  # Upload/delete + URL parsing
│   │   │   ├── firebase_admin.py     # SDK bootstrap
│   │   │   ├── push_service.py       # FCM delivery
│   │   │   └── image_validator.py    # Magic-byte validation
│   │   └── jobs/
│   │       ├── scheduler.py          # APScheduler setup
│   │       └── cleanup_jobs.py       # 5 periodic cleanup tasks
│   └── presentation/
│       ├── api/v1/routers/           # Mobile REST API (JSON)
│       │   ├── __init__.py
│       │   ├── auth_router.py
│       │   ├── cases_router.py
│       │   ├── appointments_router.py
│       │   ├── notifications_router.py
│       │   ├── tools_router.py
│       │   ├── orders_router.py
│       │   └── admin_router.py
│       ├── middleware/
│       │   └── request_id.py         # X-Request-ID + duration logging
│       └── admin/                    # ★ Admin Panel (Jinja2 + Tailwind)
│           ├── __init__.py
│           ├── context.py            # Locale, theme, flash, helpers
│           ├── dependencies.py       # Session-based auth (get_current_admin)
│           ├── templates.py          # Jinja2Templates instance + filters
│           └── routers/
│               ├── __init__.py
│               ├── auth_router.py
│               ├── dashboard_router.py
│               ├── users_router.py
│               ├── doctors_router.py
│               ├── cases_router.py
│               └── profile_router.py
│
├── templates/                        # ★ Jinja2 Templates
│   ├── base.html
│   ├── layouts/
│   │   ├── admin.html
│   │   └── auth.html
│   ├── partials/
│   │   ├── _sidebar.html
│   │   ├── _mobile_sidebar.html
│   │   ├── _topbar.html
│   │   ├── _flash.html
│   │   ├── _pagination.html
│   │   └── _confirm_modal.html
│   ├── components/
│   │   └── empty_state.html
│   ├── errors/
│   │   ├── 404.html
│   │   └── 500.html
│   └── pages/
│       ├── auth/login.html
│       ├── dashboard/index.html
│       ├── users/
│       │   ├── list.html
│       │   └── detail.html
│       ├── doctors/
│       │   ├── list.html
│       │   ├── create.html
│       │   └── detail.html
│       ├── cases/
│       │   ├── list.html
│       │   └── detail.html
│       └── profile/index.html
│
├── static/                           # ★ Static Assets
│   ├── css/
│   │   ├── input.css
│   │   └── app.css                   # Compiled (gitignored)
│   ├── js/
│   │   └── animations.js
│   └── uploads/
│       └── avatars/
│
├── alembic/
├── tests/
│   ├── conftest.py
│   ├── unit/
│   ├── integration/
│   └── helpers/
│
├── package.json
├── tailwind.config.js
├── postcss.config.js
├── requirements.txt
├── pytest.ini
├── alembic.ini
├── .env.example
└── README.md
```

---

## Getting Started

### 1. Prerequisites

- **Python 3.11+**
- **Node.js 18+** (only for building the Tailwind CSS)
- **PostgreSQL 15+** (running locally)
- A **Cloudinary** account (free tier works)
- A **Firebase** project with a service account key (optional — only for push)
- A **Gmail** account with an **App Password** (optional — only for outbound email)

### 2. Clone and create virtual environment

```bash
git clone <repo-url>
cd DENTSPACE2/BackEnd
python -m venv venv

# Windows
venv\Scripts\activate

# Linux / macOS
source venv/bin/activate
```

### 3. Install Python dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Install Node dependencies (for Tailwind)

```bash
npm install
```

### 5. Create the databases

```sql
CREATE DATABASE dent_space;
CREATE DATABASE dent_space_test;
```

### 6. Configure environment

```bash
cp .env.example .env
# then edit .env — every field below is required
```

**Minimum `.env`:**

```env
# ─── App ─────────────────────────────────────────────
APP_NAME=DentSpace API
APP_ENV=development
DEBUG=True
API_V1_PREFIX=/api/v1

# ─── Security (API JWT) ──────────────────────────────
SECRET_KEY=<at-least-32-random-chars>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30

# ─── Admin Panel Session ─────────────────────────────
SESSION_SECRET=<another-32+-random-chars>
ADMIN_SESSION_MAX_AGE=28800

# ─── Database ────────────────────────────────────────
DATABASE_URL=postgresql+asyncpg://postgres:admin@localhost:5432/dent_space
DATABASE_URL_SYNC=postgresql://postgres:admin@localhost:5432/dent_space

# ─── Cloudinary ──────────────────────────────────────
CLOUDINARY_CLOUD_NAME=<your-cloud-name>
CLOUDINARY_API_KEY=<your-api-key>
CLOUDINARY_API_SECRET=<your-api-secret>
CLOUDINARY_UPLOAD_PRESET=<your-preset>

# ─── Firebase (only needed for push) ─────────────────
FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json

# ─── SMTP (only needed for outbound OTP emails) ──────
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=<your-gmail>
SMTP_PASSWORD=<your-app-password>
SMTP_FROM_NAME=DentSpace
OTP_EXPIRE_MINUTES=10
MAX_OTP_ATTEMPTS=5

# ─── CORS ────────────────────────────────────────────
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# ─── Rate limiting ───────────────────────────────────
RATE_LIMIT_ENABLED=True
RATE_LIMIT_DEFAULT=120/minute
RATE_LIMIT_AUTH=10/minute
```

**Important:** `.env` and `firebase-credentials.json` must never be committed. They are already listed in `.gitignore`.

### 7. Run migrations

```bash
alembic upgrade head
```

### 8. Bootstrap the first admin (CLI)

```bash
python -m app.scripts.create_admin
```

The script prompts for name, email, phone, and password, then creates an `admin` account. Subsequent doctors are created through the admin panel at `/admin/doctors/new` or via `POST /api/v1/auth/admin/create-doctor`.

### 9. Build the admin CSS

```bash
# One-time build
npm run build

# Watch mode (rebuild on changes)
npm run dev
```

### 10. Run the server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open **http://127.0.0.1:8000/docs** for the interactive Swagger UI, or **http://127.0.0.1:8000/admin/login** for the admin panel.

**Startup log should show:**

```text
INFO  ... Firebase Admin initialised (firebase-credentials.json)
INFO  ... Scheduler started with 5 jobs: [...]
INFO  ... Rate-limiter cleanup task started.
INFO:     Application startup complete.
```

---

## Admin Panel — Detailed Guide

### Access

| URL | Description |
|---|---|
| `http://localhost:8000/admin` | Redirects to `/admin/dashboard` |
| `http://localhost:8000/admin/login` | Login page (session cookie) |
| `http://localhost:8000/admin/dashboard` | Main dashboard |

Only users with `role == 'admin'` can authenticate. Doctors and patients attempting to log in are silently redirected to `/admin/login` with an error toast.

### Session Model

- **Storage**: signed cookie via `itsdangerous` (through Starlette's `SessionMiddleware`).
- **Cookie name**: `dentspace_admin_session`.
- **TTL**: 8 hours (`ADMIN_SESSION_MAX_AGE`).
- **Attributes**: `HTTP-only`, `SameSite=Lax`, `Secure` in production.
- **Invalidation**: `POST /admin/logout` clears the session.

Server-side validation on each request fetches the user from the DB and re-verifies `role == ADMIN` and `is_active == True`.

### Routes

| Method | Path | Purpose |
|---|---|---|
| GET | `/admin` | Redirect → dashboard |
| GET | `/admin/login` | Login page |
| POST | `/admin/login` | Authenticate, set session cookie |
| POST | `/admin/logout` | Clear session |
| GET | `/admin/dashboard` | KPIs + charts |
| GET | `/admin/users` | Users list (filterable) |
| GET | `/admin/users/{id}` | User detail |
| POST | `/admin/users/{id}/toggle` | Enable / disable account |
| POST | `/admin/users/{id}/reset-password` | Set new password |
| POST | `/admin/users/{id}/delete` | Delete user (self-lockout protected) |
| GET | `/admin/doctors` | Doctors list (searchable) |
| GET | `/admin/doctors/new` | Create doctor form |
| POST | `/admin/doctors/new` | Submit new doctor |
| GET | `/admin/doctors/{id}` | Doctor detail |
| GET | `/admin/cases` | Cases list (filterable by status) |
| GET | `/admin/cases/{id}` | Case detail + review form |
| POST | `/admin/cases/{id}/verify` | Approve or reject a completed case |
| GET | `/admin/profile` | Admin profile |
| POST | `/admin/profile` | Update profile |
| POST | `/admin/profile/avatar` | Upload avatar |

### Design System

All colors are declared as **CSS custom properties** in `static/css/input.css` and mirrored in `tailwind.config.js`. They match `FrontEnd/lib/core/theme/app_colors.dart` so the mobile app and the admin panel stay visually aligned.

**Brand tokens**

| Token | Light | Dark |
|---|---|---|
| `--color-primary` | `#0D6EFD` | `#4D94FF` |
| `--color-primary-dark` | `#0A58CA` | — |
| `--color-secondary` | `#14B8A6` | — |
| `--color-success` | `#10B981` | — |
| `--color-warning` | `#F59E0B` | — |
| `--color-error` | `#EF4444` | — |
| `--color-bg` | `#F8FAFC` | `#0B1220` |
| `--color-surface` | `#FFFFFF` | `#111A2C` |
| `--color-surface-variant` | `#F1F5F9` | `#1A2540` |
| `--color-border` | `#E2E8F0` | `#1E293B` |

**Component classes** (defined in `input.css` under `@layer components`):

`.btn`, `.btn-primary`, `.btn-outline`, `.btn-ghost`, `.btn-danger`, `.card`, `.card-hover`, `.input`, `.badge`, `.badge-success`, `.badge-warning`, `.badge-danger`, `.badge-info`, `.badge-neutral`, `.toast`.

### Locale & Theme

| Concern | Storage | Default | Toggle |
|---|---|---|---|
| Locale | Cookie `dentspace_locale` (`ar` \| `en`) | `ar` | Topbar button (`data-lang-switch`) |
| Theme | `localStorage` + cookie `dentspace_theme` (`light` \| `dark`) | light | Topbar button (`data-theme-toggle`) |

Both toggles are **pure client-side** — no server round trip on theme change, one page reload on locale change.

**FOUC prevention:** an inline script in `<head>` reads `localStorage` before paint and adds `.dark` to `<html>` synchronously.

**RTL:** `<html dir="rtl">` when `locale == 'ar'`. All spacing uses logical properties (`ms-*`, `me-*`, `ps-*`, `pe-*`, `start-*`, `end-*`) so mirroring is automatic.

### Client-side JS (`static/js/animations.js`)

Small, dependency-free, ~200 lines. Responsibilities:

1. **Count-up** — animates `[data-count-to]` elements on the dashboard.
2. **Toast notifications** — reads a `<script id="flash-data">` JSON blob rendered by `base.html`, and exposes `window.showToast(msg, kind)`.
3. **Mobile sidebar** — opens/closes the drawer via `[data-mobile-menu-open]` and `[data-mobile-menu-close]`, with ESC + overlay click.
4. **Confirm modal** — intercepts `<form data-confirm="...">` submissions, shows a shared `<dialog>`, submits on confirm.
5. **Loading states** — disables the submit button and shows a spinner on any form submission that isn't awaiting confirm.
6. **Page title fallback** — fills `#page-title` from `document.title` if the server didn't provide one.

Respects `prefers-reduced-motion` — all animations skipped when the OS setting is on.

### Extending the Panel

To add a new admin page:

1. Create `app/presentation/admin/routers/<feature>_router.py` with the routes.
2. Register it in `app/presentation/admin/routers/__init__.py`.
3. Create `templates/pages/<feature>/<page>.html` extending `layouts/admin.html`.
4. Add a link to `templates/partials/_sidebar.html` and `_mobile_sidebar.html`.
5. Run `npm run dev` if you added new Tailwind classes.

---

## Running Tests

### Full suite

```bash
python -m pytest
```

### Unit tests only (fast, no DB)

```bash
python -m pytest tests/unit -v
```

### Integration tests only (needs `dent_space_test`)

```bash
python -m pytest tests/integration -v
```

### With coverage

```bash
pip install pytest-cov
python -m pytest --cov=app --cov-report=term-missing
```

### Test layout

| Layer | What it covers | Count |
|---|---|---|
| `tests/unit/test_password_validator.py` | Password policy edge cases | 12 |
| `tests/unit/test_symptom_analyzer.py` | Diagnostic engine — CF math, pivotal gating, contradictions, red flags, context | 28 |
| `tests/integration/test_auth_flow.py` | Register → OTP → login → refresh → logout-all → profile → admin-creates-doctor | 17 |
| `tests/integration/test_cases_flow.py` | Preview, CRUD, business rules, doctor view | 12 |

**External services** (Cloudinary, FCM, SMTP) are **mocked** in `tests/conftest.py`, so the suite runs offline.

---

## API Reference

All endpoints are prefixed with `/api/v1`.

### Authentication — `/auth`

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/register` | — | Register a patient; sends OTP by email |
| POST | `/verify-email` | — | Verify email with OTP, returns tokens |
| POST | `/resend-otp` | — | Resend verification OTP |
| POST | `/login` | — | Login, returns access and refresh tokens |
| POST | `/refresh` | — | Exchange refresh token for a new access token |
| POST | `/forgot-password` | — | Request password-reset OTP |
| POST | `/reset-password` | — | Reset password using OTP |
| GET | `/me` | Yes | Current user's profile |
| PATCH | `/me` | Yes | Update name / phone / gender / age |
| PATCH | `/me/fcm-token` | Yes | Register FCM token |
| POST | `/me/avatar` | Yes | Upload or replace avatar |
| DELETE | `/me/avatar` | Yes | Delete avatar |
| POST | `/logout-all` | Yes | Invalidate every active session |
| POST | `/admin/create-doctor` | Admin | Create a doctor account |

### Patient Cases — `/cases`

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/preview` | Yes | Differential diagnosis (no DB write) |
| POST | `/` | Patient | Create a case |
| GET | `/` | Yes | Role-aware list |
| GET | `/{id}` | Yes | Case detail |
| PATCH | `/{id}` | Owner | Update a pending case |
| DELETE | `/{id}` | Owner | Delete a pending case (cascades images) |
| POST | `/{id}/complete` | Doctor | Mark treatment complete |
| POST | `/{id}/images` | Owner | Upload one image |
| DELETE | `/{id}/images/{index}` | Owner | Remove one image |

### Appointments — `/appointments`

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/` | Doctor | Create a request |
| GET | `/` | Yes | List (role-aware) |
| GET | `/{id}` | Yes | Detail |
| POST | `/{id}/approve` | Patient | Approve a pending request |
| POST | `/{id}/reject` | Patient | Reject a pending request |
| DELETE | `/{id}` | Yes | Cancel |

### Notifications — `/notifications`

| Method | Path | Description |
|---|---|---|
| GET | `/` | List my notifications (with unread count) |
| POST | `/{id}/read` | Mark one as read |
| POST | `/read-all` | Mark all as read |
| DELETE | `/{id}` | Delete one |
| DELETE | `/` | Delete all read |

### Tools — `/tools`

| Method | Path | Description |
|---|---|---|
| POST | `/` | Create a tool listing |
| GET | `/` | Browse available tools (searchable) |
| GET | `/{id}` | Tool detail |
| PATCH | `/{id}` | Update (owner) |
| DELETE | `/{id}` | Delete (owner, no active orders) |
| POST | `/{id}/images` | Upload image |
| DELETE | `/{id}/images/{index}` | Remove image |

### Orders — `/orders`

| Method | Path | Description |
|---|---|---|
| POST | `/` | Create a purchase order |
| GET | `/` | List (`?role=seller` or `?role=buyer`) |
| GET | `/{id}` | Order detail |
| POST | `/{id}/approve` | Seller approves |
| POST | `/{id}/reject` | Seller rejects |
| POST | `/{id}/complete` | Seller marks as sold |
| DELETE | `/{id}` | Either party cancels |

### Admin (JSON API) — `/admin` (all require `admin` role)

| Method | Path | Description |
|---|---|---|
| GET | `/users` | List users (filterable by role / active / search) |
| PATCH | `/users/{id}/active` | Enable / disable a user |
| GET | `/cases` | List cases for review |
| POST | `/cases/{id}/verify` | Approve or reject a completed case |
| GET | `/stats` | Dashboard counts |

### Health — root

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Liveness — returns 200 if the process is up |
| GET | `/health/ready` | Readiness — returns 200 if the DB is reachable |

---

## Business Rules

| Rule | Where enforced |
|---|---|
| Max **3 pending cases** per patient | `CaseService.create_case` |
| Max **5 images** per case; max **5 MB** per image | `CaseService.add_image` |
| Max **3 active appointments** per patient | `AppointmentService` |
| Max **3 active appointments** per doctor | `AppointmentService` |
| **One pending request per (doctor, case)** | `AppointmentService.create` |
| Approving an appointment **auto-rejects** competitors | `AppointmentService.approve` |
| **Completed cases cannot be edited/deleted** | `CaseService` |
| Max **5 available tools** per seller | `ToolService.create_tool` |
| Max **5 active orders** per buyer | `OrderService.create_order` |
| **One active order per (buyer, tool)** | `OrderService.create_order` |
| Approving an order **auto-rejects** competitors | `OrderService.approve` |
| Only **completed cases** can be verified by admin | `AdminService.verify_case` |
| Admins **cannot disable their own** account | `AdminService.toggle_user_active` |
| The **last active admin** cannot be disabled | `AdminService.toggle_user_active` |
| Admins **cannot delete their own** account | `users_router.delete_user` |

---

## Security

| Concern | Mitigation |
|---|---|
| **Password storage** | bcrypt via passlib |
| **Password policy** | Min 12 chars, letter + digit, blacklist, no single-char repeats |
| **OTP brute-force** | 5 attempts then the code is invalidated |
| **OTP storage** | Short-lived, single-use, 10-min TTL, cleaned up daily |
| **JWT revocation** | `password_changed_at` timestamp; tokens older than that are rejected |
| **Session revocation** | `POST /auth/logout-all` |
| **Enumeration (API)** | `forgot-password` always returns success |
| **Enumeration (Admin UI)** | Login error message is generic for both cases |
| **Rate limiting** | slowapi on every sensitive endpoint |
| **Image type spoofing** | Magic-byte validation ignores the client's `Content-Type` |
| **Concurrent approvals** | `SELECT ... FOR UPDATE` on appointment/order/case rows |
| **SQL injection** | Parameterised queries only (SQLAlchemy) |
| **XSS (admin UI)** | Jinja2 auto-escaping; `textContent` in JS, never `innerHTML` with user data |
| **CSRF (admin UI)** | Session cookie is `SameSite=Lax`; destructive actions require POST forms |
| **Admin session forgery** | Cookie is signed with `SESSION_SECRET` via itsdangerous |
| **CORS** | Restricted via `ALLOWED_ORIGINS` |
| **Secrets** | Loaded from `.env`; never hard-coded |
| **Upload size** | Avatar upload rejected if > 5 MB; image MIME type whitelisted |

---

## Background Jobs

APScheduler runs five jobs **once a day** at quiet hours (UTC):

| Time | Job | Retention |
|---|---|---|
| 03:00 | Read notifications | > 7 days |
| 03:15 | Cancelled/rejected appointments | > 30 days |
| 03:30 | Used/expired OTPs | > 24 hours |
| 03:45 | Cancelled/rejected orders | > 30 days |
| 03:50 | Unread notifications | > 90 days |

Jobs never crash the scheduler — they log and continue.

Additionally, an in-process task clears slowapi's in-memory rate-limit buckets every 6 hours to prevent unbounded growth.

---

## External Services

| Service | Purpose | Failure mode |
|---|---|---|
| **Cloudinary** | Avatar, case, and tool images | Upload raises `400`; delete is best-effort |
| **Firebase FCM** | Push notifications | Best-effort; stale tokens are cleared |
| **Gmail SMTP** | OTP delivery | Best-effort; OTP still recorded in DB |

Every outbound call is wrapped so a remote failure **never** breaks the request.

---

## Deployment Checklist

### Application
- [ ] Set `APP_ENV=production` and `DEBUG=False`.
- [ ] Use a strong, randomly generated `SECRET_KEY` (≥ 32 chars).
- [ ] Use a strong, randomly generated `SESSION_SECRET` (≥ 32 chars).
- [ ] Restrict `ALLOWED_ORIGINS` to your real front-end origins.
- [ ] Run `npm run build` once on the deploy machine (or commit `app.css`).
- [ ] Ensure `static/uploads/avatars/` is writable by the process user.

### Infrastructure
- [ ] Serve behind **Nginx** with HTTPS (Let's Encrypt).
- [ ] Add **security headers** (HSTS, X-Frame-Options, X-Content-Type-Options).
- [ ] Configure a **process manager** (systemd, supervisord, or gunicorn+uvicorn workers).
- [ ] Set up **daily database backups** (`pg_dump` → off-site storage).
- [ ] Configure **log shipping** (e.g. to a centralised log store).
- [ ] Install **Sentry** for error tracking (`SENTRY_DSN`).
- [ ] Monitor `/health/ready` with an uptime service.
- [ ] Replace the in-memory rate limiter with **Redis** if running multiple workers.
- [ ] Serve `/static/*` directly from Nginx (bypass FastAPI for performance).

### Admin Panel Specifics
- [ ] Verify `SESSION_SECRET` differs from `SECRET_KEY`.
- [ ] Confirm the session cookie has `Secure` set (requires HTTPS in prod).
- [ ] Test the mobile drawer on a real device at 375 px width.
- [ ] Verify avatar uploads persist across restarts (mount volume or use S3).

---

## Development Workflow

### Adding a new API endpoint

1. Add the **request/response DTO** in `app/application/dtos/`.
2. Add the **business logic** in `app/application/services/`.
3. If persistence is needed:
   - Add a method to the **repository interface** in `app/domain/repositories/`.
   - Implement it in `app/infrastructure/repositories/`.
4. Add the **router** in `app/presentation/api/v1/routers/`.
5. Register the router in `routers/__init__.py`.
6. Write **unit and/or integration tests**.

### Adding a new admin page

1. Create a router in `app/presentation/admin/routers/`.
2. Register it in `app/presentation/admin/routers/__init__.py`.
3. Create the template in `templates/pages/<feature>/`.
4. Add the route to `_sidebar.html` and `_mobile_sidebar.html`.
5. Run `npm run dev` while styling.

### Adding a migration

```bash
alembic revision --autogenerate -m "short description"
alembic upgrade head
```

Always inspect the generated file before applying — Alembic sometimes misses enum changes or composite indexes.

### Tailwind workflow

- Edit `static/css/input.css` for design tokens and component classes.
- Use utility classes directly in Jinja templates.
- `npm run dev` watches `templates/**/*.html` and rebuilds `app.css`.
- `npm run build` produces a minified build for production.

---

## Contributing

1. Branch from `main`: `git checkout -b feature/<name>`.
2. Follow **Clean Architecture** layering — no domain → framework imports.
3. Keep functions small; prefer composition over inheritance.
4. Run the full test suite before pushing:

   ```bash
   python -m pytest
   ```

5. If you changed CSS, run `npm run build` and commit the updated `app.css` (or ensure your CI rebuilds it).
6. Open a Pull Request with a clear description and screenshots if UI-related.

---

## License

This project is developed as part of an academic graduation requirement. All rights reserved by the authors. Not licensed for commercial use without explicit written permission.

---

## Team

| Role | Name |
|---|---|
| Backend & API | TBD |
| Database Design | TBD |
| Frontend (Flutter) | TBD |
| Admin Console (Jinja + Tailwind) | TBD |
| Supervision | Faculty of Dentistry |

---

**Built with care for supervised dental training.**