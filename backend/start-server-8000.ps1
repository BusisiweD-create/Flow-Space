# Flow-Space Backend Server - Port 8000
# Quick startup script for development

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 Starting Backend Server on Port 8000" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location $PSScriptRoot

# Set environment variables
$env:PORT = "8000"
$env:NODE_ENV = "development"

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
    npm install
}

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  No .env file found. Using defaults." -ForegroundColor Yellow
}

# Stop any existing server on port 8000
Write-Host "🛑 Checking for existing servers..." -ForegroundColor Yellow
$existing = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($existing) {
    $pid = $existing.OwningProcess
    Write-Host "Stopping process $pid on port 8000..." -ForegroundColor Yellow
    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Start the server
Write-Host "🚀 Starting server..." -ForegroundColor Green
Write-Host "📍 Server will run on: http://localhost:8000" -ForegroundColor Cyan
Write-Host ""

try {
    node server.js
} catch {
    Write-Host ""
    Write-Host "❌ Error starting server: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure PostgreSQL is running" -ForegroundColor White
    Write-Host "2. Check database connection in server.js" -ForegroundColor White
    Write-Host "3. Verify Node.js is installed: node --version" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
}

