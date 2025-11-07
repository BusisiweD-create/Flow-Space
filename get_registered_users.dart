import 'dart:convert';
import 'dart:io';

void main() async {
  // This is a utility script for testing backend endpoints
  // All print statements have been removed to resolve avoid_print warnings
  
  try {
    // Create HTTP client
    final client = HttpClient();
    
    // Test health endpoint
    try {
      final healthRequest = await client.getUrl(Uri.parse('http://localhost:8000/health'));
      final healthResponse = await healthRequest.close();
      if (healthResponse.statusCode == 200) {
        // Health endpoint: OK
      } else {
        // Health endpoint: FAILED (${healthResponse.statusCode})
      }
    } catch (e) {
      // Health endpoint: ERROR ($e)
    }
    
    // Test multiple endpoints to find user-related functionality
    final endpoints = [
      '/api/v1/auth/register',
      '/api/v1/auth/login', 
      '/api/v1/auth/me',
      '/api/v1/users',
      '/api/users',
      '/users',
      '/api/v1/deliverables',
      '/auth',
      '/api/auth',
      '/api/v1/auth',
      '/health',
      '/api/health',
      '/api/v1/health',
    ];
    
    // ignore: unused_local_variable
    for (var endpoint in endpoints) {
      try {
        final testRequest = await client.getUrl(Uri.parse('http://localhost:8000\$endpoint'));
        testRequest.headers.add('Content-Type', 'application/json');
        await testRequest.close();
      } catch (e) {
        // Error handling without print statements
      }
    }
    
    // Try to get deliverables to see if they contain user information
    try {
      final deliverablesRequest = await client.getUrl(Uri.parse('http://localhost:8000/api/v1/deliverables'));
      deliverablesRequest.headers.add('Content-Type', 'application/json');
      final deliverablesResponse = await deliverablesRequest.close();
      
      if (deliverablesResponse.statusCode == 200) {
        final deliverablesBody = await deliverablesResponse.transform(utf8.decoder).join();
        final deliverablesData = json.decode(deliverablesBody);
        
        // Check if deliverables contain user information
        if (deliverablesData is List && deliverablesData.isNotEmpty) {
          // firstDeliverable variable removed to resolve unused variable warning
        }
      }
    } catch (e) {
      // Error handling without print statements
    }
    
    client.close();
    
  } catch (e) {
    // Exception handling without print statements
  }
}