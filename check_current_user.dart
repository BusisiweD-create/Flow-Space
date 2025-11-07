// Simple script to check current user role
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== Checking Current User Role ===');
  
  // Check if user is logged in by looking for auth tokens
  final appDir = Directory.current;
  final sharedPrefsDir = Directory('${appDir.path}/frontend/.dart_tool/flutter_build/shared_preferences');
  
  if (sharedPrefsDir.existsSync()) {
    final files = sharedPrefsDir.listSync();
    for (var file in files) {
      if (file.path.endsWith('.json')) {
        try {
          final content = File(file.path).readAsStringSync();
          final data = jsonDecode(content);
          
          if (data.containsKey('flutter.access_token')) {
            final token = data['flutter.access_token'];
            print('✓ User is logged in (access token found)');
            
            // Try to extract role from token (JWT format)
            if (token is String && token.contains('.')) {
              final parts = token.split('.');
              if (parts.length >= 2) {
                try {
                  final payload = base64Url.decode(parts[1]);
                  final payloadStr = utf8.decode(payload);
                  final payloadData = jsonDecode(payloadStr);
                  
                  if (payloadData.containsKey('role')) {
                    print('Current User Role: ${payloadData['role']}');
                  } else {
                    print('Role not found in token');
                  }
                  
                  if (payloadData.containsKey('email')) {
                    print('User Email: ${payloadData['email']}');
                  }
                  
                  return;
                } catch (e) {
                  print('Error decoding token: $e');
                }
              }
            }
          }
        } catch (e) {
          // Continue to next file
        }
      }
    }
  }
  
  print('✗ No active user session found');
  print('Please log in through the Flutter application first');
}