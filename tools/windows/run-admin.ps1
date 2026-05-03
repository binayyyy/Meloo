$ErrorActionPreference = "Stop"

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $PSScriptRoot "Load-DotEnv.ps1")

$port = if ($env:ADMIN_PORT) { $env:ADMIN_PORT } else { "3001" }
if (-not $env:NEXT_PUBLIC_API_BASE_URL) {
  $env:NEXT_PUBLIC_API_BASE_URL = "http://127.0.0.1:3000/api"
}

Set-Location (Join-Path $repoRoot "apps/admin")
npm run dev -- --port $port
