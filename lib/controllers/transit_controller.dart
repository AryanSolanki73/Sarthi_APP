import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sarthi_app/admin/models/bus_schedule_model.dart';
import 'package:sarthi_app/admin/services/bus_schedule_service.dart';
import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/cart_location.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/models/ticket.dart';
import 'package:sarthi_app/services/transit_service.dart';

/// Controller for student transit actions: EV Cart hailing, live map tracking,
/// and City Bus ticket booking powered by Firebase.
class TransitController extends ChangeNotifier {
  TransitController(this._service, {BusScheduleService? scheduleService})
      : _busScheduleService = scheduleService ?? BusScheduleService();

  final TransitService _service;
  final BusScheduleService _busScheduleService;

  bool isBusTab = false;
  bool isLoading = true;
  String pickup = 'Satluj Hostel';
  String drop = 'J.C. Bose Block';

  List<Bus> buses = [];
  List<CartLocation> cartLocations = [];
  List<RideRequest> rides = [];
  List<Ticket> tickets = [];

  // Day Schedule selection
  String selectedScheduleDayKey = 'today'; // 'today', 'tomorrow', 'monday', etc.
  DateTime selectedScheduleDate = DateTime.now();
  DayBusSchedule? currentDaySchedule;
  List<Bus> dayScheduleBuses = [];
  bool isLoadingSchedule = false;

  StreamSubscription<List<Bus>>? _busesSub;
  StreamSubscription<List<CartLocation>>? _locationsSub;
  StreamSubscription<List<RideRequest>>? _ridesSub;
  StreamSubscription<List<Ticket>>? _ticketsSub;
  Timer? _staleCartTimer;

  /// Returns the current active ride if the student has requested one.
  RideRequest? get activeRide {
    for (final ride in rides) {
      if (ride.isActive) return ride;
    }
    return null;
  }

  /// Maps any calendar date to the corresponding IIT Ropar timetable day ID.
  static String dayIdForDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
        return 'tuesday_thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday_holidays';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'tuesday_thursday';
    }
  }

  /// Formatted date string (e.g., "Wed, Nov 4").
  String formatShortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  /// User-friendly label for the selected day filter.
  String get selectedScheduleDayLabel {
    if (selectedScheduleDayKey == 'today') {
      return 'Today · ${formatShortDate(DateTime.now())}';
    } else if (selectedScheduleDayKey == 'tomorrow') {
      return 'Tomorrow · ${formatShortDate(DateTime.now().add(const Duration(days: 1)))}';
    } else if (selectedScheduleDayKey == 'custom') {
      return formatShortDate(selectedScheduleDate);
    }
    return currentDaySchedule?.dayTitle ?? 'Selected Day';
  }

  /// Checks whether a trip is completed. Completed trips are filtered out from the list.
  bool isTripCompleted(Bus bus, {DateTime? targetDate}) {
    if (bus.isCompleted) return true;

    final date = targetDate ?? selectedScheduleDate;
    final now = DateTime.now();

    // Check if the selected date is in the past:
    final isPastDay = date.year < now.year ||
        (date.year == now.year && date.month < now.month) ||
        (date.year == now.year &&
            date.month == now.month &&
            date.day < now.day);
    if (isPastDay) return true;

    // Check if the selected date is in the future:
    final isFutureDay = date.year > now.year ||
        (date.year == now.year && date.month > now.month) ||
        (date.year == now.year &&
            date.month == now.month &&
            date.day > now.day);
    if (isFutureDay) return false;

    // For TODAY:
    // 1. If all stops are marked departed:
    if (bus.stops.isNotEmpty &&
        bus.currentStopIndex >= bus.stops.length - 1 &&
        bus.stops.last.isDeparted) {
      return true;
    }

    // 2. Check if the trip's arrival / end time has passed:
    final timeStr = bus.arrivalTime ??
        (bus.stops.isNotEmpty && bus.stops.last.scheduledTime != null
            ? bus.stops.last.scheduledTime!
            : bus.departureTime);

    final currentMins = now.hour * 60 + now.minute;
    final tripEndMins = Bus.parseMinutesFromTimeString(timeStr);

    if (tripEndMins != null) {
      if (currentMins > tripEndMins + 10) {
        return true;
      }
    }

    return false;
  }

  /// Checks whether a trip has started on the selected day.
  bool isTripStarted(Bus bus, {DateTime? targetDate}) {
    if (isTripCompleted(bus, targetDate: targetDate)) return false;
    return bus.isTripStarted(targetDate: targetDate ?? selectedScheduleDate);
  }

  /// Returns the active buses to display for the currently chosen day filter,
  /// with completed trips automatically removed.
  List<Bus> get activeDisplayedBuses {
    final dayId = (selectedScheduleDayKey == 'today' ||
            selectedScheduleDayKey == 'tomorrow' ||
            selectedScheduleDayKey == 'custom')
        ? dayIdForDate(selectedScheduleDate)
        : selectedScheduleDayKey;

    // Filter live buses from Firestore for this specific schedule day:
    final liveBusesForDay = buses.where((b) {
      if (b.scheduleDayId != null && b.scheduleDayId!.isNotEmpty) {
        return b.scheduleDayId == dayId;
      }
      return selectedScheduleDayKey == 'today';
    }).toList();

    // Prefer live Firestore buses if available; otherwise use scheduled timetable buses:
    final List<Bus> sourceList =
        liveBusesForDay.isNotEmpty ? liveBusesForDay : dayScheduleBuses;

    return sourceList
        .where((b) => !isTripCompleted(b, targetDate: selectedScheduleDate))
        .toList();
  }

  /// Loads trips for a specific day key ('today', 'tomorrow', 'monday', etc.) or custom date from Firebase.
  Future<void> selectScheduleDay(String key, {DateTime? date}) async {
    selectedScheduleDayKey = key;
    if (date != null) {
      selectedScheduleDate = date;
    } else if (key == 'today') {
      selectedScheduleDate = DateTime.now();
    } else if (key == 'tomorrow') {
      selectedScheduleDate = DateTime.now().add(const Duration(days: 1));
    }

    final dayId = (key == 'today' || key == 'tomorrow' || key == 'custom')
        ? dayIdForDate(selectedScheduleDate)
        : key;

    isLoadingSchedule = true;
    notifyListeners();

    try {
      currentDaySchedule = await _busScheduleService.getScheduleForDay(dayId);
      final trips = currentDaySchedule?.trips ?? [];
      dayScheduleBuses = trips
          .where((t) => t.isActive)
          .map((t) => Bus.fromScheduledTrip(t, dayId: dayId))
          .toList();
    } catch (e) {
      debugPrint('Error fetching trips for day $dayId: $e');
    } finally {
      isLoadingSchedule = false;
      notifyListeners();
    }
  }

  /// Initializes real-time Firebase listeners for routes, rides, and locations.
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      await _service.seedInitialDataIfEmpty();
    } catch (_) {}

    _subscribeToFirebaseStreams();

    try {
      await selectScheduleDay('today');
    } catch (_) {}

    // Check periodically for stale carts whose pilot app closed or stopped updating
    _staleCartTimer?.cancel();
    _staleCartTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (cartLocations.isNotEmpty) {
        final activeList = cartLocations.where((c) => c.isOnline).toList();
        if (activeList.length != cartLocations.length) {
          cartLocations = activeList;
          notifyListeners();
        }
      }
    });

    isLoading = false;
    notifyListeners();
  }

  void _subscribeToFirebaseStreams() {
    _busesSub = _service.streamBuses().listen(
      (data) {
        buses = data;
        notifyListeners();
      },
      onError: (err) => debugPrint('Buses stream error: $err'),
    );

    _locationsSub = _service.streamCartLocations().listen(
      (data) {
        cartLocations = data;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('Cart locations stream error: $err');
        cartLocations = [];
        notifyListeners();
      },
    );

    _ridesSub = _service.streamUserRides().listen(
      (data) {
        rides = data;
        notifyListeners();
      },
      onError: (err) => debugPrint('User rides stream error: $err'),
    );

    _ticketsSub = _service.streamUserTickets().listen(
      (data) {
        tickets = data;
        notifyListeners();
      },
      onError: (err) => debugPrint('User tickets stream error: $err'),
    );
  }

  void setPassengerTab(bool showBuses) {
    isBusTab = showBuses;
    notifyListeners();
  }

  void setPickup(String value) {
    pickup = value;
    notifyListeners();
  }

  void setDrop(String value) {
    drop = value;
    notifyListeners();
  }

  /// Submits an EV Cart hailing request to Firebase.
  Future<RideRequest> requestCart() async {
    final request = await _service.createRideRequest(
      pickup: pickup,
      drop: drop,
    );
    if (!rides.any((r) => r.id == request.id)) {
      rides = [request, ...rides];
    }
    notifyListeners();
    return request;
  }

  /// Cancels an in-progress or pending ride request in Firebase.
  Future<void> cancelActiveRide(String rideId) async {
    await _service.cancelRideRequest(rideId);
    final idx = rides.indexWhere((r) => r.id == rideId);
    if (idx != -1) {
      rides[idx] = RideRequest(
        id: rides[idx].id,
        pickup: rides[idx].pickup,
        drop: rides[idx].drop,
        userId: rides[idx].userId,
        userName: rides[idx].userName,
        userEmail: rides[idx].userEmail,
        status: 'cancelled',
        assignedCartId: rides[idx].assignedCartId,
        assignedCartName: rides[idx].assignedCartName,
        createdAt: rides[idx].createdAt,
      );
    }
    notifyListeners();
  }

  /// Reserves a bus seat and creates a verified ticket in Firebase.
  Future<Ticket> bookBus(
    Bus bus, {
    required String pickup,
    required String destination,
  }) async {
    final ticket = await _service.bookBus(
      bus,
      pickup: pickup,
      destination: destination,
    );
    if (!tickets.any((t) => t.id == ticket.id)) {
      tickets = [ticket, ...tickets];
    }
    notifyListeners();
    return ticket;
  }

  @override
  void dispose() {
    _busesSub?.cancel();
    _locationsSub?.cancel();
    _ridesSub?.cancel();
    _ticketsSub?.cancel();
    _staleCartTimer?.cancel();
    super.dispose();
  }
}
