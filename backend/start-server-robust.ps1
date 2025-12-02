# Robust server startup script with auto-restart
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🚀 Flow-Space Backend Server" -ForegroundColor Cyan
Write-Host "   (Auto-restart enabled)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop any existing Node processes
Write-Host "🛑 Stopping existing Node processes..." -ForegroundColor Yellow
taskkill /F /IM node.exe /T 2>&1 | Out-Null
Start-Sleep -Seconds 2

# Set environment
$env:NODE_ENV = "local"

# Function to start server
function Start-Server {
    Write-Host "`n🚀 Starting server..." -ForegroundColor Green
    Write-Host "📋 Database: flow_space @ localhost" -ForegroundColor White
    Write-Host "🔧 Environment: local" -ForegroundColor White
    Write-Host "🌐 Port: 8000" -ForegroundColor White
    Write-Host ""
    
    try {
        node server.js
    } catch {
        Write-Host "`n❌ Server crashed!" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Yellow
        Write-Host "`n🔄 Restarting in 5 seconds..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        Start-Server
    }
}

# Start server with auto-restart
Start-Server

