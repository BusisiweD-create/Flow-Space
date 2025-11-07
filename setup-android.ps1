# PowerShell script to setup Android development environment
Write-Host "🚀 Setting up Android Development Environment for FlowSpace" -ForegroundColor Green
Write-Host ""

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>$null
    if (-not $flutterVersion) {
        Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install"
        exit 1
    }
    Write-Host "✅ Flutter is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
}

# Check current Android configuration
Write-Host ""
Write-Host "📱 Current Android Configuration:" -ForegroundColor Yellow
flutter config

# Check Android SDK status
Write-Host ""
Write-Host "🔍 Checking Android SDK..." -ForegroundColor Yellow

$androidHome = $env:ANDROID_HOME
if (-not $androidHome) {
    Write-Host "❌ ANDROID_HOME environment variable is not set" -ForegroundColor Red
    
    # Try to find Android SDK in common locations
    $commonPaths = @(
        "$env:LOCALAPPDATA\Android\Sdk",
        "$env:ProgramFiles\Android\Android Studio\Sdk",
        "C:\Android\Sdk",
        "$env:USERPROFILE\AppData\Local\Android\Sdk"
    )
    
    $foundSdk = $false
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $androidHome = $path
            Write-Host "✅ Found Android SDK at: $androidHome" -ForegroundColor Green
            $foundSdk = $true
            break
        }
    }
    
    if (-not $foundSdk) {
        Write-Host ""
        Write-Host "📋 Android SDK Setup Instructions:" -ForegroundColor Cyan
        Write-Host "1. Download Android Studio: https://developer.android.com/studio"
        Write-Host "2. Install Android Studio with Android SDK"
        Write-Host "3. Set ANDROID_HOME environment variable to SDK path"
        Write-Host "4. Add $androidHome\platform-tools to PATH"
        Write-Host "5. Run 'flutter doctor --android-licenses'"
        Write-Host ""
        exit 1
    }
} else {
    Write-Host "✅ ANDROID_HOME is set to: $androidHome" -ForegroundColor Green
}

# Check if Android SDK tools are available
Write-Host ""
Write-Host "🛠️ Checking Android tools..." -ForegroundColor Yellow

$toolsToCheck = @("adb", "sdkmanager", "avdmanager")
foreach ($tool in $toolsToCheck) {
    $toolPath = Get-Command $tool -ErrorAction SilentlyContinue
    if ($toolPath) {
        Write-Host "✅ $tool found: $($toolPath.Source)" -ForegroundColor Green
    } else {
        Write-Host "❌ $tool not found in PATH" -ForegroundColor Red
    }
}

# Run flutter doctor to check overall status
Write-Host ""
Write-Host "🏥 Running Flutter Doctor..." -ForegroundColor Yellow
flutter doctor -v

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Install missing components from Android Studio SDK Manager"
Write-Host "2. Run: flutter doctor --android-licenses"
Write-Host "3. Create Android Virtual Device (AVD) from Android Studio"
Write-Host "4. Test with: flutter run"

Write-Host ""
Write-Host "✅ Android environment setup check completed!" -ForegroundColor Green