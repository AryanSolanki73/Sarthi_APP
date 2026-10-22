import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/app.dart';

void main() {
  testWidgets('shows the Sarthi college sign-in page', (WidgetTester tester) async {
    await tester.pumpWidget(const SarthiApp());
    await tester.pumpAndSettle();

    expect(find.text('Your campus.\nOne easy ride.'), findsOneWidget);
    expect(find.text('Sign in with college email'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('New to Sarthi? Sign Up'), findsOneWidget);
  });
}
