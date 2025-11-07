# Development Environment Setup Guide

## Critical Issues Resolved

### 1. Android Development Setup

**Problem**: Android SDK, Android Studio, and Visual Studio components missing

**Solution**:
1. **Install Android Studio**: Download from https://developer.android.com/studio
2. **During installation**: Make sure to install:
   - Android SDK
   - Android Emulator
   - Android Build Tools
3. **Set Environment Variables**:
   ```bash
   setx ANDROID_HOME "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"
   setx PATH "%PATH%;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools\bin"
   ```
4. **Complete Visual Studio Setup**:
   - Run Visual Studio Installer
   - Install "Desktop development with C++" workload
   - Install Windows 10/11 SDK

### 2. Flutter Configuration

**Verify setup**:
```bash
flutter doctor
flutter config --android-sdk "%ANDROID_HOME%"
flutter doctor --android-licenses
```

### 3. Backend Development

**Start backend server**:
```bash
cd backend
npm install
npm run dev
```

### 4. Frontend Development

**Run Flutter app**:
```bash
cd frontend
flutter pub get
flutter run
```

## Environment Variables

Create/update `.env` files:

**Backend (.env)**:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/flowspace
JWT_SECRET=your-super-secret-jwt-key-here
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

**Frontend (lib/config/environment.dart)**:
```dart
const String apiBaseUrl = 'http://localhost:3000';
const String socketUrl = 'http://localhost:3000';
```

## Verification

After setup, run:
```bash
flutter doctor -v
flutter analyze
npm test # in backend directory
```

All checks should pass with no errors.