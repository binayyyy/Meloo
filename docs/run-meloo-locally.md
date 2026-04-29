# Run Meloo Locally

This repo has three main surfaces:

- `apps/api`: NestJS API
- `apps/admin`: Next.js internal admin console
- `apps/mobile`: Flutter app for public roles, intended for mobile or desktop QA targets

## Fastest Graphical Flow

Open three terminals from the repo root.

Terminal 1:

```bash
npm run dev:api
```

Terminal 2:

```bash
npm run dev:admin
```

Terminal 3:

```bash
cd apps/mobile
flutter run -d linux --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

After startup:

- API: `http://127.0.0.1:3000/api`
- Admin: `http://127.0.0.1:3001`
- Mobile app: Flutter window on the selected target

Notes:

- The admin console is desktop-only.
- The public app is mobile-only at runtime, so native Android/iOS targets are preferred when available.
- Linux desktop is acceptable for local QA when no phone or emulator is connected.

## Docker Option

If you only need the API and admin console:

```bash
docker compose up --build
```

That brings up:

- API: `http://localhost:3000/api`
- Admin: `http://localhost:3001`
- Uploads: `http://localhost:3000/uploads/...`

## Seeded Local Accounts

Seeded local accounts use:

- `admin@meloo.local`
- `organizer@meloo.local`
- `vendor@meloo.local`
- `sponsor@meloo.local`
- `attendee@meloo.local`

Default password:

```text
Password123!
```

If you want a clean seeded state:

```bash
npm run db:reset:demo
npm run seed:demo
```

## Distance-Based Vendor Matching

Vendor ranking is no longer city-label only.

- Events can store `latitude`, `longitude`, and `vendor match radius`
- Vendor profiles can store a base `latitude`, `longitude`, and `travel radius`
- Organizer/admin vendor discovery uses those coordinates to sort vendors by real distance

To see it working in the UI:

1. Create or seed an organizer event and tap the map to place the event location.
2. Create or edit a vendor profile and tap the map to place the vendor base location.
3. Adjust the radius with the slider instead of typing it manually.
4. Reload the organizer/admin home view and check the vendor market cards.

## Local AI

- AI assist is a per-user setting.
- Chat drafting is available across roles when AI assist is enabled for that account.
- Organizer planning and admin support triage run through the local AI harness as well.
- Default local model wiring targets Ollama.

## Brand Assets

Current Meloo assets live at:

- `apps/admin/public/branding/meloo-logo-v1.png`
- `apps/admin/public/branding/meloo-mark-v1.png`
- `apps/mobile/assets/branding/meloo-logo-v1.png`
- `apps/mobile/assets/branding/meloo-mark-v1.png`
