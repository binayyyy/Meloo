# Local Docker Run

For the full graphical local workflow, including Flutter web/mobile preview, see `docs/run-meloo-locally.md`.

This stack packages the API and admin console for local testing with seeded local data.

## Start

From the repo root:

```bash
docker compose up --build
```

The services come up at:

- API: `http://localhost:3000/api`
- Admin console: `http://localhost:3001`
- Uploaded assets: `http://localhost:3000/uploads/...`

## Demo Admin Login

Use the admin login form in the sidebar with:

- Email: `admin@meloo.local`
- Password: `Password123!`

The compose stack seeds organizer, vendor, sponsor, and attendee accounts too.

## Notes

- The API uses a local `sqljs` database stored in the `smart_event_demo` Docker volume.
- Uploaded files are stored in the `smart_event_uploads` Docker volume.
- To reset everything, run:

```bash
docker compose down -v
```

- Stripe is left disabled by default for local testing.
