
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'requester': requester,
      'date': date.toIso8601String(),
      'status': status.name,
      'description': description,
    };
  }

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'],
      itemName: json['itemName'],
      requester: json['requester'],
      date: DateTime.parse(json['date']),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      description: json['description'],
    );
  }
}
