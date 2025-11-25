class ApprovalRequest {
  final String id;
  final String title;
  final String description;
  final String requestedBy;
  final String requestedByName;
  final DateTime requestedAt;
  final String status;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? reviewReason;
  final String priority;
  final String category;
  final String? deliverableId;

  ApprovalRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedAt,
    required this.status,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.reviewReason,
    required this.priority,
    required this.category,
    this.deliverableId,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requestedBy: json['requested_by'] ?? '',
      requestedByName: json['requested_by_name'] ?? '',
      requestedAt: DateTime.parse(json['requested_at'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      reviewedBy: json['reviewed_by'],
      reviewedByName: json['reviewed_by_name'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      reviewReason: json['review_reason'],
      priority: json['priority'] ?? 'medium',
      category: json['category'] ?? '',
      deliverableId: json['deliverableId']?.toString() ?? json['deliverable_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requested_by': requestedBy,
      'requested_by_name': requestedByName,
      'requested_at': requestedAt.toIso8601String(),
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_by_name': reviewedByName,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_reason': reviewReason,
      'priority': priority,
      'category': category,
      'deliverable_id': deliverableId,
    };
  }

  ApprovalRequest copyWith({
    String? id,
    String? title,
    String? description,
    String? requestedBy,
    String? requestedByName,
    DateTime? requestedAt,
    String? status,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
    String? reviewReason,
    String? priority,
    String? category,
    String? deliverableId,
  }) {
    return ApprovalRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewReason: reviewReason ?? this.reviewReason,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      deliverableId: deliverableId ?? this.deliverableId,
    );
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status.toUpperCase();
    }
  }

  String get priorityDisplay {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}