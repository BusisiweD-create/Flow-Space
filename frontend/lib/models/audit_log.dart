
class AuditLog {
  final int id;
  final String entityType;
  final int entityId;
  final String action;
  final String userEmail;
  final String userRole;
  final String entityName;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? details;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.userEmail,
    required this.userRole,
    required this.entityName,
    this.oldValues,
    this.newValues,
    this.details,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as int,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as int,
      action: json['action'] as String,
      userEmail: json['user_email'] as String,
      userRole: json['user_role'] as String,
      entityName: json['entity_name'] as String,
      oldValues: json['old_values'] != null 
          ? Map<String, dynamic>.from(json['old_values'] as Map)
          : null,
      newValues: json['new_values'] != null
          ? Map<String, dynamic>.from(json['new_values'] as Map)
          : null,
      details: json['details'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'user_email': userEmail,
      'user_role': userRole,
      'entity_name': entityName,
      'old_values': oldValues,
      'new_values': newValues,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AuditLog(id: $id, entityType: $entityType, entityId: $entityId, action: $action, userEmail: $userEmail, createdAt: $createdAt)';
  }
}

class AuditLogCreate {
  final String entityType;
  final int entityId;
  final String action;
  final String userEmail;
  final String userRole;
  final String entityName;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? details;

  AuditLogCreate({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.userEmail,
    required this.userRole,
    required this.entityName,
    this.oldValues,
    this.newValues,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'user_email': userEmail,
      'user_role': userRole,
      'entity_name': entityName,
      'old_values': oldValues,
      'new_values': newValues,
      'details': details,
    };
  }

  @override
  String toString() {
    return 'AuditLogCreate(entityType: $entityType, entityId: $entityId, action: $action, userEmail: $userEmail)';
  }
}