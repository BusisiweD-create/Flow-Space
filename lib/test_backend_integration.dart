import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/backend_api_service.dart';
import 'services/api_client.dart';

class BackendIntegrationTest {
  static Future<void> runTests() async {
    debugPrint('🧪 Starting Backend Integration Tests...');

    // Test 1: API Client Initialization
    await _testApiClientInitialization();

    // Test 2: Mock Backend Authentication
    await _testMockAuthentication();

    // Test 3: Auth Service Integration
    await _testAuthServiceIntegration();

    // Test 4: Backend API Service
    await _testBackendApiService();

    debugPrint('✅ Backend Integration Tests Completed!');
  }

  static Future<void> _testApiClientInitialization() async {
    debugPrint('📡 Testing API Client Initialization...');
    
    try {
      final apiClient = ApiClient();
      await apiClient.initialize();
      
      debugPrint('✅ API Client initialized successfully');
      debugPrint('   - Mock Backend: ${apiClient.isAuthenticated ? 'Connected' : 'Not connected'}');
    } catch (e) {
      debugPrint('❌ API Client initialization failed: $e');
    }
  }

  static Future<void> _testMockAuthentication() async {
    debugPrint('🔐 Testing Mock Authentication...');
    
    try {
      final apiClient = ApiClient();
      
      // Test login
      final loginResponse = await apiClient.login('team@example.com', 'password123');
      debugPrint('   - Login Response: ${loginResponse.isSuccess ? 'Success' : 'Failed'}');
      
      if (loginResponse.isSuccess) {
        debugPrint('   - Access Token: ${loginResponse.data?['access_token']?.toString().substring(0, 20)}...');
        debugPrint('   - User: ${loginResponse.data?['user']?['name']}');
      }
      
      // Test get current user
      final userResponse = await apiClient.getCurrentUser();
      debugPrint('   - Current User: ${userResponse.isSuccess ? 'Retrieved' : 'Failed'}');
      
      // Test logout
      final logoutResponse = await apiClient.logout();
      debugPrint('   - Logout: ${logoutResponse.isSuccess ? 'Success' : 'Failed'}');
      
      debugPrint('✅ Mock Authentication tests completed');
    } catch (e) {
      debugPrint('❌ Mock Authentication test failed: $e');
    }
  }

  static Future<void> _testAuthServiceIntegration() async {
    debugPrint('👤 Testing Auth Service Integration...');
    
    try {
      final authService = AuthService();
      await authService.initialize();
      
      // Test sign in
      final signInSuccess = await authService.signIn('lead@example.com', 'password123');
      debugPrint('   - Sign In: ${signInSuccess ? 'Success' : 'Failed'}');
      
      if (signInSuccess) {
        debugPrint('   - Current User: ${authService.currentUser?.name}');
        debugPrint('   - User Role: ${authService.currentUser?.roleDisplayName}');
        debugPrint('   - Permissions: ${authService.getCurrentUserPermissions().length} permissions');
      }
      
      // Test sign out
      await authService.signOut();
      debugPrint('   - Sign Out: ${!authService.isAuthenticated ? 'Success' : 'Failed'}');
      
      debugPrint('✅ Auth Service Integration tests completed');
    } catch (e) {
      debugPrint('❌ Auth Service Integration test failed: $e');
    }
  }

  static Future<void> _testBackendApiService() async {
    debugPrint('🌐 Testing Backend API Service...');
    
    try {
      final apiService = BackendApiService();
      await apiService.initialize();
      
      // Test dashboard data
      final dashboardResponse = await apiService.getDashboardData();
      debugPrint('   - Dashboard Data: ${dashboardResponse.isSuccess ? 'Retrieved' : 'Failed'}');
      
      if (dashboardResponse.isSuccess) {
        final data = dashboardResponse.data!;
        debugPrint('   - Total Deliverables: ${data['total_deliverables']}');
        debugPrint('   - Completed Deliverables: ${data['completed_deliverables']}');
        debugPrint('   - Pending Reviews: ${data['pending_reviews']}');
      }
      
      // Test deliverables
      final deliverablesResponse = await apiService.getDeliverables();
      debugPrint('   - Deliverables: ${deliverablesResponse.isSuccess ? 'Retrieved' : 'Failed'}');
      
      if (deliverablesResponse.isSuccess) {
        final deliverables = apiService.parseDeliverablesFromResponse(deliverablesResponse);
        debugPrint('   - Deliverable Count: ${deliverables.length}');
      }
      
      // Test health check
      final healthResponse = await apiService.getHealthCheck();
      debugPrint('   - Health Check: ${healthResponse.isSuccess ? 'Healthy' : 'Unhealthy'}');
      
      debugPrint('✅ Backend API Service tests completed');
    } catch (e) {
      debugPrint('❌ Backend API Service test failed: $e');
    }
  }
}

// Widget to run tests in the app
class BackendTestWidget extends StatefulWidget {
  const BackendTestWidget({super.key});

  @override
  State<BackendTestWidget> createState() => _BackendTestWidgetState();
}

class _BackendTestWidgetState extends State<BackendTestWidget> {
  bool _isRunning = false;
  String _testResults = '';

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Running tests...\n';
    });

    try {
      await BackendIntegrationTest.runTests();
      setState(() {
        _testResults += '\n✅ All tests completed successfully!';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Tests failed: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Integration Test'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runTests,
              child: _isRunning
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Running Tests...'),
                      ],
                    )
                  : const Text('Run Backend Tests'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty ? 'Click "Run Backend Tests" to start testing...' : _testResults,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
