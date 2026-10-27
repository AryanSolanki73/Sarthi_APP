import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/cart_location.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/models/ticket.dart';

/// Contract for passenger transit services powered by Firebase.
abstract class TransitService {
  Stream<List<Bus>> streamBuses();
  Future<List<Bus>> fetchBuses();
  Stream<List<CartLocation>> streamCartLocations();
  Stream<List<RideRequest>> streamUserRides();
  Future<RideRequest> createRideRequest({
    required String pickup,
    required String drop,
  });
  Future<void> cancelRideRequest(String requestId);
  Future<Ticket> bookBus(Bus bus);
  Stream<List<Ticket>> streamUserTickets();
  Future<void> seedInitialDataIfEmpty();
}

/// Firebase Firestore implementation of [TransitService].
/// Manages real-time collections for:
/// - `buses` (scheduled bus routes & seat counts)
/// - `rides` (student EV cart requests & live status)
/// - `locations` (live EV cart coordinates & battery status)
/// - `tickets` (student booked bus tickets)
class FirebaseTransitService implements TransitService {
  FirebaseTransitService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _busesRef =>
      _firestore.collection('buses');
  CollectionReference<Map<String, dynamic>> get _ridesRef =>
      _firestore.collection('rides');
  CollectionReference<Map<String, dynamic>> get _locationsRef =>
      _firestore.collection('locations');
  CollectionReference<Map<String, dynamic>> get _ticketsRef =>
      _firestore.collection('tickets');

  String get _currentUserId => _auth.currentUser?.uid ?? 'guest';
  String get _currentUserName =>
      _auth.currentUser?.displayName ?? 'Student';
  String get _currentUserEmail => _auth.currentUser?.email ?? '';

  /// Real-time stream of available scheduled buses from Firestore.
  @override
  Stream<List<Bus>> streamBuses() {
    return _busesRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Bus.fromDoc(doc))
          .where((bus) => bus.isActive)
          .toList();
    });
  }

  /// One-time fetch of scheduled buses.
  @override
  Future<List<Bus>> fetchBuses() async {
    final snapshot = await _busesRef.get();
    if (snapshot.docs.isEmpty) {
      await seedInitialDataIfEmpty();
      final fresh = await _busesRef.get();
      return fresh.docs.map((doc) => Bus.fromDoc(doc)).toList();
    }
    return snapshot.docs.map((doc) => Bus.fromDoc(doc)).toList();
  }

  /// Real-time stream of live EV cart GPS locations on campus from "locations".
  /// Strictly filters for active vehicles broadcasted by online drivers.
  /// If cannot connect to the collection or an error occurs, yields an empty list (no carts visible).
  @override
  Stream<List<CartLocation>> streamCartLocations() {
    return _locationsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CartLocation.fromDoc(doc))
          .where((cart) => cart.isOnline)
          .toList();
    }).handleError((error) {
      debugPrint('Firestore streamCartLocations connection error: $error');
      return <CartLocation>[];
    });
  }

  /// Real-time stream of ride requests made by the signed-in student.
  @override
  Stream<List<RideRequest>> streamUserRides() {
    final uid = _currentUserId;
    return _ridesRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => RideRequest.fromDoc(doc)).toList();
      // Sort in-memory to avoid needing a composite index
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Creates a new EV cart ride request in Firestore for the current student.
  @override
  Future<RideRequest> createRideRequest({
    required String pickup,
    required String drop,
  }) async {
    final now = DateTime.now();
    final docRef = _ridesRef.doc();
    final ride = RideRequest(
      id: docRef.id,
      pickup: pickup,
      drop: drop,
      userId: _currentUserId,
      userName: _currentUserName,
      userEmail: _currentUserEmail,
      status: 'pending',
      createdAt: now,
    );

    await docRef.set(ride.toMap());
    return ride;
  }

  /// Cancels an active ride request in Firestore.
  @override
  Future<void> cancelRideRequest(String requestId) async {
    await _ridesRef.doc(requestId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Books a seat on a city bus, decrementing available seats in Firestore atomically.
  @override
  Future<Ticket> bookBus(Bus bus) async {
    final busDocRef = _busesRef.doc(bus.id);
    final now = DateTime.now();
    final ticketId = 'TKT-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final ticketDocRef = _ticketsRef.doc(ticketId);

    return await _firestore.runTransaction<Ticket>((transaction) async {
      final busSnapshot = await transaction.get(busDocRef);
      if (!busSnapshot.exists) {
        throw Exception('Selected bus route does not exist.');
      }

      final available = (busSnapshot.data()?['availableSeats'] as num?)?.toInt() ?? 0;
      if (available <= 0) {
        throw Exception('Sorry, no seats remaining on this bus.');
      }

      // Decrement seats
      transaction.update(busDocRef, {'availableSeats': available - 1});

      final updatedBus = Bus(
        id: bus.id,
        route: bus.route,
        departureTime: bus.departureTime,
        availableSeats: available - 1,
        totalSeats: bus.totalSeats,
        registrationNumber: bus.registrationNumber,
      );

      final ticket = Ticket(
        id: ticketId,
        bus: updatedBus,
        userId: _currentUserId,
        userName: _currentUserName,
        isUsed: false,
        bookedAt: now,
      );

      transaction.set(ticketDocRef, ticket.toMap());
      return ticket;
    });
  }

  /// Real-time stream of booked tickets for the signed-in student.
  @override
  Stream<List<Ticket>> streamUserTickets() {
    final uid = _currentUserId;
    return _ticketsRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Ticket.fromDoc(doc)).toList();
      list.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
      return list;
    });
  }

  /// Auto-populates Firestore with default routes & cart locations if empty.
  @override
  Future<void> seedInitialDataIfEmpty() async {
    try {
      // 1. Seed scheduled buses / routes
      final busesSnap = await _busesRef.limit(1).get();
      if (busesSnap.docs.isEmpty) {
        final initialBuses = [
          {
            'route': 'Main Campus → Rupnagar City Centre',
            'departureTime': '02:30 PM',
            'availableSeats': 14,
            'totalSeats': 32,
            'registrationNumber': 'PB-12-A-4019',
            'isActive': true,
          },
          {
            'route': 'Main Campus → Morinda Railway Station',
            'departureTime': '04:15 PM',
            'availableSeats': 6,
            'totalSeats': 32,
            'registrationNumber': 'PB-12-B-8821',
            'isActive': true,
          },
          {
            'route': 'Main Campus → Chandigarh ISBT (Sector 43)',
            'departureTime': '06:00 PM',
            'availableSeats': 8,
            'totalSeats': 45,
            'registrationNumber': 'PB-12-C-1092',
            'isActive': true,
          },
          {
            'route': 'Hostel Sector → Academic Block Shuttle',
            'departureTime': 'Every 15 mins',
            'availableSeats': 18,
            'totalSeats': 20,
            'registrationNumber': 'PB-12-EV-01',
            'isActive': true,
          },
        ];

        for (final busData in initialBuses) {
          await _busesRef.add(busData);
        }
      }
    } catch (e) {
      // Non-blocking in case of offline launch
    }
  }
}
