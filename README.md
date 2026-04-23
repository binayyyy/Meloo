# Meloo

Meloo is a multi-surface event platform with:

- a NestJS API
- a Next.js admin client
- a Flutter app for attendee, organizer, vendor, sponsor, and admin flows

## Stack

- API: NestJS + TypeORM
- Admin: Next.js
- App: Flutter
- Database: PostgreSQL with PostGIS-ready Docker runtime

## Run With Docker

1. Copy `.env.example` to `.env` if you want local overrides.
2. Start the stack:

```bash
docker compose up --build
```

3. Open:

- Admin: `http://localhost:3001`
- API: `http://127.0.0.1:3000/api`

The compose setup starts PostgreSQL, the API, the admin client, and the demo seed job.

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

6. Start the Flutter app:

```bash
cd apps/mobile
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

## Demo Accounts

- `admin@meloo.local`
- `organizer@meloo.local`
- `vendor@meloo.local`
- `sponsor@meloo.local`
- `attendee@meloo.local`

Password:

- `Password123!`
