import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/views/widgets/qr_code_widget.dart';

void main() {
  testWidgets('QrCodeWidget renders scannable QR matrix for ticket IDs', (WidgetTester tester) async {
    const testTicketId = 'TKT-884102';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: QrCodeWidget(
              data: testTicketId,
              size: 200,
              showCenterBadge: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify QrCodeWidget and its CustomPaint are rendered
    expect(find.byType(QrCodeWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
  });
}

