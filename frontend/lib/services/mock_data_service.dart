// ignore_for_file: unused_import, unused_local_variable, require_trailing_commas

import 'package:flutter/material.dart';
// Using simple map structures to avoid model dependencies

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  
  factory MockDataService() {
    return _instance;
  }
  
  MockDataService._internal();
  
  // Mock deliverables data
  List<Map<String, dynamic>> getMockDeliverables() {
    final now = DateTime.now();
    return [
      {
        'id': '1',
        'title': 'User Authentication Module',
        'description': 'Implement JWT-based authentication system with refresh tokens',
        'status': 'approved',
        'created_at': DateTime(2024, 1, 15).toIso8601String(),
        'due_date': DateTime(2024, 2, 1).toIso8601String(),
        'sprint_ids': ['1'],
        'definition_of_done': [
          'JWT token generation and validation',
          'Refresh token rotation',
          'Password hashing with bcrypt',
          'Rate limiting on auth endpoints'
        ],
        'evidence_links': ['https://github.com/project/auth-module'],
        'approved_at': DateTime(2024, 2, 1).toIso8601String(),
        'approved_by': 'client@example.com',
      },
      {
        'id': '2',
        'title': 'Dashboard Analytics',
        'description': 'Create performance metrics dashboard with charts and visualizations',
        'status': 'submitted',
        'created_at': DateTime(2024, 1, 20).toIso8601String(),
        'due_date': DateTime(2024, 2, 10).toIso8601String(),
        'sprint_ids': ['1', '2'],
        'definition_of_done': [
          'Real-time data visualization',
          'Performance metrics calculation',
          'Responsive design for mobile',
          'Export functionality'
        ],
        'evidence_links': ['https://github.com/project/dashboard'],
        'submitted_at': DateTime(2024, 2, 5).toIso8601String(),
        'submitted_by': 'dev@example.com',
      },
      {
        'id': '3',
        'title': 'API Documentation',
        'description': 'Generate comprehensive API documentation with examples',
        'status': 'draft',
        'created_at': DateTime(2024, 1, 25).toIso8601String(),
        'due_date': DateTime(2024, 2, 15).toIso8601String(),
        'sprint_ids': ['2'],
        'definition_of_done': [
          'OpenAPI/Swagger specification',
          'Interactive API playground',
          'Code examples in multiple languages',
          'Authentication guide'
        ],
        'evidence_links': [],
      },
      {
        'id': '4',
        'title': 'Mobile App UI',
        'description': 'Design and implement mobile application user interface',
        'status': 'change_requested',
        'created_at': DateTime(2024, 2, 1).toIso8601String(),
        'due_date': DateTime(2024, 2, 20).toIso8601String(),
        'sprint_ids': ['2'],
        'definition_of_done': [
          'Cross-platform compatibility',
          'Touch-optimized interface',
          'Offline functionality',
          'Push notifications'
        ],
        'evidence_links': ['https://github.com/project/mobile-ui'],
        'client_comment': 'Please improve the navigation flow and add dark mode support',
        'submitted_at': DateTime(2024, 2, 12).toIso8601String(),
        'submitted_by': 'designer@example.com',
      },
      {
        'id': '5',
        'title': 'Database Migration',
        'description': 'Migrate from SQLite to PostgreSQL with data preservation',
        'status': 'approved',
        'created_at': DateTime(2024, 1, 10).toIso8601String(),
        'due_date': DateTime(2024, 1, 30).toIso8601String(),
        'sprint_ids': ['1'],
        'definition_of_done': [
          'Schema migration scripts',
          'Data validation and integrity checks',
          'Performance benchmarking',
          'Rollback procedure'
        ],
        'evidence_links': ['https://github.com/project/db-migration'],
        'approved_at': DateTime(2024, 1, 28).toIso8601String(),
        'approved_by': 'dba@example.com',
      },
    ];
  }
  
  // Mock sprints data
  List<Map<String, dynamic>> getMockSprints() {
    final now = DateTime.now();
    return [
      {
        'id': '1',
        'name': 'Sprint 1 - Foundation',
        'start_date': DateTime(2024, 1, 1).toIso8601String(),
        'end_date': DateTime(2024, 1, 31).toIso8601String(),
        'committed_points': 40,
        'completed_points': 38,
        'velocity': 35,
        'test_pass_rate': 95.5,
        'defect_count': 2,
        'carried_over_points': 2,
        'scope_changes': ['Added user profile feature'],
        'notes': 'Strong start with good velocity. Minor scope changes handled well.',
        'is_active': false,
        'status': 'completed',
      },
      {
        'id': '2',
        'name': 'Sprint 2 - Features',
        'start_date': DateTime(2024, 2, 1).toIso8601String(),
        'end_date': DateTime(2024, 2, 29).toIso8601String(),
        'committed_points': 45,
        'completed_points': 32,
        'velocity': 40,
        'test_pass_rate': 92.0,
        'defect_count': 5,
        'carried_over_points': 13,
        'scope_changes': ['Enhanced dashboard requirements'],
        'notes': 'Focused on core feature development. Some carryover expected.',
        'is_active': true,
        'status': 'in_progress',
      },
      {
        'id': '3',
        'name': 'Sprint 3 - Polish',
        'start_date': DateTime(2024, 3, 1).toIso8601String(),
        'end_date': DateTime(2024, 3, 31).toIso8601String(),
        'committed_points': 35,
        'completed_points': 0,
        'velocity': 0,
        'test_pass_rate': 0.0,
        'defect_count': 0,
        'carried_over_points': 0,
        'scope_changes': [],
        'notes': 'Upcoming sprint focused on polishing and bug fixes.',
        'is_active': false,
        'status': 'planning',
      },
    ];
  }
  
  // Mock analytics data
  Map<String, dynamic> getMockAnalyticsData() {
    return {
      'overallMetrics': {
        'totalDeliverables': 15,
        'completedDeliverables': 8,
        'approvalRate': 73.3,
        'averageCycleTime': 7.2,
        'onTimeDeliveryRate': 86.7,
      },
      'sprintPerformance': {
        'averageVelocity': 38.3,
        'highestVelocity': 45,
        'lowestVelocity': 32,
        'velocityTrend': 'stable',
      },
      'qualityMetrics': {
        'defectDensity': 0.8,
        'testCoverage': 85.2,
        'codeReviewEffectiveness': 92.1,
        'technicalDebtRatio': 12.3,
      },
      'teamPerformance': {
        'capacityUtilization': 88.7,
        'focusFactor': 76.4,
        'collaborationScore': 89.2,
        'innovationRate': 15.8,
      },
      'recentActivity': [
        {
          'type': 'deliverable_approved',
          'title': 'User Authentication Module',
          'timestamp': DateTime(2024, 2, 1, 14, 30).toIso8601String(),
          'user': 'client@example.com',
        },
        {
          'type': 'deliverable_submitted',
          'title': 'Dashboard Analytics',
          'timestamp': DateTime(2024, 2, 5, 10, 15).toIso8601String(),
          'user': 'dev@example.com',
        },
        {
          'type': 'comment_added',
          'title': 'Mobile App UI',
          'timestamp': DateTime(2024, 2, 12, 16, 45).toIso8601String(),
          'user': 'designer@example.com',
        },
      ],
    };
  }
  
  // Check if we should use mock data (when backend is not available)
  static bool shouldUseMockData() {
    // For now, always use mock data until authentication is fixed
    return true;
  }
}