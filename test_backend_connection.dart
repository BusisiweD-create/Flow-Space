// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing backend connection and user data service...\n');
  
  // Test 1: Root endpoint
  print('📋 Test 1: Root endpoint');
  try {
    final response = await http.get(Uri.parse('http://localhost:8000/'));
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('   ✅ Success: Backend is running');
    }
  } catch (e) {
    print('   ❌ Error: \$e');
  }
  
  // Test 2: Health endpoint
  print('\n📋 Test 2: Health endpoint');
  try {
    final response = await http.get(Uri.parse('http://localhost:8000/health'));
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      print('   ✅ Success: Backend health is good');
    }
  } catch (e) {
    print('   ❌ Error: \$e');
  }
  
  // Test 3: User registration (POST request)
  print('\n📋 Test 3: User registration');
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'testuser_${DateTime.now().millisecondsSinceEpoch}@example.com',
        'password': 'testpassword123',
        'firstName': 'Test',
        'lastName': 'User',
        'company': 'Test Company',
        'role': 'teamMember',
      }),
    );
    
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('   ✅ Success: User registered successfully');
        print('   👤 User ID: ${data['data']['user']['id']}');
      } else {
        print('   ❌ Failed: ${data['error']}');
      }
    } else {
      print('   ❌ Failed: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Error: \$e');
  }
  
  // Test 4: Test login with standard test credentials
  print('\n📋 Test 4: User login (with test credentials)');
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'testuser@example.com',
        'password': 'testpassword123',
      }),
    );
    
    print('   Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('   ✅ Success: User logged in successfully');
        print('   🔑 Token received: ${data['data']['token'].substring(0, 20)}...');
        
        // Test 5: Get users (requires admin token)
        print('\n📋 Test 5: Get all users (admin endpoint)');
        try {
          final usersResponse = await http.get(
            Uri.parse('http://localhost:8000/api/v1/users'),
            headers: {
              'Authorization': 'Bearer \$token',
              'Content-Type': 'application/json',
            },
          );
          
          print('   Status: ${usersResponse.statusCode}');
          if (usersResponse.statusCode == 200) {
            final usersData = jsonDecode(usersResponse.body);
            if (usersData['success'] == true) {
              final users = usersData['data'];
              print('   ✅ Success: Retrieved ${users.length} users');
              
              // Display first few users
              for (var i = 0; i < (users.length > 3 ? 3 : users.length); i++) {
                final user = users[i];
                print('     👤 ${user['name']} (${user['email']}) - ${user['role']}');
              }
              if (users.length > 3) {
                print('     ... and ${users.length - 3} more users');
              }
            } else {
              print('   ❌ Failed: ${usersData['error']}');
            }
          } else {
            print('   ❌ Failed: ${usersResponse.body}');
          }
        } catch (e) {
          print('   ❌ Error: \$e');
        }
      } else {
        print('   ❌ Failed: ${data['error']}');
      }
    } else {
      print('   ❌ Failed: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Error: \$e');
  }
  
  print('\n🎉 Backend connection test completed!');
  print('💡 The UserDataService should work correctly with real backend data.');
}