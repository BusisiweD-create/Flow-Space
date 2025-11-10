import 'package:flutter/material.dart';

enum DeliverableStatus {
  draft,
  submitted,
  approved,
  changeRequested,
  rejected,
}

class Deliverable {
  final String id;
  final String title;
  final String description;
  final DeliverableStatus status;
  final DateTime createdAt;
  final DateTime dueDate;
  final List<String> sprintIds;
  final List<String> definitionOfDone;
  final List<String> evidenceLinks;
  final String? clientComment;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? submittedBy;
  final DateTime? submittedAt;

  const Deliverable({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.dueDate,
    required this.sprintIds,
    required this.definitionOfDone,
    this.evidenceLinks = const [],
    this.clientComment,
    this.approvedAt,
    this.approvedBy,
    this.submittedBy,
    this.submittedAt,
  });

  Deliverable copyWith({
    String? id,
    String? title,
    String? description,
    DeliverableStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
    List<String>? sprintIds,
    List<String>? definitionOfDone,
    List<String>? evidenceLinks,
    String? clientComment,
    DateTime? approvedAt,
    String? approvedBy,
    String? submittedBy,
    DateTime? submittedAt,
  }) {
    return Deliverable(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      sprintIds: sprintIds ?? this.sprintIds,
      definitionOfDone: definitionOfDone ?? this.definitionOfDone,
      evidenceLinks: evidenceLinks ?? this.evidenceLinks,
      clientComment: clientComment ?? this.clientComment,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      submittedBy: submittedBy ?? this.submittedBy,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'sprintIds': sprintIds,
      'definitionOfDone': definitionOfDone,
      'evidenceLinks': evidenceLinks,
      'clientComment': clientComment,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'submittedBy': submittedBy,
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }

  factory Deliverable.fromJson(Map<String, dynamic> json) {
    return Deliverable(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: DeliverableStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => DeliverableStatus.draft,
      ),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      dueDate: DateTime.parse(json['dueDate']?.toString() ?? DateTime.now().toIso8601String()),
      sprintIds: List<String>.from(json['sprintIds'] ?? []),
      definitionOfDone: List<String>.from(json['definitionOfDone'] ?? []),
      evidenceLinks: List<String>.from(json['evidenceLinks'] ?? []),
      clientComment: json['clientComment']?.toString(),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']?.toString() ?? '') : null,
      approvedBy: json['approvedBy']?.toString(),
      submittedBy: json['submittedBy']?.toString(),
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']?.toString() ?? '') : null,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case DeliverableStatus.draft:
        return 'Draft';
      case DeliverableStatus.submitted:
        return 'Submitted';
      case DeliverableStatus.approved:
        return 'Approved';
      case DeliverableStatus.changeRequested:
        return 'Change Requested';
      case DeliverableStatus.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case DeliverableStatus.draft:
        return Colors.grey;
      case DeliverableStatus.submitted:
        return Colors.orange;
      case DeliverableStatus.approved:
        return Colors.green;
      case DeliverableStatus.changeRequested:
        return Colors.amber;
      case DeliverableStatus.rejected:
        return Colors.red;
    }
  }

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && status != DeliverableStatus.approved;
  }

  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }
}
