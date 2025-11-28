# Android SDK Command Line Tools Setup Guide

## 🎯 Quick Setup Instructions

### 1. Install Command Line Tools via Android Studio

1. **Open Android Studio** (you should see it in your Start menu)
2. Go to **Tools → SDK Manager**
3. Click on the **SDK Tools** tab
4. Check the box for **Android SDK Command-line Tools (latest)**
5. Click **Apply** to install

### 2. Accept Android SDK Licenses

After installing the command line tools, run:
```bash
flutter doctor --android-licenses
```
Press 'y' to accept all licenses when prompted.

### 3. Set ANDROID_HOME Environment Variable

If not already set, add this to your system environment variables:
- **Variable name**: `ANDROID_HOME`
- **Variable value**: `C:\Users\%USERNAME%\AppData\Local\Android\Sdk`

Also add to PATH:
- `%ANDROID_HOME%\platform-tools`
- `%ANDROID_HOME%\tools\bin`

### 4. Complete Visual Studio Setup

Run **Visual Studio Installer** and install:
- C++ build tools
- Windows SDK
- Any missing components

## 🔍 Verification Commands

After setup, verify everything works:

```bash
# Check full environment status
flutter doctor -v

# Verify sdkmanager is available
sdkmanager --list

# Check Android devices
adb devices
```

## 🚀 Alternative: Manual Installation

If Android Studio method doesn't work, download manually:

1. Download from: https://developer.android.com/studio#command-line-tools-only
2. Extract to: `C:\Users\%USERNAME%\AppData\Local\Android\Sdk\cmdline-tools\latest`
3. Set environment variables as above

## ✅ Expected Final Result

After successful setup, `flutter doctor` should show:
```
[✓] Android toolchain - develop for Android devices
    • Android SDK at C:\Users\[username]\AppData\Local\Android\Sdk
    • Platform android-34, build-tools 34.0.0
    • ANDROID_HOME = C:\Users\[username]\AppData\Local\Android\Sdk
    • Java binary at: ...
    • All Android licenses accepted.
```