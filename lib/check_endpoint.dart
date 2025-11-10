// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  print('🔍 Checking if /system/stats endpoint exists...');
  
  try {
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse('http://localhost:8000/system/stats'));
    
    // Add basic headers
    request.headers.add('Content-Type', 'application/json');
    request.headers.add('Accept', 'application/json');
    
    final response = await request.close();
    await response.transform(utf8.decoder).join();

    
    print('✅ Endpoint check completed!');
    print('📋 Response status: \${response.statusCode}');
    print('📄 Response headers: \${response.headers}');
    print('📝 Response body (first 200 chars): \${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}');
    
    if (response.statusCode == 200) {
      print('🎉 /system/stats endpoint exists and is working!');
    } else if (response.statusCode == 404) {
      print('❌ /system/stats endpoint not found (404)');
    } else if (response.statusCode == 401) {
      print('🔐 /system/stats endpoint requires authentication');
    } else {
      print('⚠️ /system/stats endpoint returned status: \${response.statusCode}');
    }
    
    httpClient.close();
  } catch (e) {
    print('❌ Error checking endpoint: $e');
    print('\n⚠️ This might indicate:');
    print('   - Backend server is not running on port 3000');
    print('   - /system/stats endpoint does not exist');
    print('   - Network connectivity issues');
  }
}