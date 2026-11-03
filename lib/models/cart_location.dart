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

  /// Returns true only if the vehicle is actively marked online by the driver
  /// AND has sent a recent heartbeat (within 45 seconds).
  /// If the pilot app was closed for some time, this returns false so the cart disappears.
  bool get isOnline {
    final s = status.trim().toLowerCase();
    if (s == 'offline' || !driverOnline) return false;
    if (s != 'active' && s != 'online' && !driverOnline) return false;

    // Heartbeat freshness check: If the driver closed the app or stopped updating,
    // the cart is considered offline and disappears from the passenger map.
    if (updatedAt != null) {
      final elapsed = DateTime.now().difference(updatedAt!);
      if (elapsed.inSeconds > 45) {
        return false;
      }
    }
    return true;
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
