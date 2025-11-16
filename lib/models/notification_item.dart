enum NotificationType {
  approval,
  deliverable,
  sprint,
  repository,
  system,
  team,
  file,
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
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      isRead: json['isRead'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      action: json['action'] != null ? NotificationAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => NotificationAction.general,
      ) : NotificationAction.general,
      relatedId: json['relatedId'],
    );
  }
}
