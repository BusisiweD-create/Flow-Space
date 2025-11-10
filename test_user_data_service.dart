import 'dart:convert';
import 'dart:io';

void main() async {
  
  // Test 1: Simple health check endpoint
  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://localhost:8000/api/v1/health'),
    );
    
    final response = await request.close();
    await response.transform(utf8.decoder).join();
    
    
    if (response.statusCode == 200) {
    } else {
    }
    
    client.close();
  // ignore: empty_catches
  } catch (e) {
  }
  
  // Test 2: Try to register a new user to test auth endpoints
  try {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('http://localhost:8000/api/v1/auth/register'),
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'email': 'testuser_${DateTime.now().millisecondsSinceEpoch}@example.com',
      'password': 'testpassword123',
      'firstName': 'Test',
      'lastName': 'User',
      'company': 'Test Company',
      'role': 'teamMember',
    }),);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    
    if (response.statusCode == 201) {
      final data = jsonDecode(responseBody);
      if (data['success'] == true) {
      } else {
      }
    } else {
    }
    
    client.close();
  // ignore: empty_catches
  } catch (e) {
  }
  
}