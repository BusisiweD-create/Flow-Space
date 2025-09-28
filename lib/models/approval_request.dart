enum ApprovalStatus {
  pending,
  approved,
  denied,
}

class ApprovalRequest {
  final String id;
  final String itemName;
  final String requester;
  final DateTime date;
  final ApprovalStatus status;
  final String description;

  const ApprovalRequest({
    required this.id,
    required this.itemName,
    required this.requester,
    required this.date,
    required this.status,
    required this.description,
  });

  ApprovalRequest copyWith({
    String? id,
    String? itemName,
    String? requester,
    DateTime? date,
    ApprovalStatus? status,
    String? description,
  }) {
    return ApprovalRequest(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      requester: requester ?? this.requester,
      date: date ?? this.date,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }
}
