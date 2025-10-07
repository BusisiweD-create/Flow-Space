Write-Host "Setting up Flow-Space database tables..." -ForegroundColor Green
Write-Host ""

# Check if PostgreSQL is available
$psqlPath = "C:\Program Files\PostgreSQL\16\bin\psql.exe"
if (-not (Test-Path $psqlPath)) {
    $psqlPath = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
    if (-not (Test-Path $psqlPath)) {
        Write-Host "❌ PostgreSQL not found. Please install PostgreSQL first." -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Found PostgreSQL at: $psqlPath" -ForegroundColor Green
Write-Host ""

# Run the database setup
Write-Host "Creating database tables..." -ForegroundColor Yellow
try {
    & $psqlPath -U postgres -d flow_space -f setup-database.sql
    Write-Host ""
    Write-Host "✅ Database tables created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Tables created:" -ForegroundColor Cyan
    Write-Host "   - profiles (users)" -ForegroundColor White
    Write-Host "   - sprints (sprint management)" -ForegroundColor White
    Write-Host "   - deliverables (project deliverables)" -ForegroundColor White
    Write-Host "   - approval_requests (approval workflow)" -ForegroundColor White
    Write-Host "   - notifications (user notifications)" -ForegroundColor White
    Write-Host "   - reports (project reports)" -ForegroundColor White
    Write-Host ""
    Write-Host "🔐 Permissions granted to flowspace_user" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Your database is ready for Flow-Space!" -ForegroundColor Green
} catch {
    Write-Host "❌ Error creating database tables: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Make sure PostgreSQL is running" -ForegroundColor White
    Write-Host "   2. Check your postgres password" -ForegroundColor White
    Write-Host "   3. Ensure the flow_space database exists" -ForegroundColor White
    Write-Host "   4. Run: createdb flow_space (if database doesn't exist)" -ForegroundColor White
}

Write-Host ""
Read-Host "Press Enter to continue"
