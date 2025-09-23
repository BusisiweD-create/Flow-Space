#!/usr/bin/env python3
"""
Test script to check if basic imports work correctly
"""

import sys
print("Python executable:", sys.executable)
print("Python version:", sys.version)
print()

# Test basic imports
try:
    import fastapi
    print("✓ FastAPI imported successfully")
    print("  FastAPI version:", fastapi.__version__)
except Exception as e:
    print("✗ FastAPI import failed:", e)

print()

try:
    import pydantic
    print("✓ Pydantic imported successfully")
    print("  Pydantic version:", pydantic.__version__)
except Exception as e:
    print("✗ Pydantic import failed:", e)

print()

try:
    from models import Base
    print("✓ Models imported successfully")
except Exception as e:
    print("✗ Models import failed:", e)

print()

try:
    from schemas import SettingsResponse
    print("✓ Schemas imported successfully")
except Exception as e:
    print("✗ Schemas import failed:", e)

print()
print("Test completed!")