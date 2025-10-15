@echo off
echo ========================================
echo    COMPLETE ANDROID SETUP FOR FLOWSPACE
echo ========================================
echo.

:: Check current status
echo [1/4] Checking current Flutter/Android status...
flutter doctor

echo.
echo [2/4] Please run these commands manually:
echo.
echo 1. Open Android Studio → Tools → SDK Manager
echo 2. Check "Android SDK Command-line Tools (latest)"
echo 3. Click Apply to install
echo.
echo 4. Run: flutter doctor --android-licenses
echo 5. Press 'y' to accept all licenses
echo.
echo 6. Run Visual Studio Installer to complete setup
echo.

:: Check ANDROID_HOME
echo [3/4] Checking ANDROID_HOME environment variable...
if defined ANDROID_HOME (
    echo ANDROID_HOME is set to: %ANDROID_HOME%
) else (
    echo ANDROID_HOME is not set. Please set it to your Android SDK path.
    echo Typical path: C:\Users\%USERNAME%\AppData\Local\Android\Sdk
)

echo.
echo [4/4] Final verification after setup:
echo Run: flutter doctor -v
echo.
echo ========================================
echo    SETUP COMPLETE WHEN flutter doctor
echo    shows no issues in Android toolchain
echo ========================================

pause