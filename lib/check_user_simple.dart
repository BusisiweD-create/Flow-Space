// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

void main() async {
  print('=== Checking Current User Status ===');
  
  final prefsDir = Directory('frontend/.dart_tool/flutter_build/shared_preferences');
  String? accessToken;
  String? userId;
  if (await prefsDir.exists()) {
    final tokenFile = File('${prefsDir.path}/access_token.json');
    if (await tokenFile.exists()) {
      accessToken = await tokenFile.readAsString();
    }
    final userIdFile = File('${prefsDir.path}/user_id.json');
    if (await userIdFile.exists()) {
      userId = await userIdFile.readAsString();
    }
  }
  
  print('Access Token Present: ${accessToken != null}');
  print('User ID Present: ${userId != null}');
  print('User ID: $userId');
  
  if (accessToken != null) {
    print('\n=== JWT Token Analysis ===');
    
    // Simple JWT parsing (just for basic info)
    try {
      final parts = accessToken.split('.');
      if (parts.length == 3) {
        final payload = String.fromCharCodes(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final Map<String, dynamic> claims = jsonDecode(payload);
        
        print('User Email: ${claims['email'] ?? "Unknown"}');
        print('User Role: ${claims['role'] ?? "Unknown"}');
        print('User ID in token: ${claims['sub'] ?? "Unknown"}');
        
        // Check if user has manage_users permission (system admin)
        final userRole = claims['role']?.toString() ?? '';
        final hasManageUsers = userRole == 'systemAdmin';
        
        print('Has manage_users permission: $hasManageUsers');
        print('Can see Settings in sidebar: $hasManageUsers');
      }
    } catch (e) {
      print('Error parsing JWT token: $e');
    }
  } else {
    print('\nNo user is currently authenticated.');
    print('Please sign in to see your user role and permissions.');
  }
}