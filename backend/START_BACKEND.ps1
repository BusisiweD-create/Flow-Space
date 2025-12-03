# Flow-Space Backend Server Startup Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flow-Space Backend Server Startup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if already running
$portInUse = Test-NetConnection -ComputerName localhost -Port 8000 -InformationLevel Quiet
if ($portInUse) {
    Write-Host "⚠️  Port 8000 is already in use!" -ForegroundColor Yellow
    Write-Host "   The server may already be running." -ForegroundColor Yellow
    Write-Host "   Check: http://localhost:8000" -ForegroundColor Cyan
    Write-Host ""
    $response = Read-Host "Do you want to start anyway? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Exiting..." -ForegroundColor Yellow
        exit
    }
}

# Check PostgreSQL
Write-Host "📊 Checking PostgreSQL..." -ForegroundColor Cyan
$pgRunning = Get-Service -Name "*postgresql*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }
if ($pgRunning) {
    Write-Host "   ✅ PostgreSQL is running" -ForegroundColor Green
} else {
    Write-Host "   ❌ PostgreSQL is not running!" -ForegroundColor Red
    Write-Host "   Please start PostgreSQL and try again." -ForegroundColor Yellow
    exit 1
}

# Check dependencies
Write-Host "📦 Checking dependencies..." -ForegroundColor Cyan
if (Test-Path "node_modules") {
    Write-Host "   ✅ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Dependencies not found. Installing..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Failed to install dependencies!" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ✅ Dependencies installed" -ForegroundColor Green
}

# Start server
Write-Host ""
Write-Host "🚀 Starting server on http://localhost:8000..." -ForegroundColor Green
${env:PORT} = "8000"
Write-Host "   Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

node server.js

