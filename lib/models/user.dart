// ignore_for_file: unnecessary_import

import 'package:flutter/material.dart';
import 'user_role.dart';

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final List<String> projectIds;
  final Map<String, dynamic> preferences;
  final bool emailVerified;
  final DateTime? emailVerifiedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.projectIds = const [],
    this.preferences = const {},
    this.emailVerified = false,
    this.emailVerifiedAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    List<String>? projectIds,
    Map<String, dynamic>? preferences,
    bool? emailVerified,
    DateTime? emailVerifiedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      projectIds: projectIds ?? this.projectIds,
      preferences: preferences ?? this.preferences,
      emailVerified: emailVerified ?? this.emailVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'projectIds': projectIds,
      'preferences': preferences,
      'emailVerified': emailVerified,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Debug logging removed for production
    
    try {
      
      return User(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.teamMember,
        ),
        avatarUrl: json['avatarUrl'],
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
        isActive: json['isActive'] ?? true,
        projectIds: List<String>.from(json['projectIds'] ?? []),
        preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
        emailVerified: json['emailVerified'] ?? false,
        emailVerifiedAt: json['emailVerifiedAt'] != null ? DateTime.parse(json['emailVerifiedAt'] as String) : null,
      );
    } catch (e) {
      // Error logging removed for production
      rethrow;
    }
  }

  // Permission checking methods
  bool hasPermission(String permissionName) {
    return PermissionManager.hasPermission(role, permissionName);
  }

  bool canCreateDeliverable() => hasPermission('create_deliverable');
  bool canEditDeliverable() => hasPermission('edit_deliverable');
  bool canSubmitForReview() => hasPermission('submit_for_review');
  bool canApproveDeliverable() => hasPermission('approve_deliverable');
  bool canViewTeamDashboard() => hasPermission('view_team_dashboard');
  bool canViewClientReview() => hasPermission('view_client_review');
  bool canManageUsers() => hasPermission('manage_users');
  bool canViewAuditLogs() => hasPermission('view_audit_logs');
  bool canOverrideReadinessGate() => hasPermission('override_readiness_gate');
  bool canViewAllDeliverables() => hasPermission('view_all_deliverables');

  // Role checking methods
  bool get isTeamMember => role == UserRole.teamMember;
  bool get isDeliveryLead => role == UserRole.deliveryLead;
  bool get isClientReviewer => role == UserRole.clientReviewer;
  bool get isSystemAdmin => role == UserRole.systemAdmin;

  // UI helper methods
  String get roleDisplayName => role.displayName;
  String get roleDescription => role.description;
  Color get roleColor => role.color;
  IconData get roleIcon => role.icon;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
