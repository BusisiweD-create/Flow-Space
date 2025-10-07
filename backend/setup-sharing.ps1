Write-Host "Setting up PostgreSQL for sharing with collaborators..." -ForegroundColor Green
Write-Host ""

Write-Host "Step 1: Finding your IP address..." -ForegroundColor Yellow
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"} | Select-Object -First 1).IPAddress
Write-Host "Your IP address is: $ip" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 2: Please run these commands in PostgreSQL:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Connect to PostgreSQL as superuser:" -ForegroundColor White
Write-Host "   psql -U postgres" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Run the setup script:" -ForegroundColor White
Write-Host "   \i setup-shared-db.sql" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Update your database-config.js with:" -ForegroundColor White
Write-Host "   - Host: $ip" -ForegroundColor Gray
Write-Host "   - Username: flowspace_user" -ForegroundColor Gray
Write-Host "   - Password: FlowSpace2024!" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Share these details with your collaborators:" -ForegroundColor White
Write-Host "   - Host: $ip" -ForegroundColor Gray
Write-Host "   - Port: 5432" -ForegroundColor Gray
Write-Host "   - Database: flow_space" -ForegroundColor Gray
Write-Host "   - Username: flowspace_user" -ForegroundColor Gray
Write-Host "   - Password: FlowSpace2024!" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Make sure PostgreSQL accepts connections:" -ForegroundColor White
Write-Host "   - Edit postgresql.conf: listen_addresses = '*'" -ForegroundColor Gray
Write-Host "   - Edit pg_hba.conf: host all all 0.0.0.0/0 md5" -ForegroundColor Gray
Write-Host "   - Restart PostgreSQL service" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to continue"
