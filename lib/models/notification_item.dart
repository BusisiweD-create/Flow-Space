enum NotificationType {
  approval,
  deliverable,
  sprint,
  repository,
  system,
  team,
  file,
  reportSubmission,      // Report submitted for review
  reportApproved,        // Report approved by client
  reportChangesRequested, // Changes requested on report
}

enum NotificationAction {
  approvalRequest,
  approvalReminder,
  approvalApproved,
  approvalRejected,
  deliverableCreated,
  deliverableUpdated,
  sprintStarted,
  sprintCompleted,
  systemError,
  general,
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final bool isRead;
  final NotificationType type;
  final String message;
  final DateTime timestamp;
  final NotificationAction action;
  final String? relatedId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.isRead,
    required this.type,
    required this.message,
    required this.timestamp,
    this.action = NotificationAction.general,
    this.relatedId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    bool? isRead,
    NotificationType? type,
    String? message,
    DateTime? timestamp,
    NotificationAction? action,
    String? relatedId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'action': action.name,
      'relatedId': relatedId,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // Map backend type names to frontend enum
    NotificationType parseType(String? typeString) {
      if (typeString == null) return NotificationType.system;
      
      // Handle backend type names (with underscores)
      final typeMap = {
        'report_submission': NotificationType.reportSubmission,
        'report_approved': NotificationType.reportApproved,
        'report_changes_requested': NotificationType.reportChangesRequested,
      };
      
      // Check if it's a backend type
      if (typeMap.containsKey(typeString)) {
        return typeMap[typeString]!;
      }
      
      // Otherwise, try to match frontend enum directly
      try {
        return NotificationType.values.firstWhere(
          (e) => e.name == typeString,
          orElse: () => NotificationType.system,
        );
      } catch (e) {
        return NotificationType.system;
      }
    }
    
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Notification',
      description: json['message'] ?? json['description'] ?? '',
      date: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : 
            (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      type: parseType(json['type']),
      message: json['message'] ?? '',
<<<<<<< HEAD
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      action: json['action'] != null ? NotificationAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => NotificationAction.general,
      ) : NotificationAction.general,
      relatedId: json['relatedId'],
=======
      timestamp: json['createdAt'] != null ? DateTime.parse(json['createdAt']) :
                 (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
>>>>>>> origin/Busisiwe
    );
  }
}
