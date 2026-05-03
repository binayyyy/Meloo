$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent -Parent
Set-Location $repoRoot

docker compose up -d db
