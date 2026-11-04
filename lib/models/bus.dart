import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sarthi_app/admin/models/bus_schedule_model.dart';

/// Represents a single stop milestone along an active bus route.
class BusRouteStop {
  const BusRouteStop({
    required this.name,
    this.subtext,
    this.scheduledTime,
    this.isDeparted = false,
    this.isNext = false,
    this.isDestination = false,
    this.statusText,
    this.isDelayed = false,
    this.type,
  });

  final String name;
  final String? subtext;
  final String? scheduledTime;
  final bool isDeparted;
  final bool isNext;
  final bool isDestination;
  final String? statusText;
  final bool isDelayed;
  final String? type;

  BusRouteStop copyWith({
    String? name,
    String? subtext,
    String? scheduledTime,
    bool? isDeparted,
    bool? isNext,
    bool? isDestination,
    String? statusText,
    bool? isDelayed,
    String? type,
  }) {
    return BusRouteStop(
      name: name ?? this.name,
      subtext: subtext ?? this.subtext,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isDeparted: isDeparted ?? this.isDeparted,
      isNext: isNext ?? this.isNext,
      isDestination: isDestination ?? this.isDestination,
      statusText: statusText ?? this.statusText,
      isDelayed: isDelayed ?? this.isDelayed,
      type: type ?? this.type,
    );
  }

  factory BusRouteStop.fromDynamic(dynamic item) {
    if (item is String) {
      final trimmed = item.trim();
      return BusRouteStop(name: trimmed);
    } else if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final name = (map['name'] ?? map['stopName'] ?? map['title'] ?? '')
          .toString()
          .trim();
      final time = (map['time'] ?? map['departureTime'] ?? map['scheduledTime'])
          ?.toString();
      final type = (map['type'] ?? map['stopType'])?.toString();
      String? subtext =
          (map['subtext'] ?? map['note'] ?? map['description'])?.toString();
      if (subtext == null || subtext.isEmpty) {
        subtext = (type == 'departure'
            ? 'Departure Point'
            : (type == 'arrival' ? 'Final Destination' : 'Transit Halt'));
      }
      final status = (map['status'] ?? map['statusText'])?.toString();

      return BusRouteStop(
        name: name,
        scheduledTime: time,
        subtext: subtext,
        statusText: status,
        type: type,
        isDeparted: map['isDeparted'] as bool? ?? false,
        isNext: map['isNext'] as bool? ?? false,
        isDestination: map['isDestination'] as bool? ?? false,
        isDelayed: map['isDelayed'] as bool? ?? false,
      );
    }
    return BusRouteStop(name: item?.toString() ?? '');
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (scheduledTime != null) 'time': scheduledTime,
    if (subtext != null) 'subtext': subtext,
    if (statusText != null) 'status': statusText,
    if (type != null) 'type': type,
    'isDeparted': isDeparted,
    'isNext': isNext,
    'isDestination': isDestination,
    'isDelayed': isDelayed,
  };
}

/// Model representing a scheduled city bus route from Firebase Firestore.
class Bus {
  Bus({
    required this.id,
    required this.route,
    required this.departureTime,
    required this.availableSeats,
    this.totalSeats = 30,
    required this.registrationNumber,
    this.isActive = true,
    this.stops = const [],
    this.busType,
    this.speed = '64 km/h',
    this.currentLocation,
    this.currentStopIndex = 2,
    this.gpsAccuracy = 'Accurate to 5m',
    this.lastUpdated = '10s ago',
    this.arrivalTime,
    this.isCompleted = false,
    this.scheduleDayId,
  });

  final String id;
  final String route;
  final String departureTime;
  final String registrationNumber;
  final int totalSeats;
  int availableSeats;
  final bool isActive;
  final List<BusRouteStop> stops;
  final String? busType;
  final String speed;
  final String? currentLocation;
  final int currentStopIndex;
  final String gpsAccuracy;
  final String lastUpdated;
  final String? arrivalTime;
  final bool isCompleted;
  final String? scheduleDayId;

  bool get isFull => availableSeats <= 0;

  /// Number of onboarded passengers based on total seats and remaining available seats.
  int get onboardedPassengers =>
      (totalSeats - availableSeats).clamp(0, totalSeats);

  /// Occupancy ratio between 0.0 and 1.0.
  double get occupancyRate =>
      totalSeats > 0 ? (onboardedPassengers / totalSeats).clamp(0.0, 1.0) : 0.0;

  /// Bus service name: strictly uses the route name without hardcoded prefixes.
  String get displayName => route;

  /// Checks whether this trip has started (departed and actively running).
  /// If [targetDate] is provided, future dates or past dates are considered not actively running.
  bool isTripStarted({DateTime? targetDate}) {
    if (isCompleted) return false;

    final date = targetDate ?? DateTime.now();
    final now = DateTime.now();

    final isSameDay = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (!isSameDay) {
      return false;
    }

    final depMins = parseMinutesFromTimeString(departureTime);
    if (depMins == null) return false;

    final nowMins = now.hour * 60 + now.minute;
    return nowMins >= depMins;
  }

  /// Factory converting an official IIT Ropar timetable [ScheduledTrip] into a [Bus].
  static Bus fromScheduledTrip(
    ScheduledTrip trip, {
    required String dayId,
  }) {
    final routeStops = trip.stops.map((s) {
      return BusRouteStop(
        name: s.stopName,
        scheduledTime: s.time,
        type: s.type,
        subtext: s.type == 'departure'
            ? 'Departure Point'
            : (s.type == 'arrival' ? 'Final Destination' : 'Transit Halt'),
      );
    }).toList();

    return Bus(
      id: 'schedule_${dayId}_${trip.id}',
      route: trip.title,
      departureTime: trip.departureTime,
      arrivalTime: trip.arrivalTime,
      availableSeats: trip.availableSeats,
      totalSeats: trip.totalSeats,
      registrationNumber: trip.registrationNumber.isNotEmpty
          ? trip.registrationNumber
          : 'PB-12-Bus-${trip.tripNumber.toString().padLeft(2, '0')}',
      isActive: trip.isActive,
      stops: routeStops,
      busType: trip.title,
      speed: '48 km/h',
      currentStopIndex: 1,
      scheduleDayId: dayId,
    );
  }

  /// Live checkpoint description for the in-transit bus callout badge,
  /// derived strictly based on the route stops from Firebase.
  String get activeLocationNotice {
    if (!isTripStarted()) {
      return 'Departs at $departureTime • Scheduled';
    }

    final validStops = routeStops;
    if (validStops.isEmpty) {
      return currentLocation ?? 'En route';
    }

    final activeIdx = currentStopIndex.clamp(0, validStops.length - 1);

    // If an explicit location string is provided in Firebase, use it
    if (currentLocation != null && currentLocation!.trim().isNotEmpty) {
      return currentLocation!;
    }

    // Otherwise, compute the live location dynamically based on the stops
    if (activeIdx == 0) {
      return 'At ${validStops[0].name} (Boarding)';
    }

    final prevStop = validStops[activeIdx - 1];
    final nextStop = validStops[activeIdx];

    if (activeIdx == validStops.length - 1) {
      return 'Past ${prevStop.name} (Approaching Destination: ${nextStop.name})';
    }

    return 'Past ${prevStop.name} (En route to ${nextStop.name})';
  }

  /// Returns stop names for route selection, pickers, and modals directly from route data.
  List<String> get availableStops {
    if (stops.isNotEmpty) {
      final names = stops
          .map((s) => s.name.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names;
    }

    // If stops list was not explicitly stored, derive simply from route format "Start → End"
    if (route.contains('→')) {
      return route
          .split('→')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [route];
  }

  /// Returns detailed stop milestones for rendering the route timeline,
  /// updating each stop's departed / next / destination status based on
  /// currentStopIndex and scheduled stop times from Firebase.
  List<BusRouteStop> get routeStops {
    List<BusRouteStop> baseStops = [];

    if (stops.isNotEmpty) {
      baseStops = stops;
    } else {
      final raw = availableStops;
      baseStops = [
        for (int i = 0; i < raw.length; i++)
          BusRouteStop(
            name: raw[i],
            scheduledTime: _calculateStopTime(departureTime, i * 35),
            subtext: i == 0
                ? 'Departure Bay 1'
                : (i == raw.length - 1 ? 'Destination' : 'Transit Halt'),
          ),
      ];
    }

    if (baseStops.isEmpty) return const [];

    final activeIndex = currentStopIndex.clamp(0, baseStops.length - 1);
    final result = <BusRouteStop>[];

    for (int i = 0; i < baseStops.length; i++) {
      final stop = baseStops[i];
      final isLast = (i == baseStops.length - 1);
      final isDeparted = (i < activeIndex);
      final isNext = (i == activeIndex);

      String? subtext = stop.subtext;
      if (subtext == null || subtext.isEmpty) {
        if (i == 0) {
          subtext = 'Departure Bay 1';
        } else if (isLast) {
          subtext = 'Destination';
        } else if (isNext) {
          subtext = 'Stop duration: 15 mins';
        } else if (isDeparted) {
          subtext = 'Checkpoint Cleared';
        } else {
          subtext = 'Transit Halt';
        }
      }

      String? time = stop.scheduledTime;
      if (time == null || time.isEmpty) {
        time = _calculateStopTime(departureTime, i * 35);
      }

      String? statusText = stop.statusText;
      bool isDelayed = stop.isDelayed;

      if (isDeparted) {
        statusText = 'Departed';
        isDelayed = false;
      } else if (isNext) {
        statusText ??= '+12m Late';
        isDelayed = true;
      } else if (isLast) {
        statusText ??= 'ETA $time';
        isDelayed = true;
      } else {
        statusText ??= 'On Time';
        isDelayed = false;
      }

      result.add(
        stop.copyWith(
          name: stop.name,
          scheduledTime: time,
          subtext: subtext,
          isDeparted: isDeparted,
          isNext: isNext,
          isDestination: isLast,
          statusText: statusText,
          isDelayed: isDelayed,
        ),
      );
    }

    return result;
  }

  static String _calculateStopTime(String baseTime, int offsetMinutes) {
    if (baseTime.isEmpty || baseTime.toLowerCase().contains('every')) {
      final now = DateTime.now().add(Duration(minutes: offsetMinutes));
      final hour =
          now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final min = now.minute.toString().padLeft(2, '0');
      return '$hour:$min $period';
    }

    try {
      final trimmed = baseTime.trim();
      final isPm = trimmed.toUpperCase().contains('PM');
      final isAm = trimmed.toUpperCase().contains('AM');
      final timePart = trimmed.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = timePart.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;

        final totalMins = (hour * 60 + min + offsetMinutes) % (24 * 60);
        final newHour24 = totalMins ~/ 60;
        final newMin = totalMins % 60;
        final displayHour =
            newHour24 > 12 ? newHour24 - 12 : (newHour24 == 0 ? 12 : newHour24);
        final displayPeriod = newHour24 >= 12 ? 'PM' : 'AM';
        return '${displayHour.toString().padLeft(2, '0')}:${newMin.toString().padLeft(2, '0')} $displayPeriod';
      }
    } catch (_) {}

    return baseTime;
  }

  /// Parses minutes from midnight for chronological stop comparison
  static int? parseMinutesFromTimeString(String timeStr) {
    try {
      final trimmed = timeStr.trim().toUpperCase();
      final isPm = trimmed.contains('PM');
      final isAm = trimmed.contains('AM');
      final clean = trimmed.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = clean.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        return hour * 60 + min;
      }
    } catch (_) {}
    return null;
  }

  /// Derives which stop the bus is approaching based on comparing current clock time
  /// with the scheduled stop times from Firebase.
  static int _deriveCurrentStopFromTimes(
    List<BusRouteStop> stopList,
    String? departureTime,
  ) {
    if (stopList.isEmpty) return 0;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < stopList.length; i++) {
      final timeStr =
          stopList[i].scheduledTime ?? (i == 0 ? departureTime : null);
      if (timeStr == null || timeStr.isEmpty) continue;

      final mins = parseMinutesFromTimeString(timeStr);
      if (mins != null && mins > currentMinutes) {
        return i;
      }
    }

    return -1;
  }

  factory Bus.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    final rawStops = (map['scheduledStops'] ?? map['stops']) as List<dynamic>?;
    final List<BusRouteStop> parsedStops = [];

    if (rawStops != null) {
      for (final item in rawStops) {
        final stop = BusRouteStop.fromDynamic(item);
        if (stop.name.isNotEmpty) {
          parsedStops.add(stop);
        }
      }
    }

    int stopIndex = (map['currentStopIndex'] as num?)?.toInt() ?? -1;

    // If stop index was not explicitly set in Firebase, check if currentStop or nextStop name is stored:
    if (stopIndex < 0 && parsedStops.isNotEmpty) {
      final currentStopName =
          (map['currentStop'] ?? map['nextStop'])?.toString().trim();
      if (currentStopName != null && currentStopName.isNotEmpty) {
        stopIndex = parsedStops.indexWhere(
          (s) => s.name.toLowerCase() == currentStopName.toLowerCase(),
        );
      }
    }

    // If still not set, derive from stop times vs current time:
    if (stopIndex < 0 && parsedStops.isNotEmpty) {
      stopIndex = _deriveCurrentStopFromTimes(
        parsedStops,
        map['departureTime']?.toString(),
      );
    }

    // Fallback if before start or not resolvable:
    if (stopIndex < 0) {
      stopIndex = parsedStops.length > 2 ? 2 : (parsedStops.length > 1 ? 1 : 0);
    }

    final isCompletedFlag =
        (map['isCompleted'] as bool?) ?? (map['status'] == 'completed');

    return Bus(
      id: doc.id,
      route: map['route'] as String? ?? 'Campus Route',
      departureTime: map['departureTime'] as String? ?? 'TBD',
      arrivalTime: map['arrivalTime'] as String?,
      availableSeats: (map['availableSeats'] as num?)?.toInt() ?? 0,
      totalSeats: (map['totalSeats'] as num?)?.toInt() ?? 30,
      registrationNumber: map['registrationNumber'] as String? ?? 'PB-12',
      isActive: map['isActive'] as bool? ?? true,
      stops: parsedStops,
      busType: map['busType'] as String?,
      speed: map['speed'] as String? ?? '64 km/h',
      currentLocation: map['currentLocation'] as String?,
      currentStopIndex: stopIndex,
      gpsAccuracy: map['gpsAccuracy'] as String? ?? 'Accurate to 5m',
      lastUpdated: map['lastUpdated'] as String? ?? '10s ago',
      isCompleted: isCompletedFlag,
      scheduleDayId: map['scheduleDayId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'route': route,
    'departureTime': departureTime,
    if (arrivalTime != null) 'arrivalTime': arrivalTime,
    'availableSeats': availableSeats,
    'totalSeats': totalSeats,
    'registrationNumber': registrationNumber,
    'isActive': isActive,
    'stops': stops.isNotEmpty
        ? stops.map((s) => s.toMap()).toList()
        : availableStops,
    'scheduledStops': stops.map((s) => s.toMap()).toList(),
    'busType': busType,
    'speed': speed,
    'currentLocation': currentLocation,
    'currentStopIndex': currentStopIndex,
    'gpsAccuracy': gpsAccuracy,
    'lastUpdated': lastUpdated,
    'isCompleted': isCompleted,
    if (scheduleDayId != null) 'scheduleDayId': scheduleDayId,
  };
}
