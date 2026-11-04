import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/bus_schedule_model.dart';

/// Service responsible for managing, persisting, and deploying bus schedules in Firestore.
class BusScheduleService {
  BusScheduleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  final FirebaseFirestore? _firestore;

  CollectionReference<Map<String, dynamic>>? get _scheduleRef =>
      _firestore?.collection('bus_schedules');

  CollectionReference<Map<String, dynamic>>? get _busesRef =>
      _firestore?.collection('buses');

  Future<bool> hasWeeklyScheduleBeenPublished() async {
    if (_scheduleRef == null) return false;
    final metadata = await _scheduleRef!.doc('active_meta').get();
    return metadata.data()?['isWeeklyPublished'] == true;
  }

  /// Fetches the schedule for a specific day ID. Returns the official PDF default
  /// if not customized in Firestore or if offline.
  Future<DayBusSchedule> getScheduleForDay(String dayId) async {
    final defaultSchedule =
        OfficialBusScheduleData.allDefaultSchedules[dayId] ??
            OfficialBusScheduleData.mondaySchedule;

    if (_scheduleRef == null) {
      return defaultSchedule;
    }

    try {
      final doc = await _scheduleRef!.doc(dayId).get();
      if (doc.exists && doc.data() != null) {
        return DayBusSchedule.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error loading bus schedule for $dayId: $e');
    }

    return defaultSchedule;
  }

  /// Saves a customized schedule for a day to Firestore.
  Future<void> saveSchedule(DayBusSchedule schedule) async {
    if (_scheduleRef == null) {
      throw StateError('Firebase is not initialized; the schedule was not saved.');
    }
    try {
      final updated = schedule.copyWith(lastUpdated: DateTime.now());
      await _scheduleRef!.doc(schedule.dayId).set(updated.toMap());
      final publishState = await _scheduleRef!.doc('active_meta').get();
      if (publishState.data()?['isWeeklyPublished'] == true) {
        await _syncDayToLiveBuses(updated);
      }
    } catch (e) {
      debugPrint('Error saving bus schedule: $e');
      rethrow;
    }
  }

  /// Publishes every weekday schedule once. The student app selects today's
  /// schedule from Firestore, and later edits sync automatically in saveSchedule.
  Future<void> publishScheduleToLiveBuses(DayBusSchedule schedule) async {
    if (_firestore == null || _busesRef == null) {
      throw StateError('Firebase is not initialized; the schedule was not published.');
    }

    try {
      // Save the currently displayed schedule before publishing the weekly set.
      await _scheduleRef!.doc(schedule.dayId).set(
        schedule.copyWith(lastUpdated: DateTime.now()).toMap(),
      );

      final schedules = <DayBusSchedule>[];
      for (final dayId in OfficialBusScheduleData.allDefaultSchedules.keys) {
        schedules.add(await getScheduleForDay(dayId));
      }

      // Remove prior schedule uploads while preserving unrelated bus records.
      final existingBuses = await _busesRef!.get();
      final batch = _firestore!.batch();
      final scheduledBuses = <String, Map<String, dynamic>>{};
      for (final daySchedule in schedules) {
        for (final trip in daySchedule.trips.where((trip) => trip.isActive)) {
          scheduledBuses['schedule_${daySchedule.dayId}_${trip.id}'] =
              _busData(daySchedule, trip);
        }
      }
      for (final doc in existingBuses.docs) {
        if (doc.data().containsKey('scheduleDayId') &&
            !scheduledBuses.containsKey(doc.id)) {
          batch.delete(doc.reference);
        }
      }
      for (final entry in scheduledBuses.entries) {
        batch.set(_busesRef!.doc(entry.key), entry.value);
      }

<<<<<<< HEAD
      // 3. Insert active trips from this schedule
      for (final trip in schedule.trips) {
        if (!trip.isActive) continue;

        final newDoc = _busesRef!.doc();
        batch.set(newDoc, {
          'route': trip.title,
          'departureTime': trip.departureTime,
          'arrivalTime': trip.arrivalTime,
          'availableSeats': trip.availableSeats,
          'totalSeats': trip.totalSeats,
          'registrationNumber': trip.registrationNumber,
          'isActive': true,
          'scheduleDayId': schedule.dayId,
          'tripNumber': trip.tripNumber,
          'stopsCount': trip.stops.length,
          'speed': '52 km/h',
          'currentStopIndex': 1,
          'stops': trip.stops
              .map(
                (s) => {
                  'name': s.stopName,
                  'time': s.time,
                  'type': s.type,
                  'subtext': s.type == 'departure'
                      ? 'Departure Point'
                      : (s.type == 'arrival'
                          ? 'Final Destination'
                          : 'Transit Halt'),
                },
              )
              .toList(),
          if (trip.note != null) 'note': trip.note,
        });
      }

      // Record metadata about the active published schedule
      if (_scheduleRef != null) {
        batch.set(_scheduleRef!.doc('active_meta'), {
          'activeDayId': schedule.dayId,
          'activeDayTitle': schedule.dayTitle,
          'publishedAt': FieldValue.serverTimestamp(),
          'totalActiveTrips': schedule.trips.where((t) => t.isActive).length,
        });
      }
=======
      batch.set(_scheduleRef!.doc('active_meta'), {
        'isWeeklyPublished': true,
        'publishedAt': FieldValue.serverTimestamp(),
        'scheduleDays': schedules.map((item) => item.dayId).toList(),
      }, SetOptions(merge: true));
>>>>>>> c8077c4d6a3e4c49ef7d68c98f2d602843538491

      await batch.commit();
    } catch (e) {
      debugPrint('Error publishing bus schedule to live app: $e');
      rethrow;
    }
  }

  Future<void> _syncDayToLiveBuses(DayBusSchedule schedule) async {
    final firestore = _firestore;
    final buses = _busesRef;
    if (firestore == null || buses == null) return;

    final current = await buses
        .where('scheduleDayId', isEqualTo: schedule.dayId)
        .get();
    final batch = firestore.batch();
    final scheduledBuses = <String, Map<String, dynamic>>{
      for (final trip in schedule.trips.where((trip) => trip.isActive))
        'schedule_${schedule.dayId}_${trip.id}': _busData(schedule, trip),
    };
    for (final doc in current.docs) {
      if (!scheduledBuses.containsKey(doc.id)) batch.delete(doc.reference);
    }
    for (final entry in scheduledBuses.entries) {
      batch.set(buses.doc(entry.key), entry.value);
    }
    await batch.commit();
  }

  Map<String, dynamic> _busData(DayBusSchedule schedule, ScheduledTrip trip) => {
        'route': trip.title,
        'departureTime': trip.departureTime,
        'arrivalTime': trip.arrivalTime,
        'availableSeats': trip.availableSeats,
        'totalSeats': trip.totalSeats,
        'registrationNumber': trip.registrationNumber,
        'isActive': true,
        'stops': trip.stops.map((stop) => stop.stopName).toList(),
        'scheduledStops': trip.stops.map((stop) => stop.toMap()).toList(),
        'scheduleDayId': schedule.dayId,
        'tripNumber': trip.tripNumber,
        'stopsCount': trip.stops.length,
        if (trip.note != null) 'note': trip.note,
      };

  /// Resets a day's schedule back to the official IIT Ropar PDF timetable defaults.
  Future<DayBusSchedule> resetScheduleToDefault(String dayId) async {
    final defaultSchedule =
        OfficialBusScheduleData.allDefaultSchedules[dayId] ??
            OfficialBusScheduleData.mondaySchedule;

    if (_scheduleRef != null) {
      try {
        await _scheduleRef!.doc(dayId).delete();
        final published = await _scheduleRef!.doc('active_meta').get();
        if (published.data()?['isWeeklyPublished'] == true) {
          await _syncDayToLiveBuses(defaultSchedule);
        }
      } catch (e) {
        debugPrint('Error deleting custom schedule doc: $e');
      }
    }

    return defaultSchedule;
  }
}

