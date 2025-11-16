# PowerShell script to fix string interpolation issues in role_dashboard_screen.dart
$content = Get-Content -Path "lib/screens/role_dashboard_screen.dart" -Raw

# Fix the specific problematic line using a simpler approach
$content = $content -replace "User: \\\${log\['user_email'\] ?? \"Unknown User\"}", "User: \${log['user_email'] ?? \"Unknown User\"}"

# Write the fixed content back to the file
Set-Content -Path "lib/screens/role_dashboard_screen.dart" -Value $content

Write-Host "String interpolation issue fixed successfully!"