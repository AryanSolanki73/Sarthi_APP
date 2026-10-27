import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/cart_location.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/models/ticket.dart';
import 'package:sarthi_app/services/transit_service.dart';

/// Controller for student transit actions: EV Cart hailing, live map tracking,
/// and City Bus ticket booking powered by Firebase.
class TransitController extends ChangeNotifier {
  TransitController(this._service);

  final TransitService _service;

  bool isBusTab = false;
  bool isLoading = true;
  String pickup = 'Satluj Hostel';
  String drop = 'J.C. Bose Block';

  List<Bus> buses = [];
  List<CartLocation> cartLocations = [];
  List<RideRequest> rides = [];
  List<Ticket> tickets = [];

  StreamSubscription<List<Bus>>? _busesSub;
  StreamSubscription<List<CartLocation>>? _locationsSub;
  StreamSubscription<List<RideRequest>>? _ridesSub;
  StreamSubscription<List<Ticket>>? _ticketsSub;

  /// Returns the current active ride if the student has requested one.
  RideRequest? get activeRide {
    for (final ride in rides) {
      if (ride.isActive) return ride;
    }
    return null;
  }

  /// Initializes real-time Firebase listeners for routes, rides, and locations.
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      await _service.seedInitialDataIfEmpty();
    } catch (_) {}

    _subscribeToFirebaseStreams();

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
  Future<Ticket> bookBus(Bus bus) async {
    final ticket = await _service.bookBus(bus);
    notifyListeners();
    return ticket;
  }

  @override
  void dispose() {
    _busesSub?.cancel();
    _locationsSub?.cancel();
    _ridesSub?.cancel();
    _ticketsSub?.cancel();
    super.dispose();
  }
}
