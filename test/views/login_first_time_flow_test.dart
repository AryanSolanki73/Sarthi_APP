import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/models/user_profile.dart';
import 'package:sarthi_app/services/auth_service.dart';
import 'package:sarthi_app/views/profile_page.dart';

void main() {
  group('First-Time Login Profile Setup Integration Flow', () {
    testWidgets('First-time user must complete profile info before proceeding', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = MockAuthService();
      bool flowFinished = false;
      bool navigatedToTransit = false;

      // Simulated new Google user profile with no hostel or phone
      final newGoogleUser = UserProfile(
        uid: 'google_fresh_uid',
        name: 'Fresh Student',
        email: 'fresh@iitrpr.ac.in',
        photoUrl: null,
        phoneNumber: null,
        hostel: null,
        role: 'student', // default student role
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            isFirstTimeSetup: true,
            initialProfile: newGoogleUser,
            authService: mockAuth,
            onProfileSaved: () {
              flowFinished = true;
            },
            onNavigateAfterSetup: (context) {
              navigatedToTransit = true;
            },
          ),
        ),
      );
      await tester.pump();

      // 1. Validate role is student by default
      expect(find.text('STUDENT'), findsOneWidget);

      // 2. Validate first-time onboarding screen elements
      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(find.text('First Time Setup'), findsOneWidget);

      // 3. User attempts to submit without hostel & phone
      final saveBtn = find.text('Save & Continue to Transit');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      expect(find.text('Please select or enter your hostel'), findsOneWidget);
      expect(find.text('Enter your phone number'), findsOneWidget);
      expect(flowFinished, isFalse);

      // 4. User selects hostel from dropdown and enters phone number
      final hostelDropdown = find.byKey(const Key('hostel_dropdown'));
      final phoneField = find.widgetWithText(TextFormField, 'Phone Number');

      await tester.tap(hostelDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Satluj (Boys Hostel)').last);
      await tester.pumpAndSettle();

      await tester.enterText(phoneField, '9876543210');
      await tester.pump();

      // 5. User taps Save & Continue
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // 6. Verify flow completion, persistence, and navigation
      expect(flowFinished, isTrue);
      expect(navigatedToTransit, isTrue);

      final storedProfile = await mockAuth.getUserProfile('google_fresh_uid');
      expect(storedProfile?.hostel, 'Satluj (Boys Hostel)');
      expect(storedProfile?.phoneNumber, '9876543210');
      expect(storedProfile?.role, 'student');
      expect(storedProfile?.isProfileComplete, isTrue);
    });
  });
}
