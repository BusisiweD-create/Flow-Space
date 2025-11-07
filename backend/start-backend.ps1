# Flow-Space Backend Startup Script
Write-Host "Starting Flow-Space Backend Server..." -ForegroundColor Green

# Set the working directory to the backend folder
$BackendPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $BackendPath

Write-Host "Working directory: $BackendPath" -ForegroundColor Cyan

# Set environment variables
$env:PORT = "8000"
$env:NODE_ENV = "development"

Write-Host "Port: $env:PORT" -ForegroundColor Cyan
Write-Host "Environment: $env:NODE_ENV" -ForegroundColor Cyan

# Start the server
Write-Host "`nStarting Node.js server..." -ForegroundColor Green
node server.js

