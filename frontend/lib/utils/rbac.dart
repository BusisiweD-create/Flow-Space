// ignore_for_file: use_super_parameters, prefer_final_locals

// Role-Based Access Control (RBAC) utilities for the Flutter frontend
// Provides role checking and permission validation for UI components

import 'package:flutter/material.dart';


enum UserRole {
  admin,
  manager,
  user,
  client,
}

enum Permission {
  // User management
  createUser,
  readUser,
  updateUser,
  deleteUser,
  
  // Deliverable management
  createDeliverable,
  readDeliverable,
  updateDeliverable,
  deleteDeliverable,
  
  // Sprint management
  createSprint,
  readSprint,
  updateSprint,
  deleteSprint,
  
  // Signoff management
  createSignoff,
  readSignoff,
  updateSignoff,
  approveSignoff,
  
  // Audit logs
  readAuditLogs,
  
  // System settings
  manageSettings,
  
  // Profile management
  updateProfile,
  readProfile,
}

class RBAC {
  static UserRole roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'user':
        return UserRole.user;
      case 'client':
        return UserRole.client;
      default:
        return UserRole.user; // Default to user for safety
    }
  }

  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.user:
        return 'user';
      case UserRole.client:
        return 'client';
    }
  }

  static bool hasPermission(UserRole role, Permission permission) {
    final permissions = _rolePermissions[role];
    return permissions?.contains(permission) ?? false;
  }

  static bool hasAnyPermission(UserRole role, List<Permission> permissions) {
    return permissions.any((permission) => hasPermission(role, permission));
  }

  static bool hasAllPermissions(UserRole role, List<Permission> permissions) {
    return permissions.every((permission) => hasPermission(role, permission));
  }

  static List<Permission> getPermissionsForRole(UserRole role) {
    return _rolePermissions[role] ?? [];
  }

  static bool canAccessEntity(UserRole currentUserRole, String? entityOwnerId, String currentUserId) {
    // Admins and managers can access all entities
    if (currentUserRole == UserRole.admin || currentUserRole == UserRole.manager) {
      return true;
    }

    // Users can access their own entities
    if (currentUserRole == UserRole.user && entityOwnerId != null && entityOwnerId == currentUserId) {
      return true;
    }

    // Clients have very limited access
    return false;
  }

  // Role-Permission mappings
  static final Map<UserRole, List<Permission>> _rolePermissions = {
    UserRole.admin: [
      Permission.createUser,
      Permission.readUser,
      Permission.updateUser,
      Permission.deleteUser,
      Permission.createDeliverable,
      Permission.readDeliverable,
      Permission.updateDeliverable,
      Permission.deleteDeliverable,
      Permission.createSprint,
      Permission.readSprint,
      Permission.updateSprint,
      Permission.deleteSprint,
      Permission.createSignoff,
      Permission.readSignoff,
      Permission.updateSignoff,
      Permission.approveSignoff,
      Permission.readAuditLogs,
      Permission.manageSettings,
      Permission.updateProfile,
      Permission.readProfile,
    ],
    UserRole.manager: [
      Permission.createDeliverable,
      Permission.readDeliverable,
      Permission.updateDeliverable,
      Permission.deleteDeliverable,
      Permission.createSprint,
      Permission.readSprint,
      Permission.updateSprint,
      Permission.deleteSprint,
      Permission.createSignoff,
      Permission.readSignoff,
      Permission.updateSignoff,
      Permission.approveSignoff,
      Permission.readAuditLogs,
      Permission.updateProfile,
      Permission.readProfile,
    ],
    UserRole.user: [
      Permission.readDeliverable,
      Permission.updateDeliverable,
      Permission.readSprint,
      Permission.createSignoff,
      Permission.readSignoff,
      Permission.updateSignoff,
      Permission.updateProfile,
      Permission.readProfile,
    ],
    UserRole.client: [
      Permission.readDeliverable,
      Permission.readSprint,
      Permission.readSignoff,
      Permission.readProfile,
    ],
  };
}

// Widget that conditionally shows content based on user role and permissions
class RoleBasedWidget extends StatelessWidget {
  final UserRole userRole;
  final List<Permission> requiredPermissions;
  final List<UserRole>? requiredRoles;
  final Widget child;
  final Widget? fallback;

  const RoleBasedWidget({
    Key? key,
    required this.userRole,
    required this.child,
    this.requiredPermissions = const [],
    this.requiredRoles,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool hasRequiredPermissions = requiredPermissions.isEmpty ||
        RBAC.hasAllPermissions(userRole, requiredPermissions);

    bool hasRequiredRole = requiredRoles == null ||
        requiredRoles!.contains(userRole);

    if (hasRequiredPermissions && hasRequiredRole) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

// Extension methods for easy role checking
extension UserRoleExtensions on UserRole {
  bool get isAdmin => this == UserRole.admin;
  bool get isManager => this == UserRole.manager;
  bool get isUser => this == UserRole.user;
  bool get isClient => this == UserRole.client;

  bool can(Permission permission) => RBAC.hasPermission(this, permission);
  bool canAny(List<Permission> permissions) => RBAC.hasAnyPermission(this, permissions);
  bool canAll(List<Permission> permissions) => RBAC.hasAllPermissions(this, permissions);

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.user:
        return 'User';
      case UserRole.client:
        return 'Client';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.user:
        return Colors.green;
      case UserRole.client:
        return Colors.orange;
    }
  }
}

// Provider for managing user role state
class RoleProvider with ChangeNotifier {
  UserRole? _currentRole;
  String? _userId;

  UserRole? get currentRole => _currentRole;
  String? get userId => _userId;

  void setRole(UserRole role, String userId) {
    _currentRole = role;
    _userId = userId;
    notifyListeners();
  }

  void clearRole() {
    _currentRole = null;
    _userId = null;
    notifyListeners();
  }

  bool hasPermission(Permission permission) {
    if (_currentRole == null) return false;
    return RBAC.hasPermission(_currentRole!, permission);
  }

  bool hasAnyPermission(List<Permission> permissions) {
    if (_currentRole == null) return false;
    return RBAC.hasAnyPermission(_currentRole!, permissions);
  }

  bool canAccessEntity(String? entityOwnerId) {
    if (_currentRole == null || _userId == null) return false;
    return RBAC.canAccessEntity(_currentRole!, entityOwnerId, _userId!);
  }
}