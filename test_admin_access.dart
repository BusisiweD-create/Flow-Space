// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🧪 Testing Admin Access for ClientReviewer User');
  print('=' * 50);
  
  // Test credentials for clientReviewer user
  const email = 'clientreviewer@example.com';
  const password = 'password123'; // From create-test-users.js
  
  try {
    // 1. Login to get JWT token
    print('1. Logging in as clientReviewer...');
    final loginResponse = await login(email, password);
    
    if (loginResponse['success'] == true) {
      final token = loginResponse['data']['token'];
      final userRole = loginResponse['data']['user']['role'];
      
      print('✅ Login successful!');
      print('   Role: $userRole');
      print('   Token: ${token.substring(0, 20)}...');
      
      // 2. Test access to admin endpoints
      print('\n2. Testing admin endpoint access...');
      
      // Test access to user management (admin endpoint)
      final usersResponse = await testAdminEndpoint('/api/v1/users', token);
      print('   Users endpoint: ${usersResponse['status']}');
      
      // Test access to settings (admin endpoint)
      final settingsResponse = await testAdminEndpoint('/api/v1/settings', token);
      print('   Settings endpoint: ${settingsResponse['status']}');
      
      // Test access to analytics (admin endpoint)
      final analyticsResponse = await testAdminEndpoint('/api/v1/analytics', token);
      print('   Analytics endpoint: ${analyticsResponse['status']}');
      
      print('\n📊 Access Test Summary:');
      print('   - User Role: $userRole');
      print('   - Should have admin access: ${userRole == 'admin' || userRole == 'clientReviewer'}');
      
    } else {
      print('❌ Login failed: ${loginResponse['error']}');
    }
    
  } catch (e) {
    print('❌ Error during test: $e');
  }
}

Future<Map<String, dynamic>> login(String email, String password) async {
  final client = HttpClient();
  
  try {
    final request = await client.postUrl(Uri.parse('http://localhost:8000/api/v1/auth/login'));
    request.headers.set('Content-Type', 'application/json');
    
    final body = json.encode({
      'email': email,
      'password': password,
    });
    
    request.write(body);
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    print('Response status: ${response.statusCode}');
    print('Response body: $responseBody');
    
    if (response.statusCode == 200) {
      final decodedResponse = json.decode(responseBody);
      return {
        'success': true,
        'data': {
          'token': decodedResponse['token'] ?? decodedResponse['accessToken'],
          'user': decodedResponse['user'] ?? {},
        },
      };
    } else {
      return {'success': false, 'error': 'HTTP ${response.statusCode}: $responseBody'};
    }
  } catch (e) {
    print('Exception during login: $e');
    return {'success': false, 'error': 'Exception: $e'};
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> testAdminEndpoint(String endpoint, String token) async {
  final client = HttpClient();
  
  try {
    final request = await client.getUrl(Uri.parse('http://localhost:8000$endpoint'));
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Content-Type', 'application/json');
    
    final response = await request.close();
    
    return {
      'status': 'HTTP ${response.statusCode}',
      'success': response.statusCode == 200,
      'hasAccess': response.statusCode < 400,
    };
  } catch (e) {
    return {'status': 'Error: $e', 'success': false, 'hasAccess': false};
  } finally {
    client.close();
  }
}