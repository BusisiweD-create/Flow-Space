#!/bin/bash

echo "Setting up Khono development environment..."
echo

echo "[1/5] Installing Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "Error: Failed to install Flutter dependencies"
    exit 1
fi

echo "[2/5] Running Flutter doctor..."
flutter doctor
echo

echo "[3/5] Analyzing code..."
flutter analyze
echo

echo "[4/5] Creating Firebase configuration..."
if [ ! -f "lib/firebase_options.dart" ]; then
    echo "Warning: Firebase configuration not found"
    echo "Please run 'flutterfire configure' to set up Firebase"
    echo "Or copy lib/firebase_options.dart.template to lib/firebase_options.dart"
else
    echo "Firebase configuration found"
fi

echo "[5/5] Development environment setup complete!"
echo
echo "Next steps:"
echo "1. Configure Firebase (if not done already)"
echo "2. Update config/environment.dart with your settings"
echo "3. Run 'flutter run' to start the app"
echo
