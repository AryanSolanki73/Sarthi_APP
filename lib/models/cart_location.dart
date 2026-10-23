import 'package:cloud_firestore/cloud_firestore.dart';

/// Real-time location and status of an EV Cart on campus.
class CartLocation {
  CartLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.status = 'active', // 'active', 'idle', 'charging'
    this.batteryLevel = 100,
    this.updatedAt,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double heading;
  final String status;
  final int batteryLevel;
  final DateTime? updatedAt;

  factory CartLocation.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? updated;
    if (map['updatedAt'] is Timestamp) {
      updated = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updated = DateTime.tryParse(map['updatedAt']);
    }

    return CartLocation(
      id: doc.id,
      name: map['name'] as String? ?? 'EV Cart',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 30.9715,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 76.4732,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'active',
      batteryLevel: (map['batteryLevel'] as num?)?.toInt() ?? 100,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'heading': heading,
    'status': status,
    'batteryLevel': batteryLevel,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
  };
}
