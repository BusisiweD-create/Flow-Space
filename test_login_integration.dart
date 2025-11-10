// ignore_for_file: avoid_print

import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

void main() async {
  print('🔐 Testing Login Integration...\n');
  
  try {
    // Test the login endpoint directly
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': 'test@example.com',
        'password': 'password123',
      }),
    );

    print('📋 Response Status: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Login successful!');
      print('🔑 Token: ${data['token'] != null}');
      print('👤 User ID: ${data['user']?['id'] ?? 'N/A'}');
      print('📧 User Email: ${data['user']?['email'] ?? 'N/A'}');
    } else {
      print('❌ Login failed with status: ${response.statusCode}');
      print('💬 Error: ${response.body}');
    }
    
  } catch (e) {
    print('❌ Exception during login test: $e');
  }
  
  print('\n🎉 Integration test completed!');
}