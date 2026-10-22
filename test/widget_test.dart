import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/app.dart';
import 'package:sarthi_app/views/splash_screen.dart';

void main() {
  testWidgets('shows the splash screen on launch with branding', (WidgetTester tester) async {
    await tester.pumpWidget(const SarthiApp(
      home: SplashScreen(minimumDuration: Duration(milliseconds: 300)),
    ));
    await tester.pump();

    expect(find.text('SARTHI'), findsOneWidget);
    expect(find.text('Your campus. One easy ride.'), findsOneWidget);
    expect(find.text('EV Carts • Campus Shuttles'), findsOneWidget);
    expect(find.text('IIT ROPAR TRANSIT NETWORK'), findsOneWidget);
    expect(find.byIcon(Icons.directions_bus), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('shows the Sarthi college sign-in page after splash transition', (WidgetTester tester) async {
    await tester.pumpWidget(const SarthiApp());
    await tester.pumpAndSettle();

    expect(find.text('Your campus.\nOne easy ride.'), findsOneWidget);
    expect(find.text('Sign in with college email'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
