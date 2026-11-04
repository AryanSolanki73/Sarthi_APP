import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/admin/models/driver_model.dart';

void main() {
  group('DriverModel Unit Tests', () {
    test('creates DriverModel and checks isActive status', () {
      final activeDriver = DriverModel(
        id: 'driver_1',
        name: 'Ramesh Kumar',
        phone: '+91 98765 43210',
        licenseNumber: 'PB-12-2018-00912',
        vehicleType: 'EV Cart',
        vehicleNumber: 'PB-12-EV-01',
        status: 'active',
      );

      expect(activeDriver.id, 'driver_1');
      expect(activeDriver.name, 'Ramesh Kumar');
      expect(activeDriver.phone, '+91 98765 43210');
      expect(activeDriver.licenseNumber, 'PB-12-2018-00912');
      expect(activeDriver.vehicleType, 'EV Cart');
      expect(activeDriver.vehicleNumber, 'PB-12-EV-01');
      expect(activeDriver.isActive, isTrue);

      final inactiveDriver = activeDriver.copyWith(status: 'inactive');
      expect(inactiveDriver.isActive, isFalse);

      final onDutyDriver = activeDriver.copyWith(status: 'on_duty');
      expect(onDutyDriver.isActive, isTrue);
    });

    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime(2026, 11, 5, 10, 30);
      final driver = DriverModel(
        id: 'driver_2',
        name: 'Harpreet Singh',
        phone: '9812345678',
        licenseNumber: 'PB-12-2020-00845',
        vehicleType: 'Bus',
        vehicleNumber: 'PB-12-Bus-01',
        status: 'active',
        createdAt: now,
      );

      final map = driver.toMap();
      expect(map['name'], 'Harpreet Singh');
      expect(map['phone'], '9812345678');
      expect(map['licenseNumber'], 'PB-12-2020-00845');
      expect(map['vehicleType'], 'Bus');
      expect(map['vehicleNumber'], 'PB-12-Bus-01');
      expect(map['status'], 'active');

      final recreated = DriverModel.fromMap('driver_2', {
        'name': 'Harpreet Singh',
        'phone': '9812345678',
        'licenseNumber': 'PB-12-2020-00845',
        'vehicleType': 'Bus',
        'vehicleNumber': 'PB-12-Bus-01',
        'status': 'active',
        'createdAt': now.toIso8601String(),
      });

      expect(recreated.id, 'driver_2');
      expect(recreated.name, 'Harpreet Singh');
      expect(recreated.phone, '9812345678');
      expect(recreated.licenseNumber, 'PB-12-2020-00845');
      expect(recreated.vehicleType, 'Bus');
      expect(recreated.vehicleNumber, 'PB-12-Bus-01');
      expect(recreated.status, 'active');
      expect(recreated.createdAt, now);
    });

    test('fromMap gracefully handles missing attributes', () {
      final minimal = DriverModel.fromMap('driver_min', {});
      expect(minimal.id, 'driver_min');
      expect(minimal.name, 'Unknown Driver');
      expect(minimal.phone, '');
      expect(minimal.licenseNumber, '');
      expect(minimal.vehicleType, 'EV Cart');
      expect(minimal.status, 'active');
      expect(minimal.isActive, isTrue);
    });
  });
}

