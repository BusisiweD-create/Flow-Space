@echo off
echo Setting up Khono development environment...
echo.

echo [1/5] Installing Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error: Failed to install Flutter dependencies
    pause
    exit /b 1
)

echo [2/5] Running Flutter doctor...
flutter doctor
echo.

echo [3/5] Analyzing code...
flutter analyze
echo.

echo [4/5] Checking backend configuration...
if not exist "config\environment.dart" (
    echo Warning: Environment configuration not found
    echo Please update config\environment.dart with your backend settings
) else (
    echo Environment configuration found
)

echo [5/5] Development environment setup complete!
echo.
echo Next steps:
echo 1. Update config/environment.dart with your backend settings
echo 2. Run 'flutter run' to start the app
echo.
pause
