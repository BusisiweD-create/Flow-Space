// ignore_for_file: avoid_print

import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

void main() async {
  
  const baseUrl = 'http://localhost:8000';
  const adminEmail = 'admin@flowspace.com';
  const adminPassword = 'admin123';
  
  // First, login to get admin token
  final loginResponse = await http.post(
    Uri.parse('$baseUrl/api/v1/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': adminEmail,
      'password': adminPassword,
    }),
  );
  
  if (loginResponse.statusCode != 200) {
    print('❌ Login failed: ${loginResponse.body}');
    return;
  }
  
  final loginData = jsonDecode(loginResponse.body);
  
  String token = '';
  String userId = '';
  
  if (loginData['success'] == true) {
    token = loginData['data']['token'];
    userId = loginData['data']['user']['id'];
    
    print('✅ Login successful. Token: ${token.substring(0, 20)}...');
    print('   User ID: $userId');
    print('Admin user ID: $userId\n');
    
    // Continue with the test using token and userId
  } else {
    print('❌ Login failed: ${loginData['error']}');
    return;
  }
  
  // Test create user endpoint
  print('2. Testing create user endpoint...');
  final testUserEmail = 'testuser-${DateTime.now().millisecondsSinceEpoch}@test.com';
  
  final createResponse = await http.post(
    Uri.parse('$baseUrl/api/v1/auth/register'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': testUserEmail,
      'firstName': 'Test',
      'lastName': 'User',
      'role': 'team_member',
      'password': 'testpassword123',
    }),
  );
  
  if (createResponse.statusCode == 201) {
    final createData = jsonDecode(createResponse.body);
    final newUserId = createData['data']['user']['id'];
    print('✅ User created successfully!');
    print('   New user ID: $newUserId');
    print('   Email: $testUserEmail\n');

    // Test delete user endpoint
    print('3. Testing delete user endpoint...');
    final deleteResponse = await http.delete(
      Uri.parse('$baseUrl/api/v1/users/$newUserId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (deleteResponse.statusCode == 200) {
      final deleteData = jsonDecode(deleteResponse.body);
      if (deleteData['success'] == true) {
        print('✅ User deleted successfully!');

        // Verify that the user is actually deleted
        print('\n4. Verifying user deletion...');
        final verifyResponse = await http.get(
          Uri.parse('$baseUrl/api/v1/users'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (verifyResponse.statusCode == 200) {
          final verifyData = jsonDecode(verifyResponse.body);
          final users = verifyData['data'] as List;
          final userExists = users.any((user) => user['id'] == newUserId);

          if (!userExists) {
            print('✅ Verification successful: User no longer exists.');
            print('✅ All user management tests passed! 🎉');
          } else {
            print('❌ Verification failed: User still exists in the database.');
          }
        } else {
          print('❌ Verification failed with status code: ${verifyResponse.statusCode}');
          print('Response: ${verifyResponse.body}');
        }
      } else {
        print('❌ Delete user failed: ${deleteData['error']}');
      }
    } else {
      print('❌ Delete user failed with status code: ${deleteResponse.statusCode}');
      print('Response: ${deleteResponse.body}');
    }
  } else {
    print('❌ Create user failed: ${createResponse.statusCode}');
    print('Response: ${createResponse.body}');
  }
}