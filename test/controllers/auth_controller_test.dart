import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';
import 'package:sarthi_app/models/user_profile.dart';
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

    test('isCollegeEmail verifies @iitrpr.ac.in domain', () {
      expect(AuthController.isCollegeEmail('student@iitrpr.ac.in'), isTrue);
      expect(AuthController.isCollegeEmail('2021csb1088@iitrpr.ac.in'), isTrue);
      expect(AuthController.isCollegeEmail('user@gmail.com'), isFalse);
      expect(AuthController.isCollegeEmail('user@yahoo.com'), isFalse);
      expect(AuthController.isCollegeEmail(''), isFalse);
      expect(AuthController.isCollegeEmail(null), isFalse);
    });

    test('signInWithGoogle accepts @iitrpr.ac.in domain accounts', () async {
      mockAuthService.mockProfile = UserProfile(
        uid: 'valid_iitrpr_uid',
        name: 'IIT Ropar Student',
        email: '2022csb1111@iitrpr.ac.in',
        role: 'student',
      );

      final profile = await controller.signInWithGoogle();
      expect(profile, isNotNull);
      expect(profile?.email, '2022csb1111@iitrpr.ac.in');
      expect(AuthController.isCollegeEmail(profile?.email), isTrue);
    });

    test('signInWithGoogle rejects non-iitrpr domains', () async {
      mockAuthService.mockProfile = UserProfile(
        uid: 'invalid_domain_uid',
        name: 'Outside User',
        email: 'user@gmail.com',
        role: 'student',
      );

      expect(
        () => controller.signInWithGoogle(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('@iitrpr.ac.in'),
          ),
        ),
      );
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
