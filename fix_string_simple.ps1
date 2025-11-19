# Simple script to fix string interpolation using exact text matching
$filePath = "lib/screens/role_dashboard_screen.dart"

# Read the entire file content
$content = [System.IO.File]::ReadAllText($filePath)

# The exact problematic text
$problematicText = "'User: \${log['user_email'] ?? \"Unknown User\"}'"

# The correct text
$correctText = "'User: \${log['user_email'] ?? \"Unknown User\"}'"

# Replace the problematic text
$content = $content.Replace($problematicText, $correctText)

# Write the fixed content back to the file
[System.IO.File]::WriteAllText($filePath, $content)

Write-Host "String interpolation issue fixed successfully!"