import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/admin/models/bus_schedule_model.dart';

void main() {
  group('BusScheduleModel & Official Timetable PDF Data Tests', () {
    test('Monday schedule matches official PDF w.e.f. 27-07-2026', () {
      final mon = OfficialBusScheduleData.mondaySchedule;
      expect(mon.dayId, 'monday');
      expect(mon.dayTitle, 'Monday');
      expect(mon.trips.length, 7);

      // Trip 1: Railway Station only on Monday's
      final trip1 = mon.trips[0];
      expect(trip1.title, contains("Pickup from Railway Station only on Monday's"));
      expect(trip1.departureTime, '05:05 AM');
      expect(trip1.arrivalTime, '05:40 AM');
      expect(trip1.note, contains('10 minutes after arrival of train'));
      expect(trip1.stops.length, 4);

      // Trip 2: Local Round Trip
      final trip2 = mon.trips[1];
      expect(trip2.departureTime, '08:15 AM');
      expect(trip2.arrivalTime, '08:50 AM');
      expect(trip2.stops.length, 7);

      // Trip 7: Last Trip
      final trip7 = mon.trips[6];
      expect(trip7.departureTime, '07:00 PM');
      expect(trip7.arrivalTime, '07:43 PM');
    });

    test('Tuesday - Thursday schedule contains 6 regular trips', () {
      final tt = OfficialBusScheduleData.tuesdayThursdaySchedule;
      expect(tt.dayId, 'tuesday_thursday');
      expect(tt.trips.length, 6);
      expect(tt.trips[0].departureTime, '08:15 AM');
      expect(tt.trips.last.arrivalTime, '07:43 PM');
    });

    test('Friday schedule matches official PDF (9 trips)', () {
      final fri = OfficialBusScheduleData.fridaySchedule;
      expect(fri.dayId, 'friday');
      expect(fri.trips.length, 9);

      // Trip 5: Added Bela Chowk trip at 05:30 PM
      final trip5 = fri.trips[4];
      expect(trip5.title, contains('Local Trip to Bela Chowk and back Added'));
      expect(trip5.departureTime, '05:30 PM');
      expect(trip5.arrivalTime, '05:57 PM');

      // Trip 9: Late night trip at 10:00 PM with notice
      final trip9 = fri.trips[8];
      expect(trip9.departureTime, '10:00 PM');
      expect(trip9.arrivalTime, '10:30 PM');
      expect(trip9.note, contains('First come first serve basis only'));
    });

    test('Saturday & Holidays schedule contains 7 trips starting at 08:30 AM', () {
      final sat = OfficialBusScheduleData.saturdayHolidaysSchedule;
      expect(sat.dayId, 'saturday_holidays');
      expect(sat.trips.length, 7);
      expect(sat.trips.first.departureTime, '08:30 AM');
      expect(sat.trips.first.arrivalTime, '09:05 AM');
    });

    test('Sunday schedule contains 6 trips starting at 10:30 AM', () {
      final sun = OfficialBusScheduleData.sundaySchedule;
      expect(sun.dayId, 'sunday');
      expect(sun.trips.length, 6);
      expect(sun.trips.first.departureTime, '10:30 AM');
      expect(sun.trips.first.arrivalTime, '10:58 AM');
    });

    test('DayBusSchedule serializes toMap and parses fromMap correctly', () {
      final original = OfficialBusScheduleData.mondaySchedule;
      final map = original.toMap();
      final recreated = DayBusSchedule.fromMap(map);

      expect(recreated.dayId, original.dayId);
      expect(recreated.dayTitle, original.dayTitle);
      expect(recreated.trips.length, original.trips.length);
      expect(recreated.trips[0].title, original.trips[0].title);
      expect(recreated.trips[0].stops.length, original.trips[0].stops.length);
    });

    test('dayIdForDate maps weekday dates accurately', () {
      // 2026-07-27 is a Monday
      expect(OfficialBusScheduleData.dayIdForDate(DateTime(2026, 7, 27)), 'monday');
      // 2026-07-28 is a Tuesday
      expect(OfficialBusScheduleData.dayIdForDate(DateTime(2026, 7, 28)), 'tuesday_thursday');
      // 2026-07-31 is a Friday
      expect(OfficialBusScheduleData.dayIdForDate(DateTime(2026, 7, 31)), 'friday');
      // 2026-08-01 is a Saturday
      expect(OfficialBusScheduleData.dayIdForDate(DateTime(2026, 8, 1)), 'saturday_holidays');
      // 2026-08-02 is a Sunday
      expect(OfficialBusScheduleData.dayIdForDate(DateTime(2026, 8, 2)), 'sunday');
    });
  });
}

