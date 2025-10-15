// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  await authService.initialize();
  
  print('=== Current User Information ===');
  print('Is Authenticated: ${authService.isAuthenticated}');
  print('Current User: ${authService.currentUser?.name ?? "None"}');
  print('User Role: ${authService.currentUserRole?.name ?? "None"}');
  print('Role Display Name: ${authService.currentUser?.roleDisplayName ?? "None"}');
  print('Is System Admin: ${authService.isSystemAdmin}');
  print('Can Manage Users: ${authService.canManageUsers()}');
  print('Has manage_users permission: ${authService.hasPermission("manage_users")}');
  
  print('\n=== Available Permissions ===');
  final permissions = authService.getCurrentUserPermissions();
  if (permissions.isEmpty) {
    print('No permissions available');
  } else {
    for (var permission in permissions) {
      print('- $permission');
    }
  }
  
  print('\n=== Settings Access ===');
  print('Can see Settings in sidebar: ${authService.hasPermission("manage_users")}');
}