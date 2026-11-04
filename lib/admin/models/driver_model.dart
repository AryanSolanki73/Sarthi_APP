import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a campus transit driver stored in Firestore.
class DriverModel {
  const DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    this.vehicleType = 'EV Cart',
    this.vehicleNumber = '',
    this.status = 'active',
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String licenseNumber;
  final String vehicleType;
  final String vehicleNumber;
  final String status;
  final DateTime? createdAt;

  bool get isActive => status.toLowerCase() == 'active' || status.toLowerCase() == 'on_duty';

  factory DriverModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return DriverModel.fromMap(doc.id, doc.data() ?? {});
  }

  factory DriverModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parsedDate;
    final createdVal = map['createdAt'];
    if (createdVal is Timestamp) {
      parsedDate = createdVal.toDate();
    } else if (createdVal is String) {
      parsedDate = DateTime.tryParse(createdVal);
    }

    return DriverModel(
      id: id,
      name: (map['name'] ?? map['driverName'] ?? 'Unknown Driver').toString().trim(),
      phone: (map['phone'] ?? map['phoneNumber'] ?? '').toString().trim(),
      licenseNumber: (map['licenseNumber'] ?? map['license'] ?? '').toString().trim(),
      vehicleType: (map['vehicleType'] ?? 'EV Cart').toString().trim(),
      vehicleNumber: (map['vehicleNumber'] ?? map['registrationNumber'] ?? '').toString().trim(),
      status: (map['status'] ?? 'active').toString().trim(),
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? licenseNumber,
    String? vehicleType,
    String? vehicleNumber,
    String? status,
    DateTime? createdAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

