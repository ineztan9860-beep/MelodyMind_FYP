import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth & Forgot Password Email Validation Tests', () {
    String? validateEmail(String? value) {
      if (value == null || value.trim().isEmpty) return 'Email cannot be empty';
      final emailRegex = RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}");
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
      return null;
    }

    test('valid emails pass validation', () {
      expect(validateEmail('test@gmail.com'), isNull);
      expect(validateEmail('student.inez@university.edu'), isNull);
      expect(validateEmail('user_123@domain.org'), isNull);
      expect(validateEmail('admin+testing@musicapp.io'), isNull);
    });

    test('empty or whitespace emails fail validation', () {
      expect(validateEmail(null), equals('Email cannot be empty'));
      expect(validateEmail(''), equals('Email cannot be empty'));
      expect(validateEmail('   '), equals('Email cannot be empty'));
    });

    test('malformed emails fail validation', () {
      expect(validateEmail('plainaddress'), equals('Please enter a valid email address'));
      expect(validateEmail('user@'), equals('Please enter a valid email address'));
      expect(validateEmail('@domain.com'), equals('Please enter a valid email address'));
      expect(validateEmail('user@domain'), equals('Please enter a valid email address'));
      expect(validateEmail('user@domain.'), equals('Please enter a valid email address'));
    });
  });
}
