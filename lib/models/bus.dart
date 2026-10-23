import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String id;
  final String route;
  final String departureTime;
  final String registrationNumber;
  final int totalSeats;
  int availableSeats;
  final bool isActive;

  bool get isFull => availableSeats <= 0;

  factory Bus.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Bus(
      id: doc.id,
      route: map['route'] as String? ?? 'Campus Route',
      departureTime: map['departureTime'] as String? ?? 'TBD',
      availableSeats: (map['availableSeats'] as num?)?.toInt() ?? 0,
      totalSeats: (map['totalSeats'] as num?)?.toInt() ?? 30,
      registrationNumber: map['registrationNumber'] as String? ?? 'PB-12',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'route': route,
    'departureTime': departureTime,
    'availableSeats': availableSeats,
    'totalSeats': totalSeats,
    'registrationNumber': registrationNumber,
    'isActive': isActive,
  };
}
