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
      committedPoints: json['committedPoints'],
      completedPoints: json['completedPoints'],
      velocity: json['velocity'],
      testPassRate: json['testPassRate'].toDouble(),
      defectCount: json['defectCount'],
      carriedOverPoints: json['carriedOverPoints'] ?? 0,
      scopeChanges: List<String>.from(json['scopeChanges'] ?? []),
      notes: toStr(json['notes']),
      isActive: json['isActive'] ?? false,
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
}
