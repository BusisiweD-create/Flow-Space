// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:khono/models/user_role.dart';

import 'services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Backend connection test', () async {
    print('🔌 Testing backend connection with authentication...');

    try {
      // 1. Register a new admin user
      // Generate a unique email for the new user to avoid conflicts
      const uniqueEmail = 'admin_\${DateTime.now().millisecondsSinceEpoch}@flow.com';

      final authService = AuthService();
      await authService.initialize();
      final registrationResult = await authService.signUp(uniqueEmail, 'password', 'Test Admin', UserRole.systemAdmin);

      if (registrationResult['success'] != true) {
        print('❌ Admin registration failed: ${registrationResult['error']}');
        return;
      }

      print('✅ Admin registration successful!');

      // 2. Authenticate as the new admin user
      print('\n--- Authenticating as new admin ---');
      final loggedIn = await authService.signIn(uniqueEmail, 'password');

      if (!loggedIn) {
        print('❌ Admin login failed. Cannot proceed.');
        return;
      }

      print('✅ Admin login successful!');
      final token = authService.accessToken;
      print('🔑 Got auth token: $token');

      // 2. Make authenticated request to system stats
      print('\n--- Fetching system stats with token ---');
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse('http://localhost:8000/api/v1/system/stats'));

      // Add auth token to header
      request.headers.add('Authorization', 'Bearer $token');
      request.headers.add('Content-Type', 'application/json');

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      print('✅ Request completed!');
      print('📋 Response status: \${response.statusCode}');
      print('📝 Response body: $responseBody');

      httpClient.close();
    } catch (e) {
      print('❌ An error occurred: $e');
    }

    print('✅ Backend connection test finished successfully!');
  });
}