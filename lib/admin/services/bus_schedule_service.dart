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
    if (_scheduleRef == null) return;
    try {
      final updated = schedule.copyWith(lastUpdated: DateTime.now());
      await _scheduleRef!.doc(schedule.dayId).set(updated.toMap());
    } catch (e) {
      debugPrint('Error saving bus schedule: $e');
      rethrow;
    }
  }

  /// Sets this schedule as the active live timetable in the student app.
  /// Synchronizes all active trips into the `buses` collection so students see
  /// today's real bus schedule on `TransitHomeView`.
  Future<void> publishScheduleToLiveBuses(DayBusSchedule schedule) async {
    // 1. Save to schedule collection
    await saveSchedule(schedule);

    if (_busesRef == null) return;

    try {
      // 2. Fetch existing buses to update or clean
      final existingBuses = await _busesRef!.get();
      final batch = _firestore!.batch();

      // Clear previous auto-scheduled buses or mark them
      for (final doc in existingBuses.docs) {
        batch.delete(doc.reference);
      }

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

      await batch.commit();
    } catch (e) {
      debugPrint('Error publishing bus schedule to live app: $e');
      rethrow;
    }
  }

  /// Resets a day's schedule back to the official IIT Ropar PDF timetable defaults.
  Future<DayBusSchedule> resetScheduleToDefault(String dayId) async {
    final defaultSchedule =
        OfficialBusScheduleData.allDefaultSchedules[dayId] ??
            OfficialBusScheduleData.mondaySchedule;

    if (_scheduleRef != null) {
      try {
        await _scheduleRef!.doc(dayId).delete();
      } catch (e) {
        debugPrint('Error deleting custom schedule doc: $e');
      }
    }

    return defaultSchedule;
  }
}

