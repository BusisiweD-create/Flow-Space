# Firebase Setup Guide for Khono

## 🔥 Manual Firebase Configuration

Since the FlutterFire CLI had some issues, here's how to manually set up Firebase for your Khono project:

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `khono-app` (or your preferred name)
4. Enable Google Analytics (recommended)
5. Choose or create a Google Analytics account
6. Click "Create project"

### Step 2: Add Apps to Your Project

#### For Web App:
1. In your Firebase project, click the web icon (`</>`)
2. Enter app nickname: `khono-web`
3. Check "Also set up Firebase Hosting" (optional)
4. Click "Register app"
5. Copy the configuration object

#### For Android App:
1. Click the Android icon
2. Enter package name: `com.example.khono`
3. Enter app nickname: `khono-android`
4. Enter SHA-1 (optional for now)
5. Click "Register app"
6. Download `google-services.json`

#### For iOS App:
1. Click the iOS icon
2. Enter bundle ID: `com.example.khono`
3. Enter app nickname: `khono-ios`
4. Click "Register app"
5. Download `GoogleService-Info.plist`

### Step 3: Enable Required Services

#### Authentication:
1. Go to "Authentication" → "Sign-in method"
2. Enable "Email/Password"
3. Enable "Google" (optional)

#### Firestore Database:
1. Go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users

#### Cloud Storage:
1. Go to "Storage"
2. Click "Get started"
3. Choose "Start in test mode" (for development)
4. Select a location

#### Analytics:
1. Go to "Analytics" → "Events"
2. Analytics should be automatically enabled

### Step 4: Update Configuration Files

#### Update `lib/firebase_options.dart`:

Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
// Example for web platform:
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', // Your actual web API key
  appId: '1:123456789012:web:abcdefghijklmnop', // Your actual web app ID
  messagingSenderId: '123456789012', // Your actual messaging sender ID
  projectId: 'khono-app', // Your actual project ID
  authDomain: 'khono-app.firebaseapp.com', // Your actual auth domain
  storageBucket: 'khono-app.appspot.com', // Your actual storage bucket
  measurementId: 'G-XXXXXXXXXX', // Your actual measurement ID
);
```

#### For Android:
1. Place `google-services.json` in `android/app/` directory
2. Update the Android configuration in `firebase_options.dart`

#### For iOS:
1. Place `GoogleService-Info.plist` in `ios/Runner/` directory
2. Update the iOS configuration in `firebase_options.dart`

### Step 5: Update Environment Configuration

Edit `config/environment.dart` and update the Firebase settings:

```dart
class Environment {
  // Firebase Configuration
  static const String firebaseProjectId = 'khono-app'; // Your actual project ID
  static const String firebaseApiKey = 'your-actual-api-key';
  static const String firebaseAppId = 'your-actual-app-id';
  static const String firebaseMessagingSenderId = 'your-actual-sender-id';

  // ... rest of your configuration
}
```

### Step 6: Test Firebase Connection

Create a simple test to verify Firebase is working:

```dart
// In your main.dart or a test file
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}
```

### Step 7: Security Rules (Important!)

#### Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Storage Security Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🚀 Next Steps

1. **Test the setup**: Run `flutter run` and check for any Firebase-related errors
2. **Implement authentication**: Start with basic email/password authentication
3. **Set up Firestore**: Create your first collections and documents
4. **Configure storage**: Set up file upload functionality
5. **Deploy**: When ready, deploy to Firebase Hosting (web) or app stores

## 🔧 Troubleshooting

### Common Issues:

1. **"Firebase not initialized"**: Make sure you call `Firebase.initializeApp()` before using any Firebase services
2. **"Permission denied"**: Check your Firestore and Storage security rules
3. **"API key not valid"**: Verify your API keys in `firebase_options.dart`
4. **"Project not found"**: Ensure your project ID is correct

### Getting Help:

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

---

**Your Firebase setup is now ready! 🎉**
