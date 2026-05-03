$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent -Parent
. (Join-Path $PSScriptRoot "Load-DotEnv.ps1")

Set-Location (Join-Path $repoRoot "apps/api")
npm run start
