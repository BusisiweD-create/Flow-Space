@echo off
echo 🚀 Setting up Android Development Environment for FlowSpace
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed or not in PATH
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    exit /b 1
)
echo ✅ Flutter is installed

echo.
echo 📱 Current Android Configuration:
flutter config

echo.
echo 🔍 Checking Android SDK...

REM Check ANDROID_HOME environment variable
if "%ANDROID_HOME%"=="" (
    echo ❌ ANDROID_HOME environment variable is not set
    
    REM Try to find Android SDK in common locations
    set FOUND_SDK=0
    
    if exist "%LOCALAPPDATA%\Android\Sdk" (
        set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
        echo ✅ Found Android SDK at: %ANDROID_HOME%
        set FOUND_SDK=1
    ) else if exist "%ProgramFiles%\Android\Android Studio\Sdk" (
        set ANDROID_HOME=%ProgramFiles%\Android\Android Studio\Sdk
        echo ✅ Found Android SDK at: %ANDROID_HOME%
        set FOUND_SDK=1
    ) else if exist "C:\Android\Sdk" (
        set ANDROID_HOME=C:\Android\Sdk
        echo ✅ Found Android SDK at: %ANDROID_HOME%
        set FOUND_SDK=1
    ) else if exist "%USERPROFILE%\AppData\Local\Android\Sdk" (
        set ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk
        echo ✅ Found Android SDK at: %ANDROID_HOME%
        set FOUND_SDK=1
    )
    
    if "%FOUND_SDK%"=="0" (
        echo.
        echo 📋 Android SDK Setup Instructions:
        echo 1. Download Android Studio: https://developer.android.com/studio
        echo 2. Install Android Studio with Android SDK
        echo 3. Set ANDROID_HOME environment variable to SDK path
        echo 4. Add %%ANDROID_HOME%%\platform-tools to PATH
        echo 5. Run 'flutter doctor --android-licenses'
        echo.
        exit /b 1
    )
) else (
    echo ✅ ANDROID_HOME is set to: %ANDROID_HOME%
)

echo.
echo 🛠️ Checking Android tools...

REM Check if Android tools are available
where adb >nul 2>&1
if errorlevel 1 (echo ❌ adb not found in PATH) else (echo ✅ adb found)

where sdkmanager >nul 2>&1
if errorlevel 1 (echo ❌ sdkmanager not found in PATH) else (echo ✅ sdkmanager found)

where avdmanager >nul 2>&1
if errorlevel 1 (echo ❌ avdmanager not found in PATH) else (echo ✅ avdmanager found)

echo.
echo 🏥 Running Flutter Doctor...
flutter doctor -v

echo.
echo 📋 Next Steps:
echo 1. Install missing components from Android Studio SDK Manager
echo 2. Run: flutter doctor --android-licenses
echo 3. Create Android Virtual Device (AVD) from Android Studio
echo 4. Test with: flutter run

echo.
echo ✅ Android environment setup check completed!
pause