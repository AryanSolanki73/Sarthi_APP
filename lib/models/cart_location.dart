import 'package:cloud_firestore/cloud_firestore.dart';

/// Real-time location and status of an EV Cart on campus.
class CartLocation {
  CartLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.status = 'active',
    this.driverOnline = true,
    this.batteryLevel = 100,
    this.updatedAt,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double heading;
  final String status;
  final bool driverOnline;
  final int batteryLevel;
  final DateTime? updatedAt;

  /// Returns true only if the vehicle is actively marked online by the driver.
  bool get isOnline {
    final s = status.trim().toLowerCase();
    if (s == 'offline' || !driverOnline) return false;
    return s == 'active' || s == 'online' || driverOnline;
  }

  factory CartLocation.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? updated;
    if (map['updatedAt'] is Timestamp) {
      updated = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updated = DateTime.tryParse(map['updatedAt']);
    }

    final statusStr = (map['status'] as String?)?.trim().toLowerCase() ?? 'offline';
    final isOnlineFlag =
        map['driverOnline'] as bool? ?? (statusStr == 'active' || statusStr == 'online');

    return CartLocation(
      id: doc.id,
      name: map['name'] as String? ?? 'EV Cart',
      latitude: double.parse(
          ((map['latitude'] as num?)?.toDouble() ?? 30.969205)
              .toStringAsFixed(6)),
      longitude: double.parse(
          ((map['longitude'] as num?)?.toDouble() ?? 76.468457)
              .toStringAsFixed(6)),
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      status: statusStr,
      driverOnline: isOnlineFlag,
      batteryLevel: (map['batteryLevel'] as num?)?.toInt() ?? 100,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'latitude': double.parse(latitude.toStringAsFixed(6)),
    'longitude': double.parse(longitude.toStringAsFixed(6)),
    'heading': heading,
    'status': status,
    'driverOnline': driverOnline,
    'batteryLevel': batteryLevel,
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };
}
