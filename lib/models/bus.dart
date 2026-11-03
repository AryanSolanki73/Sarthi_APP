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
    this.stops = const [],
  });

  final String id;
  final String route;
  final String departureTime;
  final String registrationNumber;
  final int totalSeats;
  int availableSeats;
  final bool isActive;
  final List<String> stops;

  bool get isFull => availableSeats <= 0;

  /// Returns stops for the route, constructing sensible stops if not stored explicitly.
  List<String> get availableStops {
    if (stops.isNotEmpty) return stops;

    // Auto-generate stops from route format "Start → End"
    if (route.contains('→')) {
      final parts = route.split('→').map((s) => s.trim()).toList();
      final start = parts[0];
      final end = parts[1];

      if (route.contains('Rupnagar')) {
        return [
          start,
          'Main Gate Turn',
          'Bara Pind Junction',
          'Rupnagar Old Bus Stand',
          end,
        ];
      } else if (route.contains('Morinda')) {
        return [
          start,
          'Utility Block Exit',
          'Ropar Bypass',
          'Chamkaur Sahib',
          end,
        ];
      } else if (route.contains('Chandigarh')) {
        return [
          start,
          'Kurali Bus Stop',
          'Kharar Junction',
          'Mohali Phase 7',
          end,
        ];
      } else if (route.contains('Shuttle') || route.contains('Hostel')) {
        return [
          'Satluj Hostel',
          'Beas Hostel',
          'Chenab Hostel',
          'Brahmaputra Boys Hostel',
          'Nalanda Library',
          'J.C. Bose Block',
          'Super Academic Building',
        ];
      }
      return [start, 'Mid-Route Stop', end];
    }
    return [
      'Main Campus Gate',
      'Satluj Hostel',
      'Nalanda Library',
      'Academic Block',
      'City Center',
    ];
  }

  factory Bus.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    final rawStops = map['stops'] as List<dynamic>?;
    final stopsList = rawStops != null
        ? rawStops.map((e) => e.toString()).toList()
        : <String>[];

    return Bus(
      id: doc.id,
      route: map['route'] as String? ?? 'Campus Route',
      departureTime: map['departureTime'] as String? ?? 'TBD',
      availableSeats: (map['availableSeats'] as num?)?.toInt() ?? 0,
      totalSeats: (map['totalSeats'] as num?)?.toInt() ?? 30,
      registrationNumber: map['registrationNumber'] as String? ?? 'PB-12',
      isActive: map['isActive'] as bool? ?? true,
      stops: stopsList,
    );
  }

  Map<String, dynamic> toMap() => {
    'route': route,
    'departureTime': departureTime,
    'availableSeats': availableSeats,
    'totalSeats': totalSeats,
    'registrationNumber': registrationNumber,
    'isActive': isActive,
    'stops': stops.isNotEmpty ? stops : availableStops,
  };
}
