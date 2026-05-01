# Meloo

Meloo is a cross-platform event management product with three app surfaces:

- `apps/api`: NestJS API
- `apps/admin`: Next.js internal admin console
- `apps/mobile`: Flutter app for attendee, organizer, vendor, and sponsor roles

The admin is internal-only and web-only. The public roles are designed for mobile-first use, with desktop and Flutter web mainly useful for local QA.

## Features

- Role-based public app flows for `attendee`, `organizer`, `vendor`, and `sponsor`
- Internal admin console for moderation, trust review, and operational support
- Event creation, ticketing, registration, and payment flows
- Profile media uploads for avatars, event covers, sponsor logos, vendor portfolio, and documents
- AI-assisted chat drafting, organizer planning help, and admin support triage
- Distance-aware vendor matching using event and vendor coordinates

## Tech Stack

- API: NestJS 11, TypeORM, PostgreSQL
- Admin: Next.js 15, React 19
- Mobile: Flutter 3.24+, Dart 3.4+
- Database: PostgreSQL 16 with PostGIS-ready Docker image
- AI: Ollama by default for local runs
- Payments: Stripe integration, optional in local development

## Repository Layout

```text
apps/
  admin/    Next.js internal admin console
  api/      NestJS backend
  mobile/   Flutter public-role app
docs/
tools/
compose.yaml
compose.ai.yaml
Dockerfile.api
Dockerfile.admin
```

## Prerequisites

For a full local setup outside Docker:

- Node.js 20+
- npm 10+
- Flutter SDK 3.24+
- A working Chrome install for Flutter web QA, or Android/iOS/Linux targets
- PostgreSQL 16+ if you are not using Docker for the database
- Ollama if you want local AI features enabled

Useful checks:

```bash
node --version
npm --version
flutter --version
docker --version
ollama --version
```

## Environment

Create a local env file:

```bash
cp .env.example .env
```

Important environment values from `.env.example`:

- `PORT=3000`: API port
- `API_PREFIX=api`: API route prefix
- `CORS_ORIGIN=*`: CORS origin for API
- `ADMIN_PORT=3001`: admin web port
- `NEXT_PUBLIC_API_BASE_URL=http://127.0.0.1:3000/api`: admin API base URL
- `PUBLIC_API_BASE_URL=http://127.0.0.1:3000`: public base URL used for uploaded assets
- `LOCAL_SETUP_KEY=change-this-local-setup-key`: local bootstrap/seed helper key
- `UPLOADS_DIR=/home/dav/smart-event/.tooling/uploads`: upload storage path
- `DB_TYPE=postgres`: database driver
- `DB_HOST=127.0.0.1`
- `DB_PORT=5432`
- `DB_NAME=meloo`
- `DB_USERNAME=meloo`
- `DB_PASSWORD=meloo`
- `DB_SYNCHRONIZE=true`: schema sync for local development
- `STRIPE_SECRET_KEY=`: leave blank if you do not need paid checkout locally
- `STRIPE_WEBHOOK_SECRET=`
- `STRIPE_CURRENCY=usd`
- `PAYMENT_RETURN_URL=http://127.0.0.1:8081`
- `AI_ENABLED=true`
- `AI_PROVIDER=ollama`
- `AI_BASE_URL=http://127.0.0.1:11434`
- `AI_MODEL=llama3.2:latest`

## Install Dependencies

From the repo root:

```bash
npm install
cd apps/api && npm install
cd ../admin && npm install
cd ../mobile && flutter pub get
```

## Run With Docker

The Docker setup is split the right way:

- `compose.yaml`: core stack with Postgres, API, and admin
- `compose.ai.yaml`: optional Ollama overlay for AI features
- `seed` profile: optional one-shot demo data loader

The Flutter app is not containerized. Keep it outside Docker for dev and QA.

### Base Stack

Start the core services:

```bash
docker compose up --build
```

This starts:

- `db`: PostGIS-ready PostgreSQL on `localhost:5432`
- `api`: NestJS API on `http://localhost:3000/api`
- `admin`: Next.js admin on `http://localhost:3001`

Uploads are served from:

- `http://localhost:3000/uploads/...`

### Seed Demo Data

Run the one-shot seed profile when you want demo users and sample activity:

```bash
docker compose --profile seed up seed
```

This writes demo output to the `smart_event_demo` volume and seeds:

- admin
- organizer
- vendor
- sponsor
- attendee

### Enable AI In Docker

Start the stack with the Ollama overlay:

```bash
docker compose -f compose.yaml -f compose.ai.yaml up --build
```

This adds:

- `ollama`: local AI runtime on `localhost:11434`

If you also want seeded demo data at the same time:

```bash
docker compose -f compose.yaml -f compose.ai.yaml --profile seed up --build
```

Docker notes:

- The app stack is multi-container by design. Do not try to bundle Postgres, API, admin, and AI model weights into one image.
- AI is disabled in `compose.yaml` by default and only enabled through `compose.ai.yaml`.
- Stripe is still optional and disabled unless you provide keys.
- Uploaded files are stored in the `smart_event_uploads` Docker volume.
- PostgreSQL data is stored in the `meloo_postgres` Docker volume.
- Ollama models are stored in the `ollama_data` volume when the AI overlay is used.

Reset the Docker state:

```bash
docker compose down -v
```

If you used the AI overlay:

```bash
docker compose -f compose.yaml -f compose.ai.yaml down -v
```

## Run Locally Without Docker

### 1. Start PostgreSQL

Use your local Postgres instance and make sure the database from `.env` exists.

Default local values expect:

- host: `127.0.0.1`
- port: `5432`
- database: `meloo`
- username: `meloo`
- password: `meloo`

If you prefer Docker just for the database:

```bash
docker compose up db
```

### 2. Start Ollama for AI (optional)

If `AI_ENABLED=true`, make sure Ollama is running and the configured model is available:

```bash
ollama serve
ollama pull llama3.2:latest
```

You can verify AI connectivity with:

```bash
npm run check:ai
```

If you do not want AI locally, set:

```bash
AI_ENABLED=false
```

### 3. Start the API

From the repo root:

```bash
npm run dev:api
```

The API will be available at:

- `http://127.0.0.1:3000/api`

Uploads will be available at:

- `http://127.0.0.1:3000/uploads/...`

### 4. Seed Demo Data

From the repo root:

```bash
npm run seed:demo
```

If you want a clean local reseed:

```bash
npm run db:reset:demo
npm run seed:demo
```

### 5. Start the Admin Console

From the repo root:

```bash
npm run dev:admin
```

Open:

- `http://127.0.0.1:3001`

### 6. Start the Flutter App

From `apps/mobile`:

Linux desktop QA:

```bash
flutter run -d linux --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

Flutter web QA in Chrome:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

Android/iOS:

```bash
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

Notes:

- The admin is web-only and should stay separate from the public-role app.
- Flutter web is acceptable for QA, but the public app is still designed as a mobile-first experience.
- Uploaded media now depends on `PUBLIC_API_BASE_URL` or the request host, so keep the API origin correct when testing on other devices.

## Seeded Accounts

After running the seed:

- `admin@meloo.local`
- `organizer@meloo.local`
- `vendor@meloo.local`
- `sponsor@meloo.local`
- `attendee@meloo.local`

Password for all:

```text
Password123!
```

## Local Service Matrix

If you want the whole product working locally, these are the moving parts:

- PostgreSQL: required for the main API data store
- API: required by admin and mobile
- Upload storage: local filesystem path at `UPLOADS_DIR`
- Admin web app: optional unless testing internal operations
- Flutter app: required for public-role flows
- Ollama: optional, but required for local AI features
- Stripe: optional, but required for real paid checkout behavior

## Docker Images

The Docker approach in this repo intentionally separates concerns:

- API image: NestJS runtime only
- Admin image: Next.js standalone runtime only
- Database container: PostgreSQL/PostGIS
- Optional Ollama container: AI runtime and model storage

That keeps the app images reasonably sized and avoids shipping AI model weights inside the application containers.

## AI Features

When AI is enabled and the AI provider is reachable, Meloo can power:

- chat reply drafts across roles
- organizer planning assistance
- admin support ticket triage

Default local AI configuration targets:

- provider: `ollama`
- base URL: `http://127.0.0.1:11434`
- model: `llama3.2:latest`

## Payments

Stripe is optional in local development.

Without Stripe keys:

- free registrations still work
- paid checkout flows are not fully active

To enable Stripe locally, set:

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_CURRENCY`
- `PAYMENT_RETURN_URL`

## Media Uploads

Meloo supports upload flows for:

- user avatars
- event cover photos
- vendor portfolio images
- vendor verification documents
- sponsor logos
- sponsor verification documents

Local upload behavior:

- files are written under `UPLOADS_DIR`
- assets are served by the API under `/uploads/...`
- correct asset rendering depends on `PUBLIC_API_BASE_URL` being accurate if requests are not coming from the same host

## Useful Commands

Repo root:

```bash
npm run dev:api
npm run dev:admin
npm run seed:demo
npm run db:reset:demo
npm run check:ai
```

Mobile:

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

API:

```bash
cd apps/api
npm run build
```

Admin:

```bash
cd apps/admin
npm run dev
```

## Troubleshooting

If profile images or event cover images do not render:

- confirm the API is reachable from the device or browser you are using
- confirm `PUBLIC_API_BASE_URL` matches the API host you are actually serving from
- confirm the uploaded asset exists under `UPLOADS_DIR`

If Flutter web uploads fail:

- make sure the API is running
- make sure the browser can reach the API host directly
- check that the selected file type is supported

If the admin loads but cannot fetch data:

- confirm `NEXT_PUBLIC_API_BASE_URL` points at the running API
- confirm CORS is allowing the admin origin

If AI features do not respond:

- confirm `AI_ENABLED=true`
- confirm Ollama is running
- confirm the configured model is installed
- run `npm run check:ai`

## Additional Docs

- [LOCAL_DOCKER.md](LOCAL_DOCKER.md)
- [docs/run-meloo-locally.md](docs/run-meloo-locally.md)
