// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Testing System Administrator Login ===');
  print('Email: admin@flowspace.com');
  print('Password: password');
  print('');
  
  final authService = AuthService();
  await authService.initialize();
  
  // Try to sign in as system admin
  final success = await authService.signIn('admin@flowspace.com', 'password');
  
  if (success) {
    print('✅ Login successful!');
    print('User: ${authService.currentUser?.name ?? "Unknown"}');
    print('Role: ${authService.currentUserRole?.name ?? "Unknown"}');
    print('Role Display: ${authService.currentUser?.roleDisplayName ?? "Unknown"}');
    print('Is System Admin: ${authService.isSystemAdmin}');
    print('Can Manage Users: ${authService.canManageUsers()}');
    print('Has manage_users permission: ${authService.hasPermission("manage_users")}');
    print('');
    print('🎉 You should now see the Settings option in the sidebar!');
  } else {
    print('❌ Login failed. Please check:');
    print('1. Backend server is running on http://localhost:8000');
    print('2. Database has the test admin user');
    print('3. Try running the database setup script again');
  }
}