$ErrorActionPreference = "Stop"

Write-Host "Git:"
git --version
Write-Host ""

Write-Host "Node:"
node --version
Write-Host "npm:"
npm --version
Write-Host ""

Write-Host "Flutter:"
flutter --version
Write-Host ""

Write-Host "Docker:"
docker --version
docker compose version
Write-Host ""

Write-Host "Ollama:"
ollama --version
