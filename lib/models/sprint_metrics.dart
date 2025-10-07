import 'package:flutter/material.dart';

class SprintMetrics {
  final String id;
  final String sprintId;
  final int committedPoints;
  final int completedPoints;
  final int carriedOverPoints;
  final double testPassRate;
  final int defectsOpened;
  final int defectsClosed;
  final int criticalDefects;
  final int highDefects;
  final int mediumDefects;
  final int lowDefects;
  final double codeReviewCompletion;
  final double documentationStatus;
  final String? risks;
  final String? mitigations;
  final String? scopeChanges;
  final String? uatNotes;
  final DateTime recordedAt;
  final String recordedBy;

  const SprintMetrics({
    required this.id,
    required this.sprintId,
    required this.committedPoints,
    required this.completedPoints,
    required this.carriedOverPoints,
    required this.testPassRate,
    required this.defectsOpened,
    required this.defectsClosed,
    required this.criticalDefects,
    required this.highDefects,
    required this.mediumDefects,
    required this.lowDefects,
    required this.codeReviewCompletion,
    required this.documentationStatus,
    this.risks,
    this.mitigations,
    this.scopeChanges,
    this.uatNotes,
    required this.recordedAt,
    required this.recordedBy,
  });

  SprintMetrics copyWith({
    String? id,
    String? sprintId,
    int? committedPoints,
    int? completedPoints,
    int? carriedOverPoints,
    double? testPassRate,
    int? defectsOpened,
    int? defectsClosed,
    int? criticalDefects,
    int? highDefects,
    int? mediumDefects,
    int? lowDefects,
    double? codeReviewCompletion,
    double? documentationStatus,
    String? risks,
    String? mitigations,
    String? scopeChanges,
    String? uatNotes,
    DateTime? recordedAt,
    String? recordedBy,
  }) {
    return SprintMetrics(
      id: id ?? this.id,
      sprintId: sprintId ?? this.sprintId,
      committedPoints: committedPoints ?? this.committedPoints,
      completedPoints: completedPoints ?? this.completedPoints,
      carriedOverPoints: carriedOverPoints ?? this.carriedOverPoints,
      testPassRate: testPassRate ?? this.testPassRate,
      defectsOpened: defectsOpened ?? this.defectsOpened,
      defectsClosed: defectsClosed ?? this.defectsClosed,
      criticalDefects: criticalDefects ?? this.criticalDefects,
      highDefects: highDefects ?? this.highDefects,
      mediumDefects: mediumDefects ?? this.mediumDefects,
      lowDefects: lowDefects ?? this.lowDefects,
      codeReviewCompletion: codeReviewCompletion ?? this.codeReviewCompletion,
      documentationStatus: documentationStatus ?? this.documentationStatus,
      risks: risks ?? this.risks,
      mitigations: mitigations ?? this.mitigations,
      scopeChanges: scopeChanges ?? this.scopeChanges,
      uatNotes: uatNotes ?? this.uatNotes,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sprintId': sprintId,
      'committedPoints': committedPoints,
      'completedPoints': completedPoints,
      'carriedOverPoints': carriedOverPoints,
      'testPassRate': testPassRate,
      'defectsOpened': defectsOpened,
      'defectsClosed': defectsClosed,
      'criticalDefects': criticalDefects,
      'highDefects': highDefects,
      'mediumDefects': mediumDefects,
      'lowDefects': lowDefects,
      'codeReviewCompletion': codeReviewCompletion,
      'documentationStatus': documentationStatus,
      'risks': risks,
      'mitigations': mitigations,
      'scopeChanges': scopeChanges,
      'uatNotes': uatNotes,
      'recordedAt': recordedAt.toIso8601String(),
      'recordedBy': recordedBy,
    };
  }

  factory SprintMetrics.fromJson(Map<String, dynamic> json) {
    return SprintMetrics(
      id: json['id'],
      sprintId: json['sprintId'],
      committedPoints: json['committedPoints'],
      completedPoints: json['completedPoints'],
      carriedOverPoints: json['carriedOverPoints'],
      testPassRate: json['testPassRate']?.toDouble() ?? 0.0,
      defectsOpened: json['defectsOpened'],
      defectsClosed: json['defectsClosed'],
      criticalDefects: json['criticalDefects'],
      highDefects: json['highDefects'],
      mediumDefects: json['mediumDefects'],
      lowDefects: json['lowDefects'],
      codeReviewCompletion: json['codeReviewCompletion']?.toDouble() ?? 0.0,
      documentationStatus: json['documentationStatus']?.toDouble() ?? 0.0,
      risks: json['risks'],
      mitigations: json['mitigations'],
      scopeChanges: json['scopeChanges'],
      uatNotes: json['uatNotes'],
      recordedAt: DateTime.parse(json['recordedAt']),
      recordedBy: json['recordedBy'],
    );
  }

  // Calculated properties
  double get velocity => completedPoints.toDouble();
  double get completionRate => committedPoints > 0 ? (completedPoints / committedPoints) * 100 : 0.0;
  int get totalDefects => defectsOpened;
  int get netDefects => defectsOpened - defectsClosed;
  double get defectResolutionRate => defectsOpened > 0 ? (defectsClosed / defectsOpened) * 100 : 0.0;
  
  Color get qualityStatusColor {
    if (testPassRate >= 95 && netDefects <= 2) return Colors.green;
    if (testPassRate >= 90 && netDefects <= 5) return Colors.orange;
    return Colors.red;
  }

  String get qualityStatusText {
    if (testPassRate >= 95 && netDefects <= 2) return 'Excellent';
    if (testPassRate >= 90 && netDefects <= 5) return 'Good';
    return 'Needs Attention';
  }
}
