enum ApprovalStatus {
  pending,
  approved,
  rejected,
  // ignore: constant_identifier_names
  reminder_sent,
}

class FlowSpaceApprovalRequest {
  final String id;
  final String deliverableTitle;
  final String requesterName;
  final DateTime requestedAt;
  final ApprovalStatus status;
  final String comments;

  const FlowSpaceApprovalRequest({
    required this.id,
    required this.deliverableTitle,
    required this.requesterName,
    required this.requestedAt,
    required this.status,
    required this.comments,
  });

  FlowSpaceApprovalRequest copyWith({
    String? id,
    String? deliverableTitle,
    String? requesterName,
    DateTime? requestedAt,
    ApprovalStatus? status,
    String? comments,
  }) {
    return FlowSpaceApprovalRequest(
      id: id ?? this.id,
      deliverableTitle: deliverableTitle ?? this.deliverableTitle,
      requesterName: requesterName ?? this.requesterName,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliverableTitle': deliverableTitle,
      'requesterName': requesterName,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
      'comments': comments,
    };
  }

  factory FlowSpaceApprovalRequest.fromJson(Map<String, dynamic> json) {
    final deliverable = json['deliverable'] as Map<String, dynamic>?;
    final requester = json['requester'] as Map<String, dynamic>?;
    final statusString = (json['status'] ?? 'pending').toString();
    return FlowSpaceApprovalRequest(
      id: json['id'].toString(),
      deliverableTitle: (deliverable != null ? (deliverable['title'] ?? '') : '') as String,
      requesterName: (requester != null
              ? ('${((requester['first_name'] ?? '') as String).trim()} ${((requester['last_name'] ?? '') as String).trim()}').trim()
              : (json['requested_by']?.toString() ?? '')),
      requestedAt: DateTime.parse((json['requested_at'] ?? json['requestedAt'] ?? DateTime.now().toIso8601String()).toString()),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == statusString,
        orElse: () => ApprovalStatus.pending,
      ),
      comments: (json['comments'] ?? deliverable?['description'] ?? '')?.toString() ?? '',
    );
  }
}
