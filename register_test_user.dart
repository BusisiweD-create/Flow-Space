// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  print('Registering test user...');
  
  try {
    final httpClient = HttpClient();
    
    // Register a new test user
    final request = await httpClient.postUrl(
      Uri.parse('http://localhost:8000/api/v1/auth/register'),
    );
    
    request.headers.set('Content-Type', 'application/json');
    
    final userData = {
      'email': 'testuser@example.com',
      'password': 'testpassword123',
      'firstName': 'Test',
      'lastName': 'User',
      'role': 'user',
    };
    
    request.write(json.encode(userData));
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 201) {
      print('✅ User registered successfully!');
    } else {
      print('❌ Failed to register user. Status code: ${response.statusCode}');
      print('Response: $responseBody');
    }
    
    httpClient.close();
  } catch (e) {
    print('❌ Error registering user: $e');
  }
}