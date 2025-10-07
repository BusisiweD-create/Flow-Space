import 'package:flutter/material.dart';

enum ReportStatus {
  draft,
  submitted,
  underReview,
  approved,
  changeRequested,
  rejected,
}

class SignOffReport {
  final String id;
  final String deliverableId;
  final String reportTitle;
  final String reportContent;
  final List<String> sprintIds;
  final String? sprintPerformanceData;
  final String? knownLimitations;
  final String? nextSteps;
  final ReportStatus status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? submittedAt;
  final String? submittedBy;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? clientComment;
  final String? changeRequestDetails;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? digitalSignature;

  const SignOffReport({
    required this.id,
    required this.deliverableId,
    required this.reportTitle,
    required this.reportContent,
    required this.sprintIds,
    this.sprintPerformanceData,
    this.knownLimitations,
    this.nextSteps,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.submittedAt,
    this.submittedBy,
    this.reviewedAt,
    this.reviewedBy,
    this.clientComment,
    this.changeRequestDetails,
    this.approvedAt,
    this.approvedBy,
    this.digitalSignature,
  });

  SignOffReport copyWith({
    String? id,
    String? deliverableId,
    String? reportTitle,
    String? reportContent,
    List<String>? sprintIds,
    String? sprintPerformanceData,
    String? knownLimitations,
    String? nextSteps,
    ReportStatus? status,
    DateTime? createdAt,
    String? createdBy,
    DateTime? submittedAt,
    String? submittedBy,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? clientComment,
    String? changeRequestDetails,
    DateTime? approvedAt,
    String? approvedBy,
    String? digitalSignature,
  }) {
    return SignOffReport(
      id: id ?? this.id,
      deliverableId: deliverableId ?? this.deliverableId,
      reportTitle: reportTitle ?? this.reportTitle,
      reportContent: reportContent ?? this.reportContent,
      sprintIds: sprintIds ?? this.sprintIds,
      sprintPerformanceData: sprintPerformanceData ?? this.sprintPerformanceData,
      knownLimitations: knownLimitations ?? this.knownLimitations,
      nextSteps: nextSteps ?? this.nextSteps,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      clientComment: clientComment ?? this.clientComment,
      changeRequestDetails: changeRequestDetails ?? this.changeRequestDetails,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      digitalSignature: digitalSignature ?? this.digitalSignature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliverableId': deliverableId,
      'reportTitle': reportTitle,
      'reportContent': reportContent,
      'sprintIds': sprintIds,
      'sprintPerformanceData': sprintPerformanceData,
      'knownLimitations': knownLimitations,
      'nextSteps': nextSteps,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'submittedAt': submittedAt?.toIso8601String(),
      'submittedBy': submittedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'clientComment': clientComment,
      'changeRequestDetails': changeRequestDetails,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'digitalSignature': digitalSignature,
    };
  }

  factory SignOffReport.fromJson(Map<String, dynamic> json) {
    return SignOffReport(
      id: json['id'],
      deliverableId: json['deliverableId'],
      reportTitle: json['reportTitle'],
      reportContent: json['reportContent'],
      sprintIds: List<String>.from(json['sprintIds']),
      sprintPerformanceData: json['sprintPerformanceData'],
      knownLimitations: json['knownLimitations'],
      nextSteps: json['nextSteps'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.draft,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      submittedBy: json['submittedBy'],
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      reviewedBy: json['reviewedBy'],
      clientComment: json['clientComment'],
      changeRequestDetails: json['changeRequestDetails'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      approvedBy: json['approvedBy'],
      digitalSignature: json['digitalSignature'],
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ReportStatus.draft:
        return 'Draft';
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.approved:
        return 'Approved';
      case ReportStatus.changeRequested:
        return 'Change Requested';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case ReportStatus.draft:
        return Colors.grey;
      case ReportStatus.submitted:
        return Colors.blue;
      case ReportStatus.underReview:
        return Colors.orange;
      case ReportStatus.approved:
        return Colors.green;
      case ReportStatus.changeRequested:
        return Colors.amber;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }

  bool get isApproved => status == ReportStatus.approved;
  bool get isPendingReview => status == ReportStatus.submitted || status == ReportStatus.underReview;
  bool get needsChanges => status == ReportStatus.changeRequested;
}
