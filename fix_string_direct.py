# Simple Python script to fix string interpolation issue
import re

file_path = "lib/screens/role_dashboard_screen.dart"

# Read the file content
with open(file_path, 'r', encoding='utf-8') as file:
    content = file.read()

# Fix the problematic string interpolation
# The issue is that there's an extra backslash before the $ character
content = content.replace("User: \\\${log['user_email'] ?? \"Unknown User\"}", "User: \${log['user_email'] ?? \"Unknown User\"}")

# Write the fixed content back to the file
with open(file_path, 'w', encoding='utf-8') as file:
    file.write(content)

print("String interpolation issue fixed successfully!")