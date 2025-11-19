# PostgreSQL Firewall Rule Setup
# Run this script as Administrator
# Right-click → Run with PowerShell

Write-Host "🔥 Adding PostgreSQL Firewall Rule..." -ForegroundColor Cyan
Write-Host ""

try {
    # Check if rule already exists
    $existingRule = Get-NetFirewallRule -DisplayName "PostgreSQL Server" -ErrorAction SilentlyContinue
    
    if ($existingRule) {
        Write-Host "⚠️  Rule already exists. Removing old rule..." -ForegroundColor Yellow
        Remove-NetFirewallRule -DisplayName "PostgreSQL Server"
    }
    
    # Create new firewall rule
    New-NetFirewallRule -DisplayName "PostgreSQL Server" `
        -Direction Inbound `
        -LocalPort 5432 `
        -Protocol TCP `
        -Action Allow `
        -Profile Domain,Private `
        -Description "Allow PostgreSQL connections from local network"
    
    Write-Host "✅ Firewall rule created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Rule Details:" -ForegroundColor Cyan
    Get-NetFirewallRule -DisplayName "PostgreSQL Server" | Format-List DisplayName,Enabled,Direction,Action
    
    Write-Host ""
    Write-Host "🎉 PostgreSQL is now accessible from your local network!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📍 Your IP address for collaborators:" -ForegroundColor Cyan
    
    # Get IP addresses
    $ipAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*"}
    foreach ($ip in $ipAddresses) {
        Write-Host "   $($ip.IPAddress)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Make sure you run this script as Administrator:" -ForegroundColor Yellow
    Write-Host "   Right-click → Run with PowerShell (as Administrator)" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

