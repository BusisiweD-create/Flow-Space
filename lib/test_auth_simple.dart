// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {

  try {
    // Test if backend is reachable
    final healthResponse = await http.get(Uri.parse('http://localhost:8000/health'));
    if (healthResponse.statusCode != 200) {
      return;
    }
    

    // Try to login
    final loginResponse = await http.post(
      Uri.parse('http://localhost:8000/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'admin@flowspace.com',
        'password': 'password',
      }),
    );

    if (loginResponse.statusCode == 200) {
      final responseData = jsonDecode(loginResponse.body);
      final user = responseData['user'];
      
      
      // Check if user has system admin role
      final isSystemAdmin = user['role'] == 'system_admin';
      
      if (isSystemAdmin) {
      } else {
      }
      
    } else {
    }
    
  } catch (e) {
  }
}