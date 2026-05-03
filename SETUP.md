# Meloo Windows Setup

This guide is for a fresh Windows laptop with nothing preinstalled.

It is the fastest supported setup path for this repo:
- database in Docker Desktop
- API on Windows
- admin on Windows
- AI with local Ollama
- mobile app in Chrome via Flutter web

Use **PowerShell** for every command below.

## 1. Install Software

Install these from a normal browser:

1. Git for Windows
- https://git-scm.com/install/windows.html

2. Node.js 20.x
- https://nodejs.org/download/release/latest-v20.x/
- download the Windows x64 `.msi`

3. Google Chrome
- https://support.google.com/chrome/answer/95346

4. Docker Desktop
- https://docs.docker.com/desktop/setup/install/windows-install/

5. Ollama for Windows
- https://docs.ollama.com/windows

6. Flutter SDK
- https://docs.flutter.dev/install/manual
- extract to `C:\src\flutter`

Optional:
- VS Code: https://code.visualstudio.com/
- Visual Studio C++ tools if you want native Windows Flutter later:
  https://docs.flutter.dev/platform-integration/windows/setup

## 2. Folder Layout

Create these folders:

```powershell
New-Item -ItemType Directory -Force C:\meloo
New-Item -ItemType Directory -Force C:\meloo\uploads
New-Item -ItemType Directory -Force C:\src
```

Use these final paths:
- project: `C:\meloo\Meloo`
- uploads: `C:\meloo\uploads`
- Flutter SDK: `C:\src\flutter`

## 3. Download The Repo

Download from GitHub:

- Repo: `https://github.com/binayyyy/Meloo`
- ZIP: `https://github.com/binayyyy/Meloo/archive/refs/heads/main.zip`

Extract to:

`C:\meloo\Meloo`

If the extracted folder is `Meloo-main`, rename it to `Meloo`.

## 4. Add Flutter To PATH

Add this to your Windows user `Path`:

```text
C:\src\flutter\bin
```

Then open a **new** PowerShell window.

## 5. Verify Installed Tools

Run:

```powershell
git --version
node --version
npm --version
flutter --version
docker --version
ollama --version
```

Enable Flutter web:

```powershell
flutter config --enable-web
flutter doctor
```

Chrome should be detected. Android/iOS warnings are okay.

## 6. Configure The Repo

Go to the repo:

```powershell
cd C:\meloo\Meloo
Copy-Item .env.example .env
notepad .env
```

Use these values:

```env
NODE_ENV=development
PORT=3000
API_PREFIX=api
CORS_ORIGIN=*
ADMIN_PORT=3001
NEXT_PUBLIC_API_BASE_URL=http://127.0.0.1:3000/api
PUBLIC_API_BASE_URL=http://127.0.0.1:3000
LOCAL_SETUP_KEY=change-this-local-setup-key
UPLOADS_DIR=C:/meloo/uploads

JWT_SECRET=replace-me-with-a-long-random-jwt-secret
ACCESS_TOKEN_TTL_SECONDS=900
REFRESH_TOKEN_TTL_SECONDS=2592000

DB_TYPE=postgres
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=meloo
DB_USERNAME=meloo
DB_PASSWORD=meloo
DB_SYNCHRONIZE=true

STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
STRIPE_CURRENCY=usd
PAYMENT_RETURN_URL=http://127.0.0.1:8081

AI_ENABLED=true
AI_PROVIDER=ollama
AI_BASE_URL=http://127.0.0.1:11434
AI_MODEL=llama3.2:latest
AI_API_KEY=
AI_TIMEOUT_MS=300000
```

## 7. Install Repo Dependencies

From the repo root:

```powershell
cd C:\meloo\Meloo
npm run win:install
```

This installs:
- root npm dependencies
- API dependencies
- admin dependencies
- Flutter mobile dependencies

## 8. Start Docker And Database

Open Docker Desktop manually and wait until it is fully running.

Then run:

```powershell
cd C:\meloo\Meloo
npm run win:db
```

Optional check:

```powershell
docker ps
```

## 9. Install The Local AI Model

Run:

```powershell
ollama pull llama3.2:latest
ollama list
```

If the laptop is weak, you can use:

```powershell
ollama pull llama3.2:1b
```

Then change `.env`:

```env
AI_MODEL=llama3.2:1b
```

## 10. Start The Services

Open separate PowerShell windows for each service.

### API

```powershell
cd C:\meloo\Meloo
npm run win:api
```

Expected:
- NestJS starts
- API at `http://127.0.0.1:3000/api`

### Admin

```powershell
cd C:\meloo\Meloo
npm run win:admin
```

Expected:
- Next.js dev server starts
- Admin at `http://127.0.0.1:3001`

### Seed Demo Data

```powershell
cd C:\meloo\Meloo
npm run win:seed
```

Expected:
- Nepal-specific synthetic data is seeded
- output written to:
  `C:\meloo\Meloo\.tooling\demo\demo-data.json`

### Verify AI End To End

```powershell
cd C:\meloo\Meloo
npm run win:ai
```

Expected:
- verifies local Ollama
- verifies recommendations, planning, drafting, and support triage

### Mobile Web App

```powershell
cd C:\meloo\Meloo
npm run win:mobile
```

Expected:
- Flutter launches in Chrome
- mobile app at `http://127.0.0.1:8081`

## 11. Main URLs

- Admin: `http://127.0.0.1:3001`
- API: `http://127.0.0.1:3000/api`
- Mobile web: `http://127.0.0.1:8081`
- Ollama API: `http://127.0.0.1:11434`

## 12. Seeded Accounts

All seeded accounts use:

```text
Password123!
```

Main accounts:
- `admin@meloo.local`
- `organizer@meloo.local`
- `vendor@meloo.local`
- `sponsor@meloo.local`
- `attendee@meloo.local`

Additional Nepal-specific accounts are listed in:

`C:\meloo\Meloo\.tooling\demo\demo-data.json`

## 13. Useful Commands

Environment/tool check:

```powershell
cd C:\meloo\Meloo
npm run win:doctor
```

Install dependencies:

```powershell
cd C:\meloo\Meloo
npm run win:install
```

Start DB:

```powershell
cd C:\meloo\Meloo
npm run win:db
```

Reset database volume:

```powershell
cd C:\meloo\Meloo
docker compose down -v
docker compose up -d db
```

## 14. If Something Fails

If Docker Desktop fails because WSL is missing, run PowerShell as Administrator:

```powershell
wsl --install
wsl --update
```

Then reboot.

If `flutter` is not recognized:
- recheck that `C:\src\flutter\bin` is in your `Path`
- close PowerShell and open a new one

If `ollama` is not recognized:
- close PowerShell and open a new one

If the AI is too slow:
- switch from `llama3.2:latest` to `llama3.2:1b`
- restart the API afterward

If you want a fully clean reseed:
1. stop the API
2. stop the admin app
3. run:

```powershell
cd C:\meloo\Meloo
docker compose down -v
docker compose up -d db
npm run win:api
```

Then in new windows:

```powershell
cd C:\meloo\Meloo
npm run win:seed
```

```powershell
cd C:\meloo\Meloo
npm run win:ai
```

## 15. Recommended Real Workflow

Do this once after installation:

```powershell
cd C:\meloo\Meloo
npm run win:doctor
npm run win:install
npm run win:db
```

Then open separate windows for:

```powershell
cd C:\meloo\Meloo
npm run win:api
```

```powershell
cd C:\meloo\Meloo
npm run win:admin
```

```powershell
cd C:\meloo\Meloo
npm run win:seed
```

```powershell
cd C:\meloo\Meloo
npm run win:ai
```

```powershell
cd C:\meloo\Meloo
npm run win:mobile
```
