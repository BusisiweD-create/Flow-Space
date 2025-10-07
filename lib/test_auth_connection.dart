import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'models/user_role.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🧪 Testing Authentication and Database Connection...\n');
  
  final authService = AuthService();
  
  try {
    // Initialize the auth service
    debugPrint('1. Initializing Auth Service...');
    await authService.initialize();
    debugPrint('✅ Auth Service initialized successfully\n');
    
    // Test user registration
    debugPrint('2. Testing User Registration...');
    const email = 'test@example.com';
    const password = 'TestPassword123!';
    const name = 'Test User';
    const role = UserRole.teamMember;
    
    final signUpResult = await authService.signUp(email, password, name, role);
    if (signUpResult) {
      debugPrint('✅ User registration successful');
    } else {
      debugPrint('❌ User registration failed');
    }
    debugPrint('');
    
    // Test user login
    debugPrint('3. Testing User Login...');
    final signInResult = await authService.signIn(email, password);
    if (signInResult) {
      debugPrint('✅ User login successful');
      debugPrint('   Current user: ${authService.currentUser?.name}');
      debugPrint('   User role: ${authService.currentUser?.roleDisplayName}');
      debugPrint('   User permissions: ${authService.currentUser?.hasPermission('create_deliverable')}');
    } else {
      debugPrint('❌ User login failed');
    }
    debugPrint('');
    
    // Test role-based permissions
    debugPrint('4. Testing Role-Based Permissions...');
    if (authService.currentUser != null) {
      debugPrint('   Can create deliverable: ${authService.currentUser!.canCreateDeliverable()}');
      debugPrint('   Can submit for review: ${authService.currentUser!.canSubmitForReview()}');
      debugPrint('   Can approve deliverable: ${authService.currentUser!.canApproveDeliverable()}');
      debugPrint('   Can manage users: ${authService.currentUser!.canManageUsers()}');
    }
    debugPrint('');
    
    // Test logout
    debugPrint('5. Testing User Logout...');
    await authService.signOut();
    debugPrint('✅ User logout successful');
    debugPrint('   Is authenticated: ${authService.isAuthenticated}');
    debugPrint('');
    
    debugPrint('🎉 Authentication and Database Connection Test Complete!');
    
  } catch (e) {
    debugPrint('❌ Test failed with error: $e');
    debugPrint('\n💡 Troubleshooting Tips:');
    debugPrint('   - Make sure the backend server is running');
    debugPrint('   - Check database connection');
    debugPrint('   - Verify API endpoints are accessible');
  }
}
