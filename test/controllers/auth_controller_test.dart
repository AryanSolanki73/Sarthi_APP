import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';
import 'package:sarthi_app/services/auth_service.dart';

void main() {
  group('AuthController Unit Tests', () {
    late AuthController controller;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      controller = AuthController(mockAuthService);
    });

    test('validateCollegeEmail accepts valid @iitrpr.ac.in addresses', () {
      expect(controller.validateCollegeEmail('student@iitrpr.ac.in'), isNull);
      expect(controller.validateCollegeEmail('2021csb1088@iitrpr.ac.in'), isNull);
      expect(controller.validateCollegeEmail('admin@gmail.com'), contains('@iitrpr.ac.in'));
      expect(controller.validateCollegeEmail(''), contains('Enter your college email'));
    });

    test('validatePhoneNumber validates 10-digit phone numbers', () {
      expect(controller.validatePhoneNumber('9876543210'), isNull);
      expect(controller.validatePhoneNumber('+91 98765 43210'), isNull);
      expect(controller.validatePhoneNumber('12345'), contains('10-digit'));
      expect(controller.validatePhoneNumber(''), contains('Enter your phone number'));
    });

    test('validateHostel validates hostel length', () {
      expect(controller.validateHostel('Satluj'), isNull);
      expect(controller.validateHostel(''), contains('Please select or enter your hostel'));
      expect(controller.validateHostel('A'), contains('Please select or enter your hostel'));
    });

    test('validateName validates full name / username', () {
      expect(controller.validateName('Aryan'), isNull);
      expect(controller.validateName('A'), contains('Enter your full name'));
      expect(controller.validateName(''), contains('Enter your full name'));
    });

    test('getUserProfile and saveUserProfile interact with service correctly', () async {
      final initial = await controller.getUserProfile('mock_google_uid');
      expect(initial, isNotNull);
      expect(initial!.role, 'student');

      final updated = initial.copyWith(
        name: 'New Name',
        hostel: 'Chenab (Boys Hostel)',
        phoneNumber: '9123456780',
      );
      await controller.saveUserProfile(updated);

      final fetched = await controller.getUserProfile('mock_google_uid');
      expect(fetched?.name, 'New Name');
      expect(fetched?.hostel, 'Chenab (Boys Hostel)');
      expect(fetched?.phoneNumber, '9123456780');
      expect(fetched?.role, 'student');
      expect(fetched?.isProfileComplete, isTrue);
    });
  });
}
