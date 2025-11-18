import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Firebase initialized successfully!
    
    // Test email sending
    await testEmailSending();
  } catch (e) {
    // Firebase initialization failed: $e
  }
}

Future<void> testEmailSending() async {
  try {
    final auth = FirebaseAuth.instance;
    
    // Create a test user
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: 'test-${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'testpassword123',
    );
    
    // Test user created: ${userCredential.user?.email}
    
    // Send verification email
    await userCredential.user?.sendEmailVerification();
    // Verification email sent!
    
    // Sign out
    await auth.signOut();
    // Test completed successfully!
    
  } catch (e) {
    // Email test failed: $e
  }
}
