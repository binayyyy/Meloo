# Local Docker Run

For the full graphical local workflow, including Flutter web/mobile preview, see `docs/run-meloo-locally.md`.

This stack packages the API and admin console for local testing.

## Start

From the repo root:

```bash
docker compose up --build
```

The services come up at:

- API: `http://localhost:3000/api`
- Admin console: `http://localhost:3001`
- Uploaded assets: `http://localhost:3000/uploads/...`

## Seed Demo Data

The demo seed is now an explicit profile:

```bash
docker compose --profile seed up seed
```

If you want AI enabled in Docker as well:

```bash
docker compose -f compose.yaml -f compose.ai.yaml up --build
```

## Demo Admin Login

Use the admin login form in the sidebar with:

- Email: `admin@meloo.local`
- Password: `Password123!`

The seed profile also creates organizer, vendor, sponsor, and attendee accounts.

## Notes

- The Docker stack uses PostgreSQL via the `db` service.
- The seed profile writes demo output to the `smart_event_demo` Docker volume.
- Uploaded files are stored in the `smart_event_uploads` Docker volume.
- AI is kept in a separate Ollama container via `compose.ai.yaml`.
- To reset everything, run:

```bash
docker compose down -v
```

- Stripe is left disabled by default for local testing.
