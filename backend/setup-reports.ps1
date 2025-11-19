# PowerShell script to setup reports tables
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   SETUP REPORTS TABLES" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

node setup-reports-tables.js

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Setup completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Setup failed. Check the errors above." -ForegroundColor Red
}

Write-Host "`nPress any key to exit..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

