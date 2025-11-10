// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'lib/services/user_data_service.dart';
import 'lib/services/auth_service.dart';
import 'lib/models/user_role.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing User Management Functionality');
  print('=' * 50);
  
  final authService = AuthService();
  final userDataService = UserDataService();
  
  try {
    // Initialize services
    print('1. Initializing services...');
    await authService.initialize();
    print('✅ Auth service initialized');
    
    // Test getting all users
    print('\n2. Testing getUsers()...');
    final users = await userDataService.getUsers();
    print('✅ Retrieved ${users.length} users');
    
    if (users.isNotEmpty) {
      final firstUser = users.first;
      print('   First user: ${firstUser.name} (${firstUser.email})');
      print('   Role: ${firstUser.role}');
      print('   Active: ${firstUser.isActive}');
      
      // Test getting user by ID
      print('\n3. Testing getUserById()...');
      final userById = await userDataService.getUserById(firstUser.id);
      if (userById != null) {
        print('✅ Retrieved user by ID: ${userById.name}');
      } else {
        print('❌ Failed to get user by ID');
      }
    }
    
    // Test searching users
    print('\n4. Testing searchUsers()...');
    final searchResults = await userDataService.searchUsers('admin');
    print('✅ Search found ${searchResults.length} users');
    
    // Test getting users by role
    print('\n5. Testing getUsersByRole()...');
    final adminUsers = await userDataService.getUsersByRole(UserRole.systemAdmin);
    print('✅ Found ${adminUsers.length} system admin users');
    
    print('\n🎉 User management functionality test completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ Error during user management test:');
    print('   Error: $e');
    print('   Stack trace: $stackTrace');
  }
}