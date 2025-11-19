# Flow-Space Backend Server Startup Script
# This script ensures the server stays running

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 Flow-Space Backend Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📋 Database: flow_space @ localhost" -ForegroundColor White
Write-Host "🔧 Environment: local" -ForegroundColor White
Write-Host "🌐 Port: 3001" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set environment
$env:NODE_ENV = "local"

# Change to backend directory
Set-Location $PSScriptRoot

# Function to check if server is running
function Test-ServerRunning {
    $listening = netstat -ano | Select-String "3001.*LISTENING"
    return $null -ne $listening
}

# Stop any existing Node processes on port 3001
Write-Host "🛑 Stopping any existing servers..." -ForegroundColor Yellow
Get-Process -Name node -ErrorAction SilentlyContinue | Where-Object {
    $procId = $_.Id
    $connections = netstat -ano | Select-String "3001.*LISTENING.*$procId"
    return $null -ne $connections
} | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# Start the server
Write-Host "🚀 Starting server..." -ForegroundColor Green
Write-Host ""

try {
    node server.js
    
    # If server exits, log it
    Write-Host ""
    Write-Host "⚠️ Server stopped unexpectedly" -ForegroundColor Yellow
    Write-Host "Press any key to restart or Ctrl+C to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Restart
    & $PSCommandPath
} catch {
    Write-Host ""
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
