import 'package:flutter/material.dart';
import '../utils/type_converters.dart';

class Sprint {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int committedPoints;
  final int completedPoints;
  final int velocity;
  final double testPassRate;
  final int defectCount;
  final int carriedOverPoints;
  final List<String> scopeChanges;
  final String? notes;
  final bool isActive;

  const Sprint({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.committedPoints,
    required this.completedPoints,
    required this.velocity,
    required this.testPassRate,
    required this.defectCount,
    this.carriedOverPoints = 0,
    this.scopeChanges = const [],
    this.notes,
    this.isActive = false,
  });

  Sprint copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    int? committedPoints,
    int? completedPoints,
    int? velocity,
    double? testPassRate,
    int? defectCount,
    int? carriedOverPoints,
    List<String>? scopeChanges,
    String? notes,
    bool? isActive,
  }) {
    return Sprint(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      committedPoints: committedPoints ?? this.committedPoints,
      completedPoints: completedPoints ?? this.completedPoints,
      velocity: velocity ?? this.velocity,
      testPassRate: testPassRate ?? this.testPassRate,
      defectCount: defectCount ?? this.defectCount,
      carriedOverPoints: carriedOverPoints ?? this.carriedOverPoints,
      scopeChanges: scopeChanges ?? this.scopeChanges,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'committedPoints': committedPoints,
      'completedPoints': completedPoints,
      'velocity': velocity,
      'testPassRate': testPassRate,
      'defectCount': defectCount,
      'carriedOverPoints': carriedOverPoints,
      'scopeChanges': scopeChanges,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory Sprint.fromJson(Map<String, dynamic> json) {
    return Sprint(
      id: toStr(json['id']),
      name: toStr(json['name']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      committedPoints: toInt(json['committedPoints']),
      completedPoints: toInt(json['completedPoints']),
      velocity: toInt(json['velocity']),
      testPassRate: (json['testPassRate'] is String) ? double.tryParse(json['testPassRate']) ?? 0.0 : json['testPassRate'].toDouble(),
      defectCount: toInt(json['defectCount']),
      carriedOverPoints: toInt(json['carriedOverPoints']),
      scopeChanges: List<String>.from(json['scopeChanges'] ?? []),
      notes: toStr(json['notes']),
      isActive: toBool(json['isActive']),
    );
  }

  double get completionRate {
    if (committedPoints == 0) return 0.0;
    return (completedPoints / committedPoints) * 100;
  }

  int get remainingPoints {
    return committedPoints - completedPoints;
  }

  bool get isCompleted {
    return DateTime.now().isAfter(endDate);
  }

  bool get isInProgress {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  int get daysRemaining {
    if (isCompleted) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  Color get statusColor {
    if (isCompleted) {
      return completionRate >= 100 ? Colors.green : Colors.orange;
    } else if (isInProgress) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  String get statusText {
    if (isCompleted) {
      return completionRate >= 100 ? 'Completed' : 'Overdue';
    } else if (isInProgress) {
      return 'In Progress';
    } else {
      return 'Not Started';
    }
  }

  int get plannedPoints => committedPoints;

  String? get createdByName => null;
}

class SprintCreate {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int plannedPoints;
  final int committedPoints;
  final int completedPoints;
  final int velocity;
  final double testPassRate;
  final double codeCoverage;
  final int defectCount;
  final int escapedDefects;
  final int defectsClosed;
  final int carriedOverPoints;
  final int addedDuringSprint;
  final int removedDuringSprint;
  final List<String> scopeChanges;
  final String? notes;
  final double codeReviewCompletion;
  final String documentationStatus;
  final String uatNotes;
  final double uatPassRate;
  final int risksIdentified;
  final int risksMitigated;
  final String blockers;
  final String decisions;
  final bool isActive;

  const SprintCreate({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.plannedPoints,
    required this.committedPoints,
    required this.completedPoints,
    required this.velocity,
    required this.testPassRate,
    required this.codeCoverage,
    required this.defectCount,
    required this.escapedDefects,
    required this.defectsClosed,
    required this.carriedOverPoints,
    required this.addedDuringSprint,
    required this.removedDuringSprint,
    this.scopeChanges = const [],
    this.notes,
    this.codeReviewCompletion = 0.0,
    this.documentationStatus = '',
    this.uatNotes = '',
    this.uatPassRate = 0.0,
    this.risksIdentified = 0,
    this.risksMitigated = 0,
    this.blockers = '',
    this.decisions = '',
    this.isActive = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'plannedPoints': plannedPoints,
      'committedPoints': committedPoints,
      'completedPoints': completedPoints,
      'velocity': velocity,
      'testPassRate': testPassRate,
      'codeCoverage': codeCoverage,
      'defectCount': defectCount,
      'escapedDefects': escapedDefects,
      'defectsClosed': defectsClosed,
      'carriedOverPoints': carriedOverPoints,
      'addedDuringSprint': addedDuringSprint,
      'removedDuringSprint': removedDuringSprint,
      'scopeChanges': scopeChanges,
      'notes': notes,
      'codeReviewCompletion': codeReviewCompletion,
      'documentationStatus': documentationStatus,
      'uatNotes': uatNotes,
      'uatPassRate': uatPassRate,
      'risksIdentified': risksIdentified,
      'risksMitigated': risksMitigated,
      'blockers': blockers,
      'decisions': decisions,
      'isActive': isActive,
    };
  }
}

class SprintUpdate {
  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? committedPoints;
  final int? completedPoints;
  final int? velocity;
  final double? testPassRate;
  final int? defectCount;
  final int? carriedOverPoints;
  final List<String>? scopeChanges;
  final String? notes;
  final bool? isActive;

  const SprintUpdate({
    this.name,
    this.startDate,
    this.endDate,
    this.committedPoints,
    this.completedPoints,
    this.velocity,
    this.testPassRate,
    this.defectCount,
    this.carriedOverPoints,
    this.scopeChanges,
    this.notes,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (startDate != null) json['startDate'] = startDate!.toIso8601String();
    if (endDate != null) json['endDate'] = endDate!.toIso8601String();
    if (committedPoints != null) json['committedPoints'] = committedPoints;
    if (completedPoints != null) json['completedPoints'] = completedPoints;
    if (velocity != null) json['velocity'] = velocity;
    if (testPassRate != null) json['testPassRate'] = testPassRate;
    if (defectCount != null) json['defectCount'] = defectCount;
    if (carriedOverPoints != null) json['carriedOverPoints'] = carriedOverPoints;
    if (scopeChanges != null) json['scopeChanges'] = scopeChanges;
    if (notes != null) json['notes'] = notes;
    if (isActive != null) json['isActive'] = isActive;
    return json;
  }
}
