import 'package:flutter/material.dart';

enum UserRole {
  teamMember,
  deliveryLead,
  clientReviewer,
  systemAdmin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.teamMember:
        return 'Team Member';
      case UserRole.deliveryLead:
        return 'Delivery Lead';
      case UserRole.clientReviewer:
        return 'Client Reviewer';
      case UserRole.systemAdmin:
        return 'System Admin';
    }
  }

  String get description {
    switch (this) {
      case UserRole.teamMember:
        return 'Can create deliverables and view own work';
      case UserRole.deliveryLead:
        return 'Can manage team and submit for client review';
      case UserRole.clientReviewer:
        return 'Can review and approve deliverables';
      case UserRole.systemAdmin:
        return 'Full system access and administration';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.teamMember:
        return Colors.blue;
      case UserRole.deliveryLead:
        return Colors.orange;
      case UserRole.clientReviewer:
        return Colors.green;
      case UserRole.systemAdmin:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.teamMember:
        return Icons.person;
      case UserRole.deliveryLead:
        return Icons.leaderboard;
      case UserRole.clientReviewer:
        return Icons.verified_user;
      case UserRole.systemAdmin:
        return Icons.admin_panel_settings;
    }
  }
}

class Permission {
  final String name;
  final String description;
  final List<UserRole> allowedRoles;

  const Permission({
    required this.name,
    required this.description,
    required this.allowedRoles,
  });
}

class PermissionManager {
  static const Map<String, Permission> _permissions = {
    'create_deliverable': Permission(
      name: 'Create Deliverable',
      description: 'Create new deliverables',
      allowedRoles: [UserRole.teamMember, UserRole.deliveryLead, UserRole.systemAdmin],
    ),
    'edit_deliverable': Permission(
      name: 'Edit Deliverable',
      description: 'Edit existing deliverables',
      allowedRoles: [UserRole.teamMember, UserRole.deliveryLead, UserRole.systemAdmin],
    ),
    'submit_for_review': Permission(
      name: 'Submit for Review',
      description: 'Submit deliverables for client review',
      allowedRoles: [UserRole.deliveryLead, UserRole.systemAdmin],
    ),
    'approve_deliverable': Permission(
      name: 'Approve Deliverable',
      description: 'Approve or reject deliverables',
      allowedRoles: [UserRole.clientReviewer, UserRole.systemAdmin],
    ),
    'view_team_dashboard': Permission(
      name: 'View Team Dashboard',
      description: 'View team performance dashboard',
      allowedRoles: [UserRole.deliveryLead, UserRole.systemAdmin],
    ),
    'view_client_review': Permission(
      name: 'View Client Review',
      description: 'Access client review interface',
      allowedRoles: [UserRole.clientReviewer, UserRole.systemAdmin],
    ),
    'manage_users': Permission(
      name: 'Manage Users',
      description: 'Manage user accounts and roles',
      allowedRoles: [UserRole.systemAdmin],
    ),
    'view_audit_logs': Permission(
      name: 'View Audit Logs',
      description: 'View system audit logs',
      allowedRoles: [UserRole.systemAdmin],
    ),
    'override_readiness_gate': Permission(
      name: 'Override Readiness Gate',
      description: 'Override release readiness gates',
      allowedRoles: [UserRole.deliveryLead, UserRole.systemAdmin],
    ),
    'view_all_deliverables': Permission(
      name: 'View All Deliverables',
      description: 'View all team deliverables',
      allowedRoles: [UserRole.deliveryLead, UserRole.systemAdmin],
    ),
  };

  static bool hasPermission(UserRole userRole, String permissionName) {
    final permission = _permissions[permissionName];
    if (permission == null) return false;
    return permission.allowedRoles.contains(userRole);
  }

  static List<Permission> getPermissionsForRole(UserRole userRole) {
    return _permissions.values
        .where((permission) => permission.allowedRoles.contains(userRole))
        .toList();
  }

  static List<String> getPermissionNamesForRole(UserRole userRole) {
    return _permissions.entries
        .where((entry) => entry.value.allowedRoles.contains(userRole))
        .map((entry) => entry.key)
        .toList();
  }
}
