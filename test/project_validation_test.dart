import 'package:flutter_test/flutter_test.dart';
import 'package:khono/models/project.dart';
import 'package:khono/test_helpers/project_setup_test_helper.dart';

void main() {
  group('Project Validation Tests', () {
    late TestableProjectSetupScreen setupScreen;

    setUp(() {
      setupScreen = TestableProjectSetupScreen();
    });

    test('Project name validation - empty string', () {
      final result = setupScreen.validateField('name', '');
      expect(result, equals('Project name is required'));
    });

    test('Project name validation - too short', () {
      final result = setupScreen.validateField('name', 'ab');
      expect(result, equals('Project name must be at least 3 characters'));
    });

    test('Project name validation - too long', () {
      final result = setupScreen.validateField('name', 'a' * 101);
      expect(result, equals('Project name must not exceed 100 characters'));
    });

    test('Project name validation - invalid characters', () {
      final result = setupScreen.validateField('name', 'Project@Name');
      expect(result, equals('Project name can only contain letters, numbers, spaces, hyphens, and underscores'));
    });

    test('Project name validation - valid', () {
      final result = setupScreen.validateField('name', 'Valid Project Name-123');
      expect(result, isNull);
    });

    test('Project key validation - empty string', () {
      final result = setupScreen.validateField('key', '');
      expect(result, equals('Project key is required'));
    });

    test('Project key validation - too short', () {
      final result = setupScreen.validateField('key', 'a');
      expect(result, equals('Project key must be at least 2 characters'));
    });

    test('Project key validation - too long', () {
      final result = setupScreen.validateField('key', 'A' * 21);
      expect(result, equals('Project key must not exceed 20 characters'));
    });

    test('Project key validation - invalid format', () {
      final result = setupScreen.validateField('key', 'invalid-key');
      expect(result, equals('Project key must start with letter and contain only uppercase letters, numbers, and underscores'));
    });

    test('Project key validation - valid', () {
      final result = setupScreen.validateField('key', 'VALID_KEY_123');
      expect(result, isNull);
    });

    test('Description validation - empty string', () {
      final result = setupScreen.validateField('description', '');
      expect(result, equals('Description is required'));
    });

    test('Description validation - too short', () {
      final result = setupScreen.validateField('description', 'Short');
      expect(result, equals('Description must be at least 10 characters'));
    });

    test('Description validation - too long', () {
      final result = setupScreen.validateField('description', 'a' * 1001);
      expect(result, equals('Description must not exceed 1000 characters'));
    });

    test('Description validation - valid', () {
      final result = setupScreen.validateField('description', 'This is a valid project description');
      expect(result, isNull);
    });

    test('Client name validation - empty string', () {
      final result = setupScreen.validateField('clientName', '');
      expect(result, equals('Client name is required'));
    });

    test('Client name validation - too short', () {
      final result = setupScreen.validateField('clientName', 'a');
      expect(result, equals('Client name must be at least 2 characters'));
    });

    test('Client name validation - too long', () {
      final result = setupScreen.validateField('clientName', 'a' * 101);
      expect(result, equals('Client name must not exceed 100 characters'));
    });

    test('Client name validation - valid', () {
      final result = setupScreen.validateField('clientName', 'Valid Client Name');
      expect(result, isNull);
    });
  });

  group('Project Model Tests', () {
    test('Project should create with required fields', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        key: 'TEST',
        description: 'Test Description',
        clientName: 'Test Client',
        status: ProjectStatus.planning,
        priority: ProjectPriority.medium,
        projectType: 'software',
        startDate: DateTime.now(),
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      expect(project.name, equals('Test Project'));
      expect(project.description, equals('Test Description'));
      expect(project.clientName, equals('Test Client'));
      expect(project.projectType, equals('software'));
      expect(project.status, equals(ProjectStatus.planning));
      expect(project.priority, equals(ProjectPriority.medium));
    });

    test('Project should serialize to JSON correctly', () {
      final project = Project(
        id: '1',
        name: 'Test Project',
        key: 'TEST',
        description: 'Test Description',
        clientName: 'Test Client',
        status: ProjectStatus.planning,
        priority: ProjectPriority.medium,
        projectType: 'software',
        startDate: DateTime.now(),
        createdBy: 'user1',
        createdAt: DateTime.now(),
      );

      final json = project.toJson();
      expect(json['name'], equals('Test Project'));
      expect(json['description'], equals('Test Description'));
      expect(json['clientName'], equals('Test Client'));
      expect(json['projectType'], equals('software'));
      expect(json['status'], equals('planning'));
      expect(json['priority'], equals('medium'));
    });

    test('Project should deserialize from JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Project',
        'description': 'Test Description',
        'clientName': 'Test Client',
        'status': 'planning',
        'priority': 'medium',
        'projectType': 'software',
        'startDate': DateTime.now().toIso8601String(),
        'createdBy': 'user1',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final project = Project.fromJson(json);
      expect(project.name, equals('Test Project'));
      expect(project.description, equals('Test Description'));
      expect(project.clientName, equals('Test Client'));
      expect(project.projectType, equals('software'));
      expect(project.status, equals(ProjectStatus.planning));
      expect(project.priority, equals(ProjectPriority.medium));
    });

    test('Project status enum values', () {
      expect(ProjectStatus.planning.name, equals('planning'));
      expect(ProjectStatus.active.name, equals('active'));
      expect(ProjectStatus.onHold.name, equals('onHold'));
      expect(ProjectStatus.completed.name, equals('completed'));
      expect(ProjectStatus.cancelled.name, equals('cancelled'));
    });

    test('Project priority enum values', () {
      expect(ProjectPriority.low.name, equals('low'));
      expect(ProjectPriority.medium.name, equals('medium'));
      expect(ProjectPriority.high.name, equals('high'));
      expect(ProjectPriority.critical.name, equals('critical'));
    });
  });

  group('Project Type Tests', () {
    test('Project types should include expected values', () {
      final types = ['software', 'hardware', 'consulting', 'research', 'marketing', 'infrastructure', 'other'];
      expect(types, contains('software'));
      expect(types, contains('hardware'));
      expect(types, contains('consulting'));
      expect(types, contains('research'));
      expect(types, contains('marketing'));
      expect(types, contains('infrastructure'));
      expect(types, contains('other'));
      expect(types.length, equals(7));
    });
  });
}
