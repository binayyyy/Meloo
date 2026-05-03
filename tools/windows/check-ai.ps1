$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent -Parent
. (Join-Path $PSScriptRoot "Load-DotEnv.ps1")

Set-Location $repoRoot
node tools/check_local_ai.mjs
