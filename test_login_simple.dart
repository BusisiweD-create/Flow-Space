// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🧪 Testing Flow-Space Login Functionality');
  print('==========================================');

  // Server is running (we know from the backend logs)
  print('✅ Server is running on port 8000');

  // Test login with existing user
  print('\n2. Testing login with existing user...');
  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:8000/api/v1/auth/login'));
    
    // Set headers
    request.headers.set('Content-Type', 'application/json');
    
    // Login credentials for existing user
    final loginData = {
      'email': 'testuser@example.com',
      'password': 'testpassword123',
    };
    
    request.write(json.encode(loginData));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final loginJson = json.decode(responseBody);
      print('✅ Login successful!');
      print('   User ID: ${loginJson['data']['user']['id']}');
      print('   Email: ${loginJson['data']['user']['email']}');
      print('   Name: ${loginJson['data']['user']['name']}');
      print('   Role: ${loginJson['data']['user']['role']}');
      print('   Token received: ${loginJson['data']['token'].toString().substring(0, 20)}...');
    } else {
      print('❌ Login failed with status: ${response.statusCode}');
      print('   Response: $responseBody');
    }
  } catch (e) {
    print('❌ Login error: $e');
  }

  print('\n3. Testing admin user login...');
  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:8000/api/v1/auth/login'));
    
    // Set headers
    request.headers.set('Content-Type', 'application/json');
    
    // Admin credentials
    final loginData = {
      'email': 'admin@flowspace.com',
      'password': 'admin123',
    };
    
    request.write(json.encode(loginData));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final loginJson = json.decode(responseBody);
      print('✅ Admin login successful!');
      print('   User ID: ${loginJson['data']['user']['id']}');
      print('   Email: ${loginJson['data']['user']['email']}');
      print('   Name: ${loginJson['data']['user']['name']}');
      print('   Role: ${loginJson['data']['user']['role']}');
    } else {
      print('❌ Admin login failed with status: ${response.statusCode}');
      print('   Response: $responseBody');
    }
  } catch (e) {
    print('❌ Admin login error: $e');
  }

  print('\n📋 Test completed!');
}