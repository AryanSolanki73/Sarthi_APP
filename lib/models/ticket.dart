import 'package:cloud_firestore/cloud_firestore.dart';
import 'bus.dart';

/// A ticket created after a passenger books a bus seat in Firebase.
class Ticket {
  Ticket({
    required this.id,
    required this.bus,
    required this.userId,
    this.userName = 'Student',
    this.isUsed = false,
    DateTime? bookedAt,
  }) : bookedAt = bookedAt ?? DateTime.now();

  final String id;
  final Bus bus;
  final String userId;
  final String userName;
  bool isUsed;
  final DateTime bookedAt;

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

    final busData = map['bus'] as Map<String, dynamic>? ?? {};
    final bus = Bus(
      id: busData['id'] as String? ?? '',
      route: busData['route'] as String? ?? 'Campus Bus',
      departureTime: busData['departureTime'] as String? ?? '',
      availableSeats: (busData['availableSeats'] as num?)?.toInt() ?? 0,
      totalSeats: (busData['totalSeats'] as num?)?.toInt() ?? 30,
      registrationNumber: busData['registrationNumber'] as String? ?? '',
    );

    return Ticket(
      id: doc.id,
      bus: bus,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Student',
      isUsed: map['isUsed'] as bool? ?? false,
      bookedAt: booked,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'isUsed': isUsed,
    'bookedAt': Timestamp.fromDate(bookedAt),
    'bus': bus.toMap()..['id'] = bus.id,
  };
}
