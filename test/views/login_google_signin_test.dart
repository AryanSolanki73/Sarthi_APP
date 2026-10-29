import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';
import 'package:sarthi_app/models/user_profile.dart';
import 'package:sarthi_app/services/auth_service.dart';
import 'package:sarthi_app/views/login_page.dart';

void main() {
  group('LoginPage Google Sign-In Domain Restriction Tests', () {
    testWidgets('Rejects Google Sign-In with non-iitrpr email and shows SnackBar error', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = MockAuthService();
      mockAuth.mockProfile = UserProfile(
        uid: 'gmail_user_uid',
        name: 'Gmail User',
        email: 'user@gmail.com',
        role: 'student',
      );

      final controller = AuthController(mockAuth);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(authController: controller),
        ),
      );
      await tester.pump();

      // Find Google Sign-In button and ensure visible
      final googleButton = find.text('Sign in with Google');
      expect(googleButton, findsOneWidget);
      await tester.ensureVisible(googleButton);
      await tester.pumpAndSettle();

      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      // Ensure error SnackBar is displayed
      expect(find.text('Only @iitrpr.ac.in email addresses are allowed.'), findsOneWidget);

      // Verify user remains on LoginPage
      expect(find.text('Sign in with college email'), findsOneWidget);
    });

    testWidgets('Accepts Google Sign-In with valid @iitrpr.ac.in email for new user', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockAuth = MockAuthService();
      mockAuth.mockProfile = UserProfile(
        uid: 'valid_iitrpr_uid',
        name: 'IIT Ropar Student',
        email: 'student@iitrpr.ac.in',
        role: 'student', // incomplete profile -> leads to complete profile setup
      );

      final controller = AuthController(mockAuth);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(authController: controller),
        ),
      );
      await tester.pump();

      final googleButton = find.text('Sign in with Google');
      expect(googleButton, findsOneWidget);
      await tester.ensureVisible(googleButton);
      await tester.pumpAndSettle();

      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      // User navigates away from LoginPage to Profile Setup
      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(find.text('Sign in with college email'), findsNothing);
    });
  });
}
