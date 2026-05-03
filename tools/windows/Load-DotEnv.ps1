param(
  [string]$EnvPath
)

if (-not $EnvPath) {
  $EnvPath = Join-Path (Split-Path $PSScriptRoot -Parent -Parent) ".env"
}

if (-not (Test-Path $EnvPath)) {
  throw "Missing .env file at $EnvPath"
}

Get-Content $EnvPath | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -match '^\s*$') {
    return
  }

  $parts = $_ -split '=', 2
  if ($parts.Length -ne 2) {
    return
  }

  $name = $parts[0].Trim()
  $value = $parts[1]
  [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
}
