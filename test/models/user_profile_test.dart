import 'package:flutter_test/flutter_test.dart';
import 'package:sarthi_app/models/user_profile.dart';

void main() {
  group('UserProfile Model Unit Tests', () {
    test('creates UserProfile with default student role', () {
      final profile = UserProfile(
        uid: 'user_123',
        username: 'Aryan Solanki',
        email: 'aryan@iitrpr.ac.in',
      );

      expect(profile.uid, 'user_123');
      expect(profile.username, 'Aryan Solanki');
      expect(profile.name, 'Aryan Solanki');
      expect(profile.email, 'aryan@iitrpr.ac.in');
      expect(profile.role, 'student');
      expect(profile.phone, isNull);
      expect(profile.hostel, isNull);
      expect(profile.isProfileComplete, isFalse);
    });

    test('isProfileComplete returns true only when hostel and phone are present', () {
      final incomplete1 = UserProfile(
        uid: 'user_1',
        username: 'Test',
        email: 'test@iitrpr.ac.in',
        phone: '9876543210',
        hostel: '',
      );
      expect(incomplete1.isProfileComplete, isFalse);

      final incomplete2 = UserProfile(
        uid: 'user_2',
        username: 'Test',
        email: 'test@iitrpr.ac.in',
        phone: null,
        hostel: 'Satluj',
      );
      expect(incomplete2.isProfileComplete, isFalse);

      final complete = UserProfile(
        uid: 'user_3',
        username: 'Test',
        email: 'test@iitrpr.ac.in',
        phone: '9876543210',
        hostel: 'Satluj (Boys Hostel)',
      );
      expect(complete.isProfileComplete, isTrue);
    });

    test('serializes toMap strictly alphabetically without duplicate attributes', () {
      final now = DateTime.now();
      final original = UserProfile(
        uid: 'usr_456',
        username: 'Devansh Sharma',
        email: 'devansh@iitrpr.ac.in',
        photoUrl: 'https://example.com/photo.jpg',
        phone: '9876543210',
        hostel: 'Beas (Boys Hostel)',
        role: 'student',
        createdAt: now,
      );

      final map = original.toMap();

      // Verify no duplicates
      expect(map.containsKey('name'), isFalse);
      expect(map.containsKey('phoneNumber'), isFalse);

      // Verify exact keys and strict alphabetical order
      final expectedKeys = [
        'createdAt',
        'email',
        'hostel',
        'isProfileComplete',
        'phone',
        'photoUrl',
        'role',
        'uid',
        'updatedAt',
        'username',
      ];
      expect(map.keys.toList(), expectedKeys);

      expect(map['uid'], 'usr_456');
      expect(map['username'], 'Devansh Sharma');
      expect(map['email'], 'devansh@iitrpr.ac.in');
      expect(map['phone'], '9876543210');
      expect(map['hostel'], 'Beas (Boys Hostel)');
      expect(map['role'], 'student');
      expect(map['isProfileComplete'], isTrue);

      final parsed = UserProfile.fromMap(map);
      expect(parsed.uid, original.uid);
      expect(parsed.username, original.username);
      expect(parsed.email, original.email);
      expect(parsed.photoUrl, original.photoUrl);
      expect(parsed.phone, original.phone);
      expect(parsed.hostel, original.hostel);
      expect(parsed.role, 'student');
      expect(parsed.isProfileComplete, isTrue);
    });

    test('fromMap falls back gracefully when reading legacy documents', () {
      final legacyMap = <String, dynamic>{
        'uid': 'usr_legacy',
        'name': 'Legacy Student',
        'phoneNumber': '9123456789',
        'email': 'legacy@iitrpr.ac.in',
        'role': 'student',
      };

      final profile = UserProfile.fromMap(legacyMap);
      expect(profile.uid, 'usr_legacy');
      expect(profile.username, 'Legacy Student');
      expect(profile.phone, '9123456789');
      expect(profile.role, 'student');
      expect(profile.hostel, isNull);
      expect(profile.isProfileComplete, isFalse);
    });

    test('copyWith updates specified fields only', () {
      final original = UserProfile(
        uid: 'usr_orig',
        username: 'Original Name',
        email: 'orig@iitrpr.ac.in',
        hostel: 'Satluj',
        phone: '1234567890',
        role: 'student',
      );

      final updated = original.copyWith(
        username: 'Updated Name',
        hostel: 'Chenab',
      );

      expect(updated.username, 'Updated Name');
      expect(updated.hostel, 'Chenab');
      expect(updated.phone, '1234567890');
      expect(updated.email, 'orig@iitrpr.ac.in');
      expect(updated.role, 'student');
    });
  });
}
