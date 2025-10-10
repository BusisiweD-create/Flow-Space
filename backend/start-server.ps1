# Flow-Space Backend Server Startup Script
Write-Host "🚀 Starting Flow-Space Backend Server..." -ForegroundColor Green
Write-Host ""

# Set environment variable
$env:NODE_ENV = "shared"

# Change to script directory
Set-Location $PSScriptRoot

# Start the server
Write-Host "📡 Server starting on port 3000..." -ForegroundColor Yellow
Write-Host "🔗 API available at: http://localhost:3000/api" -ForegroundColor Cyan
Write-Host "📧 Email service: Gmail SMTP configured" -ForegroundColor Cyan
Write-Host "🗄️ Database: PostgreSQL (shared mode)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Red
Write-Host ""

try {
    node server.js
} catch {
    Write-Host "❌ Error starting server: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
