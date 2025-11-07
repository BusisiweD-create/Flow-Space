// ignore_for_file: unused_import, unused_local_variable, require_trailing_commas

import 'package:flutter/material.dart';
import '../models/deliverable.dart';
import '../models/sprint.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  
  factory MockDataService() {
    return _instance;
  }
  
  MockDataService._internal();
  
  // Mock deliverables data
  List<Deliverable> getMockDeliverables() {
    final now = DateTime.now();
    return [
      Deliverable(
        id: '1',
        title: 'User Authentication Module',
        description: 'Implement JWT-based authentication system with refresh tokens',
        status: DeliverableStatus.approved,
        createdAt: DateTime(2024, 1, 15),
        dueDate: DateTime(2024, 2, 1),
        sprintIds: ['1'],
        definitionOfDone: [
          'JWT token generation and validation',
          'Refresh token rotation',
          'Password hashing with bcrypt',
          'Rate limiting on auth endpoints'
        ],
        evidenceLinks: ['https://github.com/project/auth-module'],
        approvedAt: DateTime(2024, 2, 1),
        approvedBy: 'client@example.com',
      ),
      Deliverable(
        id: '2',
        title: 'Dashboard Analytics',
        description: 'Create performance metrics dashboard with charts and visualizations',
        status: DeliverableStatus.submitted,
        createdAt: DateTime(2024, 1, 20),
        dueDate: DateTime(2024, 2, 10),
        sprintIds: ['1', '2'],
        definitionOfDone: [
          'Real-time data visualization',
          'Performance metrics calculation',
          'Responsive design for mobile',
          'Export functionality'
        ],
        evidenceLinks: ['https://github.com/project/dashboard'],
        submittedAt: DateTime(2024, 2, 5),
        submittedBy: 'dev@example.com',
      ),
      Deliverable(
        id: '3',
        title: 'API Documentation',
        description: 'Generate comprehensive API documentation with examples',
        status: DeliverableStatus.draft,
        createdAt: DateTime(2024, 1, 25),
        dueDate: DateTime(2024, 2, 15),
        sprintIds: ['2'],
        definitionOfDone: [
          'OpenAPI/Swagger specification',
          'Interactive API playground',
          'Code examples in multiple languages',
          'Authentication guide'
        ],
        evidenceLinks: [],
      ),
      Deliverable(
        id: '4',
        title: 'Mobile App UI',
        description: 'Design and implement mobile application user interface',
        status: DeliverableStatus.changeRequested,
        createdAt: DateTime(2024, 2, 1),
        dueDate: DateTime(2024, 2, 20),
        sprintIds: ['2'],
        definitionOfDone: [
          'Cross-platform compatibility',
          'Touch-optimized interface',
          'Offline functionality',
          'Push notifications'
        ],
        evidenceLinks: ['https://github.com/project/mobile-ui'],
        clientComment: 'Please improve the navigation flow and add dark mode support',
        submittedAt: DateTime(2024, 2, 12),
        submittedBy: 'designer@example.com',
      ),
      Deliverable(
        id: '5',
        title: 'Database Migration',
        description: 'Migrate from SQLite to PostgreSQL with data preservation',
        status: DeliverableStatus.approved,
        createdAt: DateTime(2024, 1, 10),
        dueDate: DateTime(2024, 1, 30),
        sprintIds: ['1'],
        definitionOfDone: [
          'Schema migration scripts',
          'Data validation and integrity checks',
          'Performance benchmarking',
          'Rollback procedure'
        ],
        evidenceLinks: ['https://github.com/project/db-migration'],
        approvedAt: DateTime(2024, 1, 28),
        approvedBy: 'dba@example.com',
      ),
    ];
  }
  
  // Mock sprints data
  List<Sprint> getMockSprints() {
    final now = DateTime.now();
    return [
      Sprint(
        id: '1',
        name: 'Sprint 1 - Foundation',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        committedPoints: 40,
        completedPoints: 38,
        velocity: 35,
        testPassRate: 95.5,
        defectCount: 2,
        carriedOverPoints: 2,
        scopeChanges: ['Added user profile feature'],
        notes: 'Strong start with good velocity. Minor scope changes handled well.',
        isActive: false,
      ),
      Sprint(
        id: '2',
        name: 'Sprint 2 - Features',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 29),
        committedPoints: 45,
        completedPoints: 32,
        velocity: 40,
        testPassRate: 92.0,
        defectCount: 5,
        carriedOverPoints: 13,
        scopeChanges: ['Enhanced dashboard requirements'],
        notes: 'Focused on core feature development. Some carryover expected.',
        isActive: true,
      ),
      Sprint(
        id: '3',
        name: 'Sprint 3 - Polish',
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 3, 31),
        committedPoints: 35,
        completedPoints: 0,
        velocity: 0,
        testPassRate: 0.0,
        defectCount: 0,
        carriedOverPoints: 0,
        scopeChanges: [],
        notes: 'Upcoming sprint focused on polishing and bug fixes.',
        isActive: false,
      ),
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