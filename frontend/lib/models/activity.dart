enum ActivityType {
  deliverable,
  sprint,
  user,
  general,
}

class ActivityEvent {
  final String id;
  final ActivityType type;
  final String message;
  final DateTime timestamp;
  final String? userId;
  final String? userName;
  final Map<String, dynamic>? data;

  ActivityEvent({
    String? id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.userId,
    this.userName,
    this.data,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  @override
  String toString() {
    return 'ActivityEvent(type: \$type, message: "\$message", timestamp: \$timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityEvent &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}