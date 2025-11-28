# Android Development Environment Setup Instructions

## 🚨 Critical Issues Identified

Based on `flutter doctor` analysis, you have 3 critical issues:

1. **❌ Android toolchain** - Unable to locate Android SDK
2. **⚠️ Visual Studio** - Installation incomplete (missing components)
3. **❌ Android Studio** - Not installed

## 📋 Step-by-Step Solution

### 1. Install Android Studio

**Download and Install:**
1. Go to https://developer.android.com/studio
2. Download Android Studio
3. Run the installer
4. **During installation, make sure to:**
   - Install Android SDK
   - Install Android Emulator  
   - Install Android Build Tools
   - Accept all licenses

### 2. Set Environment Variables

**After installation, set these environment variables:**

```cmd
setx ANDROID_HOME "%LOCALAPPDATA%\Android\Sdk"
setx PATH "%PATH%;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools\bin"
```

**Or manually in System Properties:**
1. Press `Win + R`, type `sysdm.cpl`
2. Go to Advanced → Environment Variables
3. Add new system variable:
   - Name: `ANDROID_HOME`
   - Value: `C:\Users\%USERNAME%\AppData\Local\Android\Sdk`
4. Edit `PATH` variable and add:
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\tools\bin`

### 3. Complete Visual Studio Installation

**Fix Visual Studio Build Tools:**
1. Open Visual Studio Installer
2. Click "Modify" on your Visual Studio version
3. Install these workloads:
   - **Desktop development with C++**
   - **Universal Windows Platform development**
   - **Windows 10/11 SDK** (latest version)

### 4. Verify Setup

**Run these commands to verify:**

```bash
# Accept Android licenses
flutter doctor --android-licenses

# Verify setup
flutter doctor -v

# Check Android tools
adb version
sdkmanager --list
```

### 5. Create Android Virtual Device (AVD)

**In Android Studio:**
1. Open Android Studio
2. Go to Tools → AVD Manager
3. Create Virtual Device
4. Choose a device (Pixel 5 recommended)
5. Download a system image (Android API 33+)
6. Finish setup

### 6. Test Flutter App

**Run your Flutter app:**

```bash
cd frontend
flutter pub get
flutter run
```

## 🔧 Troubleshooting

### If Android SDK not found:
```bash
# Manually set SDK path
flutter config --android-sdk "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"
```

### If licenses not accepted:
```bash
# Accept all licenses
y | sdkmanager --licenses
```

### If build fails:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
```

## ✅ Expected Result

After completing these steps, `flutter doctor` should show:

```
[✓] Flutter
[✓] Android toolchain
[✓] Chrome
[✓] Visual Studio  
[✓] Android Studio
[✓] Connected devices
```

## 📞 Support

If you encounter issues:
1. Check Flutter documentation: https://flutter.dev/to/windows-android-setup
2. Verify Android Studio installation
3. Ensure environment variables are set correctly
4. Restart your computer after making changes