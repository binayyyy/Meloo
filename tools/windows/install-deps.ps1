$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent -Parent
Set-Location $repoRoot

Write-Host "Installing root npm dependencies..."
npm install

Write-Host "Installing API dependencies..."
Set-Location (Join-Path $repoRoot "apps/api")
npm install

Write-Host "Installing admin dependencies..."
Set-Location (Join-Path $repoRoot "apps/admin")
npm install

Write-Host "Installing Flutter dependencies..."
Set-Location (Join-Path $repoRoot "apps/mobile")
flutter pub get

Write-Host ""
Write-Host "Dependency installation complete."
