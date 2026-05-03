$ErrorActionPreference = "Stop"

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $PSScriptRoot "Load-DotEnv.ps1")

$apiBaseUrl = if ($env:NEXT_PUBLIC_API_BASE_URL) {
  $env:NEXT_PUBLIC_API_BASE_URL
} else {
  "http://127.0.0.1:3000/api"
}

Set-Location (Join-Path $repoRoot "apps/mobile")
flutter run -d chrome --web-port 8081 --dart-define="API_BASE_URL=$apiBaseUrl"
