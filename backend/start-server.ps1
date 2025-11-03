Write-Host "Starting Flow-Space Backend Server..." -ForegroundColor Green
Write-Host ""
Write-Host "Server will run on http://localhost:3001" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Change to the backend directory
Set-Location $PSScriptRoot

# Start the server
node server.js