@echo off
echo ========================================
echo    VISUAL STUDIO INSTALLER LAUNCHER
echo ========================================
echo.

echo [1/3] Checking for Visual Studio Installer...

:: Check if Visual Studio Installer exists
if exist "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" (
    echo Found Visual Studio Installer!
    echo.
    echo [2/3] Launching Visual Studio Installer...
    "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe"
    echo.
    echo [3/3] Installer launched successfully!
) else (
    echo Visual Studio Installer not found.
    echo.
    echo [2/3] Please download from:
    echo https://aka.ms/vs/16/release/vs_buildtools.exe
    echo.
    echo [3/3] After downloading, run the installer
)

echo.
echo ========================================
echo    INSTRUCTIONS:
echo ========================================
echo 1. Select "Visual Studio Build Tools 2019"
echo 2. Click "Modify"
echo 3. Go to "Individual components" tab
echo 4. Install these components:
echo    - MSVC v142 - VS 2019 C++ x64/x86 build tools
echo    - Windows 10 SDK (10.0.19041.0)
echo    - C++ CMake tools for Windows
echo.
echo After installation, run: flutter doctor -v
echo.

pause