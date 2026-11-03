import 'package:cloud_firestore/cloud_firestore.dart';
import 'bus.dart';

/// A ticket created after a passenger books a bus seat in Firebase.
class Ticket {
  Ticket({
    required this.id,
    required this.bus,
    required this.userId,
    this.userName = 'Student',
    this.userEmail = '',
    this.pickup = 'Main Campus',
    this.destination = 'Destination',
    this.isUsed = false,
    this.status = 'Valid',
    this.confirmedByDriverName,
    this.confirmedAt,
    DateTime? bookedAt,
  }) : bookedAt = bookedAt ?? DateTime.now();

  final String id;
  final Bus bus;
  final String userId;
  final String userName;
  final String userEmail;
  final String pickup;
  final String destination;
  bool isUsed;
  String status;
  final String? confirmedByDriverName;
  final DateTime? confirmedAt;
  final DateTime bookedAt;

  bool get isConfirmed => isUsed || status == 'Used';

  factory Ticket.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    DateTime booked;
    if (map['bookedAt'] is Timestamp) {
      booked = (map['bookedAt'] as Timestamp).toDate();
    } else if (map['bookedAt'] is String) {
      booked = DateTime.tryParse(map['bookedAt']) ?? DateTime.now();
    } else {
      booked = DateTime.now();
    }

    DateTime? confirmed;
    if (map['confirmedAt'] is Timestamp) {
      confirmed = (map['confirmedAt'] as Timestamp).toDate();
    } else if (map['confirmedAt'] is String) {
      confirmed = DateTime.tryParse(map['confirmedAt']);
    }

    final busData = map['bus'] as Map<String, dynamic>? ?? {};
    final routeStr = map['busRoute'] as String? ??
        busData['route'] as String? ??
        'Campus Bus';
    final regNo = map['busRegistration'] as String? ??
        busData['registrationNumber'] as String? ??
        'PB-12';
    final depTime = map['departureTime'] as String? ??
        busData['departureTime'] as String? ??
        '';

    final bus = Bus(
      id: map['busId'] as String? ?? busData['id'] as String? ?? '',
      route: routeStr,
      departureTime: depTime,
      availableSeats: (busData['availableSeats'] as num?)?.toInt() ?? 0,
      totalSeats: (busData['totalSeats'] as num?)?.toInt() ?? 30,
      registrationNumber: regNo,
    );

    final isUsedFlag = map['isUsed'] as bool? ?? (map['status'] == 'Used');
    final statusStr = map['status'] as String? ?? (isUsedFlag ? 'Used' : 'Valid');

    String defaultPickup = 'Main Campus';
    String defaultDrop = 'Destination';
    if (routeStr.contains('→')) {
      final parts = routeStr.split('→').map((s) => s.trim()).toList();
      defaultPickup = parts[0];
      defaultDrop = parts.length > 1 ? parts[1] : 'Destination';
    }

    return Ticket(
      id: (map['id'] as String?)?.isNotEmpty == true
          ? map['id'] as String
          : doc.id,
      bus: bus,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Student',
      userEmail: map['userEmail'] as String? ?? '',
      pickup: map['pickup'] as String? ?? defaultPickup,
      destination: map['destination'] as String? ?? map['drop'] as String? ?? defaultDrop,
      isUsed: isUsedFlag,
      status: statusStr,
      confirmedByDriverName: map['confirmedByDriverName'] as String?,
      confirmedAt: confirmed,
      bookedAt: booked,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'busId': bus.id,
    'busRoute': bus.route,
    'busRegistration': bus.registrationNumber,
    'departureTime': bus.departureTime,
    'pickup': pickup,
    'destination': destination,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'isUsed': isUsed,
    'status': status,
    'bookedAt': Timestamp.fromDate(bookedAt),
    'bus': bus.toMap()..['id'] = bus.id,
    if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
    if (confirmedByDriverName != null)
      'confirmedByDriverName': confirmedByDriverName,
  };
}
