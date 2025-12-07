# Simple script to fix the string interpolation issue
$filePath = "lib/screens/role_dashboard_screen.dart"
$content = Get-Content $filePath -Raw

# Replace the problematic line with correct syntax
$correctLine = "            Text(
              'User: \${log['user_email'] ?? "Unknown User"}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),"

$incorrectLine = "            Text(
              'User: \\\${log['user_email'] ?? "Unknown User"}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),"

$content = $content -replace [regex]::Escape($incorrectLine), $correctLine

Set-Content $filePath -Value $content
Write-Host "String interpolation fixed!"