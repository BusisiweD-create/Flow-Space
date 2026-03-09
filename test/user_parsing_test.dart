
import 'package:flutter_test/flutter_test.dart';
import 'package:khono/models/user.dart';
import 'package:khono/models/user_role.dart';

void main() {
  group('User.fromJson', () {
    test('parses backend response format (snake_case, split name)', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'first_name': 'Test',
        'last_name': 'User',
        'role': 'systemAdmin',
        'is_active': true,
        'created_at': '2023-01-01T00:00:00.000Z',
        'last_login': '2023-01-02T00:00:00.000Z'
      };

      final user = User.fromJson(json);

      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, UserRole.systemAdmin);
      expect(user.isActive, true);
      expect(user.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
      expect(user.lastLoginAt, DateTime.parse('2023-01-02T00:00:00.000Z'));
    });

    test('parses mixed format (camelCase fallback)', () {
      final json = {
        'id': '456',
        'email': 'camel@example.com',
        'name': 'Camel Case',
        'role': 'projectManager',
        'isActive': false,
        'createdAt': '2023-01-01T00:00:00.000Z',
        'lastLoginAt': '2023-01-02T00:00:00.000Z'
      };

      final user = User.fromJson(json);

      expect(user.name, 'Camel Case');
      expect(user.role, UserRole.projectManager);
      expect(user.isActive, false);
    });
    
    test('handles empty name fields', () {
      final json = {
        'id': '789',
        'email': 'empty@example.com',
        'role': 'teamMember',
        'created_at': '2023-01-01T00:00:00.000Z'
      };

      final user = User.fromJson(json);

      expect(user.name, '');
      expect(user.role, UserRole.teamMember);
    });
  });
}
