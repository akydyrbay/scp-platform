import 'package:flutter_test/flutter_test.dart';
import 'package:scp_mobile_shared/utils/app_validators.dart';

void main() {
  group('AppValidators', () {
    group('validateEmail', () {
      test('should return null for valid email', () {
        expect(AppValidators.validateEmail('test@example.com'), isNull);
        expect(AppValidators.validateEmail('user.name@domain.co.uk'), isNull);
        expect(AppValidators.validateEmail('test+tag@example.com'), isNull);
      });

      test('should return error message for invalid email', () {
        expect(AppValidators.validateEmail('invalid'), isNotNull);
        expect(AppValidators.validateEmail('invalid@'), isNotNull);
        expect(AppValidators.validateEmail('@example.com'), isNotNull);
        expect(AppValidators.validateEmail(''), isNotNull);
        expect(AppValidators.validateEmail(null), isNotNull);
      });
    });

    group('validatePassword', () {
      test('should return null for valid password', () {
        expect(AppValidators.validatePassword('password123'), isNull);
        expect(AppValidators.validatePassword('SecureP@ssw0rd'), isNull);
        expect(AppValidators.validatePassword('a'.padRight(8, 'b')), isNull);
      });

      test('should return error message for invalid password', () {
        expect(AppValidators.validatePassword('short'), isNotNull);
        expect(AppValidators.validatePassword(''), isNotNull);
        expect(AppValidators.validatePassword(null), isNotNull);
      });
    });

    group('validatePhone', () {
      test('should return null for valid phone number', () {
        expect(AppValidators.validatePhone('+1234567890'), isNull);
        expect(AppValidators.validatePhone('1234567890'), isNull);
      });

      test('should return error message for invalid phone number', () {
        expect(AppValidators.validatePhone('123'), isNotNull);
        expect(AppValidators.validatePhone(''), isNotNull);
        expect(AppValidators.validatePhone(null), isNotNull);
      });
    });

    group('validateRequired', () {
      test('should return null for non-empty value', () {
        expect(AppValidators.validateRequired('test'), isNull);
        expect(AppValidators.validateRequired('test', fieldName: 'Name'), isNull);
      });

      test('should return error message for empty value', () {
        expect(AppValidators.validateRequired(''), isNotNull);
        expect(AppValidators.validateRequired(null), isNotNull);
        expect(AppValidators.validateRequired('', fieldName: 'Name'), isNotNull);
      });
    });

    group('validateQuantity', () {
      test('should return null for valid quantity', () {
        expect(AppValidators.validateQuantity('1'), isNull);
        expect(AppValidators.validateQuantity('10'), isNull);
        expect(AppValidators.validateQuantity('5', min: 1), isNull);
      });

      test('should return error message for invalid quantity', () {
        expect(AppValidators.validateQuantity(''), isNotNull);
        expect(AppValidators.validateQuantity(null), isNotNull);
        expect(AppValidators.validateQuantity('abc'), isNotNull);
        expect(AppValidators.validateQuantity('0', min: 1), isNotNull);
      });
    });

    // Add more validator tests as needed
  });
}

