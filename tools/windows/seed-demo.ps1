$ErrorActionPreference = "Stop"

$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $PSScriptRoot "Load-DotEnv.ps1")

Set-Location $repoRoot
node tools/seed_demo.mjs
