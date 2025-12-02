// ignore_for_file: avoid_print

import 'package:khono/services/api_service.dart';
import 'package:khono/services/auth_service.dart';

void main() async {
  print('🔧 Testing System Metrics Integration...\n');
  
  try {
    // First, authenticate as system admin
    print('🔐 Authenticating as system admin...');
    final authService = AuthService();
    await authService.initialize();
    
    final loginSuccess = await authService.signIn('admin@flowspace.com', 'password');
    
    if (!loginSuccess) {
      print('❌ Authentication failed. Please check:');
      print('   - Backend server is running on http://localhost:8000');
      print('   - Admin user exists in database');
      print('   - Credentials: admin@flowspace.com / password');
      return;
    }
    
    print('✅ Authenticated as: \${authService.currentUser?.name}');
    print('   Role: \${authService.currentUser?.roleDisplayName}');
    print('   Is System Admin: \${authService.isSystemAdmin}');
    print('');
    
    // Now get system metrics
    print('📊 Loading system metrics...');
    await ApiService.getSystemMetrics();
    
    print('✅ System Metrics loaded successfully!');
    print('📊 CPU Usage: \${metrics.performance.cpuUsage}%');
    print('💾 Memory Usage: \${metrics.performance.memoryUsage}%');
    print('💿 Disk Usage: \${metrics.performance.diskUsage}%');
    print('⏱️ Response Time: \${metrics.performance.responseTime}ms');
    print('🕒 Uptime: \${metrics.performance.uptime} seconds');
    print('🗄️ Database Records: \${metrics.performance.databaseRecords}');
    print('👥 Active Users: \${metrics.performance.activeUsers}');
    print('🕐 Last Updated: \${metrics.performance.lastUpdated}');
    
    print('\n🎉 System Metrics test completed successfully!');
  } catch (e) {
    print('❌ Error loading system metrics: \$e');
    print('\n⚠️ This might indicate that:');
    print('   - Backend system stats endpoint is not available');
    print('   - Authentication failed (need system_admin role)');
    print('   - There are still type conversion issues');
    print('   - Network connectivity issues');
  }
}
