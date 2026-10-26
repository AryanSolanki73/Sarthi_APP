import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/models/user_profile.dart';
import 'package:sarthi_app/services/auth_service.dart';
import 'package:sarthi_app/views/profile_page.dart';

void main() {
  group('ProfilePage Widget & Integration Tests', () {
    late MockAuthService mockAuthService;
    late UserProfile sampleProfile;

    setUp(() {
      mockAuthService = MockAuthService();
      sampleProfile = UserProfile(
        uid: 'user_test_1',
        name: 'Aryan Solanki',
        email: 'aryan@iitrpr.ac.in',
        hostel: 'Satluj (Boys Hostel)',
        phoneNumber: '9876543210',
        role: 'student',
      );
    });

    testWidgets('renders user profile info, hostel, phone, and student role badge', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            initialProfile: sampleProfile,
            authService: mockAuthService,
          ),
        ),
      );
      await tester.pump();

      // Check title and details
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Aryan Solanki'), findsWidgets);
      expect(find.text('aryan@iitrpr.ac.in'), findsWidgets);
      expect(find.text('Satluj (Boys Hostel)'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      // Verify Role badge is STUDENT
      expect(find.text('STUDENT'), findsOneWidget);

      // Check institutional transit status
      expect(find.text('IIT Ropar Transit Network'), findsOneWidget);
      expect(find.text('Active Student Rider'), findsOneWidget);

      // Verify Log Out button is present
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('displays first-time setup banner and Save & Continue button on first login', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final incompleteProfile = UserProfile(
        uid: 'user_first_time',
        name: 'New Student',
        email: 'newstudent@iitrpr.ac.in',
        role: 'student',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            isFirstTimeSetup: true,
            initialProfile: incompleteProfile,
            authService: mockAuthService,
          ),
        ),
      );
      await tester.pump();

      // Verify first time header and banner
      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(find.text('First Time Setup'), findsOneWidget);
      expect(
        find.textContaining('Welcome to Sarthi! Please provide your phone number and hostel'),
        findsOneWidget,
      );

      // Verify Back button is not present on mandatory first-time onboarding
      expect(find.byType(BackButton), findsNothing);

      // Verify CTA button
      expect(find.text('Save & Continue to Transit'), findsOneWidget);
    });

    testWidgets('validates required hostel and phone number before saving', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final emptyProfile = UserProfile(
        uid: 'user_empty',
        name: 'Aryan',
        email: 'aryan@iitrpr.ac.in',
        role: 'student',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            isFirstTimeSetup: true,
            initialProfile: emptyProfile,
            authService: mockAuthService,
          ),
        ),
      );
      await tester.pump();

      // Ensure button is visible and tap Save
      final saveButton = find.text('Save & Continue to Transit');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      // Expect validation error messages
      expect(find.text('Please select or enter your hostel'), findsOneWidget);
      expect(find.text('Enter your phone number'), findsOneWidget);
    });

    testWidgets('successfully updates user profile details and triggers callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool savedCallbackTriggered = false;

      final initialIncomplete = UserProfile(
        uid: 'user_edit_test',
        name: 'Aman Kumar',
        email: 'aman@iitrpr.ac.in',
        role: 'student',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(
            isFirstTimeSetup: false,
            initialProfile: initialIncomplete,
            authService: mockAuthService,
            onProfileSaved: () {
              savedCallbackTriggered = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Tap Edit Profile icon button
      final editButton = find.byTooltip('Edit Profile');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pump();

      // Find Form fields
      final phoneField = find.widgetWithText(TextFormField, 'Phone Number');
      final hostelDropdown = find.byKey(const Key('hostel_dropdown'));

      expect(phoneField, findsOneWidget);
      expect(hostelDropdown, findsOneWidget);

      // Select hostel from dropdown
      await tester.tap(hostelDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chenab (Boys Hostel)').last);
      await tester.pumpAndSettle();

      // Enter valid phone number
      await tester.enterText(phoneField, '9812345678');
      await tester.pump();

      // Tap Save Changes
      final saveButton = find.text('Save Changes');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify callback triggered
      expect(savedCallbackTriggered, isTrue);

      // Verify updated details appear on screen
      expect(find.text('Chenab (Boys Hostel)'), findsOneWidget);
      expect(find.text('9812345678'), findsOneWidget);
    });
  });
}
