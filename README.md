# Meloo

Meloo is a multi-surface event platform with:

- a NestJS API
- a Next.js internal admin console
- a Flutter app for attendee, organizer, vendor, and sponsor workflows

## Stack

- API: NestJS + TypeORM
- Admin: Next.js
- App: Flutter
- Database: PostgreSQL with PostGIS-ready Docker runtime

## Product Model

- Admin is internal-only and intended for desktop use.
- Public roles are mobile-first: `attendee`, `organizer`, `vendor`, and `sponsor`.
- Chat drafting is AI-assisted and role-aware.
- Distance-aware matching uses map coordinates and radius controls for events and vendors.

## Run With Docker

1. Copy `.env.example` to `.env` if you want local overrides.
2. Start the stack:

```bash
docker compose up --build
```

3. Open:

- Admin: `http://localhost:3001`
- API: `http://127.0.0.1:3000/api`

The compose setup starts PostgreSQL, the API, the admin client, and the local seed job.

## Run Locally

1. Install dependencies:

```bash
npm install
cd apps/api && npm install
cd ../admin && npm install
cd ../mobile && flutter pub get
```

2. Create `.env` from `.env.example`.
3. Start PostgreSQL and make sure the database in `.env` exists.
4. Start the API:

```bash
npm run dev:api
```

5. Start the admin client:

```bash
npm run dev:admin
```

6. Start the Flutter app on a native target or desktop QA target:

```bash
cd apps/mobile
flutter run -d linux --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

Use `flutter devices` to pick an Android or iOS device when available. The public app is mobile-only at runtime and should not be treated as a web surface.

## Local AI

Meloo can run against a local Ollama model for:

- chat reply drafting across roles
- organizer planning assistance
- admin support triage

Default local wiring in `.env.example` targets Ollama on `http://127.0.0.1:11434`.

## Maps And Matching

- Events store location and vendor match radius.
- Vendor profiles store base location and travel radius.
- Organizer and admin discovery flows use coordinates and distance-aware ranking instead of city label matching alone.

## Seeded Local Accounts

- `admin@meloo.local`
- `organizer@meloo.local`
- `vendor@meloo.local`
- `sponsor@meloo.local`
- `attendee@meloo.local`

Password:

- `Password123!`
