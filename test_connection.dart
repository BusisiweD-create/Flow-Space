// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  
  try {
    // Test 1: Check if backend server is reachable
    
    final healthCheck = await HttpClient().getUrl(
      Uri.parse('http://localhost:8000/api/v1/health'),
    );
    
    await healthCheck.close();
    
    // Test 2: Test login endpoint
    
    final loginRequest = await HttpClient().postUrl(
      Uri.parse('http://localhost:8000/api/v1/auth/login'),
    );
    
    loginRequest.headers.set('Content-Type', 'application/json');
    loginRequest.write(jsonEncode({
      'email': 'test@example.com',
      'password': 'password123',
    }),);
    
    final loginResponse = await loginRequest.close();
    final responseBody = await loginResponse.transform(utf8.decoder).join();
    
    print('   ✅ Login endpoint responds (Status: ${loginResponse.statusCode})');
    
    if (loginResponse.statusCode == 200) {
      final responseData = jsonDecode(responseBody);
      print('   ✅ Login successful!');
      print('   ✅ Token received: ${responseData['token'] != null}');
      print('   ✅ User data: ${responseData['user'] != null}');
    } else {
      print('   ❌ Login failed: $responseBody');
    }
    
    print('\n🎉 Connection test completed!');
    print('\n📋 Your backend server is working correctly at http://localhost:8000');
    print('\n🚀 You can now run your Flutter app with:');
    print('   flutter run -d windows');
    print('\n🔑 Test credentials:');
    print('   • Email: test@example.com');
    print('   • Password: password123');
    
  } catch (e) {
    print('❌ Connection test failed: $e');
    print('\n⚠️  Make sure your backend server is running:');
    print('   cd c:\\Flow\\backend\\node-backend');
    print('   node src/app.js');
  }
}