import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/admin/screen/driver_management_screen.dart';

void main() {
  group('DriverManagementScreen Widget & Flow Tests', () {
    testWidgets('Renders Driver Management header and empty state when offline/empty', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar & breadcrumbs
      expect(find.text('Workspace  /  '), findsOneWidget);
      expect(find.text('Drivers'), findsOneWidget);

      // Add Driver button in top bar
      expect(find.widgetWithText(FilledButton, 'Add Driver'), findsOneWidget);

      // Header overview stats
      expect(find.text('TOTAL DRIVERS'), findsOneWidget);
      expect(find.text('ON DUTY / ACTIVE'), findsOneWidget);
      expect(find.text('EV CART OPERATORS'), findsOneWidget);
      expect(find.text('BUS DRIVERS'), findsOneWidget);

      // Search field
      expect(find.byType(TextField), findsOneWidget);

      // Filter chips
      expect(find.text('All Drivers'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('EV Carts'), findsOneWidget);
      expect(find.text('Buses'), findsOneWidget);

      // Empty state
      expect(find.text('No drivers added yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add First Driver'), findsOneWidget);
    });

    testWidgets('Opens Add Driver dialog and validates required fields', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Add Driver button
      await tester.tap(find.widgetWithText(FilledButton, 'Add Driver'));
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(find.text('Add New Driver'), findsOneWidget);
      expect(find.text('Driver Full Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
      expect(find.text('Driving License Number *'), findsOneWidget);
      expect(find.text('Assigned Vehicle Type'), findsOneWidget);
      expect(find.text('Duty Status'), findsOneWidget);

      // Attempt to submit empty form
      final submitButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Add Driver'),
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Enter full driver name'), findsOneWidget);
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('Enter license number'), findsOneWidget);

      // Fill in valid details
      await tester.enterText(find.widgetWithText(TextFormField, 'Driver Full Name *'), 'Ramesh Kumar');
      await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number *'), '9876543210');
      await tester.enterText(find.widgetWithText(TextFormField, 'Driving License Number *'), 'PB-12-2020-00123');
      await tester.pumpAndSettle();

      // Tap Cancel to dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Driver'), findsNothing);
    });
  });
}
