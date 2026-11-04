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
  Future<Ticket> bookBus(
    Bus bus, {
    required String pickup,
    required String destination,
  });
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
    return snapshot.docs
        .map((doc) => Bus.fromDoc(doc))
        .where((bus) => bus.isActive)
        .toList();
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
  Future<Ticket> bookBus(
    Bus bus, {
    required String pickup,
    required String destination,
  }) async {
    // 1. Locate the bus document in Firestore
    DocumentReference<Map<String, dynamic>> busDocRef = _busesRef.doc(bus.id);
    DocumentSnapshot<Map<String, dynamic>> busSnapshot = await busDocRef.get();

    if (!busSnapshot.exists) {
      // Try toggling the 'schedule_' prefix
      final altId = bus.id.startsWith('schedule_')
          ? bus.id.replaceFirst('schedule_', '')
          : 'schedule_${bus.id}';
      final altRef = _busesRef.doc(altId);
      final altSnap = await altRef.get();
      if (altSnap.exists) {
        busDocRef = altRef;
        busSnapshot = altSnap;
      }
    }

    if (!busSnapshot.exists && bus.scheduleDayId != null) {
      // Try querying by scheduleDayId and registration or departure
      final query = await _busesRef
          .where('scheduleDayId', isEqualTo: bus.scheduleDayId)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['route'] == bus.route &&
            (data['departureTime'] == bus.departureTime ||
                data['registrationNumber'] == bus.registrationNumber)) {
          busDocRef = doc.reference;
          busSnapshot = doc;
          break;
        }
      }
    }

    if (!busSnapshot.exists) {
      // Fallback: match by route name
      final query = await _busesRef
          .where('route', isEqualTo: bus.route)
          .limit(5)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['departureTime'] == bus.departureTime ||
            data['registrationNumber'] == bus.registrationNumber) {
          busDocRef = doc.reference;
          busSnapshot = doc;
          break;
        }
      }
    }

    // Auto-create document if missing in Firestore so booking succeeds seamlessly
    if (!busSnapshot.exists) {
      await busDocRef.set(bus.toMap());
      busSnapshot = await busDocRef.get();
    }

    final targetRef = busDocRef;
    final now = DateTime.now();
    final ticketId = 'TKT-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final ticketDocRef = _ticketsRef.doc(ticketId);

    return await _firestore.runTransaction<Ticket>((transaction) async {
      final snap = await transaction.get(targetRef);
      if (!snap.exists) {
        throw Exception('Selected bus route does not exist.');
      }

      final available = (snap.data()?['availableSeats'] as num?)?.toInt() ?? 0;
      if (available <= 0) {
        throw Exception('Sorry, no seats remaining on this bus.');
      }

      // Decrement seats
      transaction.update(targetRef, {'availableSeats': available - 1});

      final updatedBus = Bus(
        id: targetRef.id,
        route: bus.route,
        departureTime: bus.departureTime,
        arrivalTime: bus.arrivalTime,
        availableSeats: available - 1,
        totalSeats: bus.totalSeats,
        registrationNumber: bus.registrationNumber,
        stops: bus.stops,
        busType: bus.busType,
        speed: bus.speed,
        currentLocation: bus.currentLocation,
        currentStopIndex: bus.currentStopIndex,
        gpsAccuracy: bus.gpsAccuracy,
        lastUpdated: bus.lastUpdated,
        scheduleDayId: bus.scheduleDayId,
      );

      final ticket = Ticket(
        id: ticketId,
        bus: updatedBus,
        userId: _currentUserId,
        userName: _currentUserName,
        userEmail: _currentUserEmail,
        pickup: pickup,
        destination: destination,
        isUsed: false,
        status: 'Valid',
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

  /// Initial bus routes dataset with structured stop details and timings.
  static final List<Map<String, dynamic>> _defaultBusesWithStops = [
    {
      'route': 'Main Campus → Rupnagar Railway Station',
      'busType': 'Campus Morning Express',
      'departureTime': '05:05 AM',
      'availableSeats': 12,
      'totalSeats': 35,
      'registrationNumber': 'PB-12-Bus-01',
      'speed': '50 km/h',
      'currentStopIndex': 1,
      'isActive': true,
      'stops': [
        {
          'name': 'Main Gate (Main Campus)',
          'time': '05:05 AM',
          'subtext': 'Bay 1 Departure',
          'status': 'Departed',
        },
        {
          'name': 'Bara Pind Junction',
          'time': '05:20 AM',
          'subtext': 'Highway Halt',
          'status': 'Departed',
        },
        {
          'name': 'Old Bus Stand, Rupnagar',
          'time': '05:35 AM',
          'subtext': 'City Stand',
          'status': '+4m Late',
        },
        {
          'name': 'Rupnagar Railway Station',
          'time': '05:50 AM',
          'subtext': 'Station Porch',
          'status': 'ETA 05:50',
        },
      ],
    },
    {
      'route': 'Main Campus → Rupnagar City Centre',
      'busType': 'Campus AC Coach (2+2)',
      'departureTime': '02:30 PM',
      'availableSeats': 14,
      'totalSeats': 32,
      'registrationNumber': 'PB-12-A-4019',
      'speed': '52 km/h',
      'currentStopIndex': 2,
      'isActive': true,
      'stops': [
        {
          'name': 'Main Campus (Main Gate)',
          'time': '02:30 PM',
          'subtext': 'Bay 1 Departure',
          'status': 'Departed',
        },
        {
          'name': 'Satluj Hostel Turn',
          'time': '02:38 PM',
          'subtext': 'Hostel Gate Junction',
          'status': 'Departed',
        },
        {
          'name': 'Bara Pind Junction',
          'time': '02:50 PM',
          'subtext': 'Highway Exit · Stop: 5 mins',
          'status': '+5m Late',
        },
        {
          'name': 'Rupnagar Old Bus Stand',
          'time': '03:05 PM',
          'subtext': 'City Counter',
          'status': 'On Time',
        },
        {
          'name': 'Rupnagar City Centre',
          'time': '03:20 PM',
          'subtext': 'Final Destination',
          'status': 'ETA 03:20',
        },
      ],
    },
    {
      'route': 'Main Campus → Morinda Railway Station',
      'busType': 'Campus AC Coach (2+2)',
      'departureTime': '04:15 PM',
      'availableSeats': 6,
      'totalSeats': 32,
      'registrationNumber': 'PB-12-B-8821',
      'speed': '56 km/h',
      'currentStopIndex': 2,
      'isActive': true,
      'stops': [
        {
          'name': 'Main Campus (Main Gate)',
          'time': '04:15 PM',
          'subtext': 'Bay 2 Departure',
          'status': 'Departed',
        },
        {
          'name': 'Utility Block Exit',
          'time': '04:22 PM',
          'subtext': 'Campus Exit Gate',
          'status': 'Departed',
        },
        {
          'name': 'Ropar Bypass Flyover',
          'time': '04:35 PM',
          'subtext': 'Service Lane Halt',
          'status': 'On Time',
        },
        {
          'name': 'Chamkaur Sahib',
          'time': '04:55 PM',
          'subtext': 'Bus Shelter',
          'status': 'On Time',
        },
        {
          'name': 'Morinda Railway Station',
          'time': '05:15 PM',
          'subtext': 'Station Platform 1',
          'status': 'ETA 05:15',
        },
      ],
    },
    {
      'route': 'Main Campus → Chandigarh ISBT (Sector 43)',
      'busType': 'Intercity AC Express (2+2)',
      'departureTime': '06:00 PM',
      'availableSeats': 8,
      'totalSeats': 45,
      'registrationNumber': 'PB-12-C-1092',
      'speed': '62 km/h',
      'currentStopIndex': 2,
      'isActive': true,
      'stops': [
        {
          'name': 'Main Campus (Main Gate)',
          'time': '06:00 PM',
          'subtext': 'Main Gate Departure',
          'status': 'Departed',
        },
        {
          'name': 'Kurali Bus Stop',
          'time': '06:25 PM',
          'subtext': 'Main Highway Stop',
          'status': 'Departed',
        },
        {
          'name': 'Kharar Junction',
          'time': '06:45 PM',
          'subtext': 'Flyover Entry',
          'status': '+8m Late',
        },
        {
          'name': 'Mohali Phase 7',
          'time': '07:10 PM',
          'subtext': 'Traffic Junction',
          'status': 'On Time',
        },
        {
          'name': 'Chandigarh ISBT (Sector 43)',
          'time': '07:35 PM',
          'subtext': 'Counter Bay 12',
          'status': 'ETA 07:35',
        },
      ],
    },
    {
      'route': 'Hostel Sector → Academic Block Shuttle',
      'busType': 'Campus Electric Shuttle (2+2)',
      'departureTime': 'Every 15 mins',
      'availableSeats': 18,
      'totalSeats': 20,
      'registrationNumber': 'PB-12-EV-01',
      'speed': '25 km/h',
      'currentStopIndex': 3,
      'isActive': true,
      'stops': [
        {
          'name': 'Satluj Hostel',
          'time': '10:00 AM',
          'subtext': 'Hostel Circle',
          'status': 'Departed',
        },
        {
          'name': 'Beas Hostel',
          'time': '10:03 AM',
          'subtext': 'North Wing Entry',
          'status': 'Departed',
        },
        {
          'name': 'Chenab Hostel',
          'time': '10:06 AM',
          'subtext': 'Mess Complex',
          'status': 'Departed',
        },
        {
          'name': 'Brahmaputra Boys Hostel',
          'time': '10:09 AM',
          'subtext': 'Main Drop Point',
          'status': 'On Time',
        },
        {
          'name': 'Nalanda Library',
          'time': '10:13 AM',
          'subtext': 'Central Lawn Exit',
          'status': 'On Time',
        },
        {
          'name': 'J.C. Bose Block',
          'time': '10:17 AM',
          'subtext': 'Academic Concourse',
          'status': 'On Time',
        },
        {
          'name': 'Super Academic Building',
          'time': '10:20 AM',
          'subtext': 'Auditorium Gate',
          'status': 'ETA 10:20',
        },
      ],
    },
  ];

  /// Auto-populates or updates Firestore with default routes & structured stops.
  @override
  Future<void> seedInitialDataIfEmpty() async {
    try {
      final busesSnap = await _busesRef.get();
      if (busesSnap.docs.isEmpty) {
        for (final busData in _defaultBusesWithStops) {
          await _busesRef.add(busData);
        }
      } else {
        // Ensure all existing documents in Firestore have rich stops and metadata populated
        for (final doc in busesSnap.docs) {
          final data = doc.data();

          // Sanitize any deprecated GreenLine names from older test sessions
          final rawBusType = (data['busType'] ?? '').toString().toLowerCase();
          final rawRoute = (data['route'] ?? '').toString().toLowerCase();
          if (rawBusType.contains('greenline') || rawRoute.contains('madiwala')) {
            await doc.reference.update({
              'route': 'Main Campus → Rupnagar Railway Station',
              'busType': 'Campus Morning Express',
            });
          }

          final rawStops = data['stops'] as List<dynamic>?;
          final bool needsStopsUpdate = rawStops == null ||
              rawStops.isEmpty ||
              rawStops.first is String;

          if (needsStopsUpdate) {
            final routeName = (data['route'] as String? ?? '').toLowerCase();
            final matchingDefault = _defaultBusesWithStops.firstWhere(
              (b) => (b['route'] as String).toLowerCase() == routeName,
              orElse: () => <String, dynamic>{},
            );

            if (matchingDefault.isNotEmpty && matchingDefault['stops'] != null) {
              await doc.reference.update({
                'stops': matchingDefault['stops'],
                'currentStopIndex': matchingDefault['currentStopIndex'] ?? 2,
                'speed': data['speed'] ?? matchingDefault['speed'] ?? '58 km/h',
                if (matchingDefault['busType'] != null && data['busType'] == null)
                  'busType': matchingDefault['busType'],
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('seedInitialData error: $e');
    }
  }
}
