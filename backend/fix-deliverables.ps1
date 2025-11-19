Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Fix Deliverables Table Migration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

node fix-deliverables-table.js

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

