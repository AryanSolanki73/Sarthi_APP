import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/admin/models/bus_schedule_model.dart';
import 'package:sarthi_app/admin/screen/bus_schedule_screen.dart';
import 'package:sarthi_app/admin/services/bus_schedule_service.dart';

class MockBusScheduleService extends BusScheduleService {
  DayBusSchedule? lastPublishedSchedule;
  bool publishCalled = false;

  @override
  Future<DayBusSchedule> getScheduleForDay(String dayId) async {
    return OfficialBusScheduleData.allDefaultSchedules[dayId] ??
        OfficialBusScheduleData.mondaySchedule;
  }

  @override
  Future<void> saveSchedule(DayBusSchedule schedule) async {}

  @override
  Future<void> publishScheduleToLiveBuses(DayBusSchedule schedule) async {
    publishCalled = true;
    lastPublishedSchedule = schedule;
  }

  @override
  Future<DayBusSchedule> resetScheduleToDefault(String dayId) async {
    return OfficialBusScheduleData.allDefaultSchedules[dayId] ??
        OfficialBusScheduleData.mondaySchedule;
  }
}

void main() {
  group('BusScheduleScreen Widget & Management Tests', () {
    testWidgets('Renders Monday schedule by default with official trips', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockBusScheduleService();

      await tester.pumpWidget(
        MaterialApp(
          home: BusScheduleScreen(service: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar header
      expect(find.text('Bus Schedule Manager'), findsOneWidget);
      expect(find.text('Bus Schedule for Monday'), findsOneWidget);

      // Verify Trip 1 (Pickup from Railway Station only on Monday's)
      expect(find.text("Pickup from Railway Station only on Monday's"), findsOneWidget);
      expect(find.text('05:05 AM → 05:40 AM'), findsOneWidget);
      expect(find.text('TRIP 1'), findsOneWidget);

      // Verify notice
      expect(find.textContaining('10 minutes after arrival of train'), findsOneWidget);
    });

    testWidgets('Switches to Friday schedule when Friday pill is tapped', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockBusScheduleService();

      await tester.pumpWidget(
        MaterialApp(
          home: BusScheduleScreen(service: mockService),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Friday tab
      final fridayTab = find.text('Friday');
      expect(fridayTab, findsOneWidget);
      await tester.tap(fridayTab);
      await tester.pumpAndSettle();

      expect(find.text('Bus Schedule for Friday'), findsOneWidget);

      // Verify Friday's first trip
      expect(find.text('Local Trip to Bus Stand and police lines'), findsOneWidget);
    });

    testWidgets('Publishes schedule to live app and shows confirmation', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockBusScheduleService();

      await tester.pumpWidget(
        MaterialApp(
          home: BusScheduleScreen(service: mockService),
        ),
      );
      await tester.pumpAndSettle();

      final publishBtn = find.text('Publish Weekly Schedule');
      expect(publishBtn, findsOneWidget);

      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      expect(mockService.publishCalled, isTrue);
      expect(mockService.lastPublishedSchedule?.dayId, 'monday');
      expect(find.textContaining('Weekly schedule published'), findsOneWidget);
    });

    testWidgets('Filters trips by search query', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockBusScheduleService();

      await tester.pumpWidget(
        MaterialApp(
          home: BusScheduleScreen(service: mockService),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Railway Station');
      await tester.pumpAndSettle();

      // Railway trip should be present
      expect(find.text("Pickup from Railway Station only on Monday's"), findsOneWidget);
    });
  });
}

