import 'package:flutter_test/flutter_test.dart';
import 'package:scp_mobile_shared/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create user from JSON', () {
      final json = {
        'id': 'user_123',
        'email': 'test@example.com',
        'first_name': 'John',
        'last_name': 'Doe',
        'company_name': 'Test Company',
        'phone_number': '+1234567890',
        'role': 'consumer',
        'profile_image_url': 'https://example.com/avatar.jpg',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('user_123'));
      expect(user.email, equals('test@example.com'));
      expect(user.firstName, equals('John'));
      expect(user.lastName, equals('Doe'));
      expect(user.companyName, equals('Test Company'));
      expect(user.phoneNumber, equals('+1234567890'));
      expect(user.role, equals('consumer'));
      expect(user.profileImageUrl, equals('https://example.com/avatar.jpg'));
      expect(user.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      expect(user.updatedAt, equals(DateTime.parse('2024-01-02T00:00:00Z')));
    });

    test('should create user with minimal required fields', () {
      final json = {
        'id': 'user_123',
        'email': 'test@example.com',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, equals('user_123'));
      expect(user.email, equals('test@example.com'));
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
      expect(user.companyName, isNull);
    });

    test('should generate fullName correctly', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        createdAt: DateTime.now(),
      );

      expect(user.fullName, equals('John Doe'));
    });

    test('should use company name when names are missing', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        companyName: 'Test Company',
        createdAt: DateTime.now(),
      );

      expect(user.fullName, equals('Test Company'));
    });

    test('should use email when all names are missing', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      expect(user.fullName, equals('test@example.com'));
    });

    test('should convert user to JSON', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
        companyName: 'Test Company',
        phoneNumber: '+1234567890',
        role: 'consumer',
        profileImageUrl: 'https://example.com/avatar.jpg',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00Z'),
      );

      final json = user.toJson();

      expect(json['id'], equals('user_123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['first_name'], equals('John'));
      expect(json['last_name'], equals('Doe'));
      expect(json['company_name'], equals('Test Company'));
      expect(json['phone_number'], equals('+1234567890'));
      expect(json['role'], equals('consumer'));
      expect(json['profile_image_url'], equals('https://example.com/avatar.jpg'));
      expect(json['created_at'], equals('2024-01-01T00:00:00.000Z'));
      expect(json['updated_at'], equals('2024-01-02T00:00:00.000Z'));
    });

    test('should handle equality correctly', () {
      final user1 = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final user2 = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      expect(user1, equals(user2));
    });
  });
}

