/// Model representing the user profile information stored in Firestore.
class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String? hostel;
  final String? phone;
  final String role; // student, admin
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    String? username,
    String? name,
    required this.email,
    this.hostel,
    String? phone,
    String? phoneNumber,
    this.role = 'student',
    this.photoUrl,
    DateTime? createdAt,
    this.updatedAt,
  })  : username = (username ?? name ?? 'Student').trim().isNotEmpty
            ? (username ?? name ?? 'Student').trim()
            : 'Student',
        phone = (phone ?? phoneNumber)?.trim().isNotEmpty == true
            ? (phone ?? phoneNumber)!.trim()
            : null,
        createdAt = createdAt ?? DateTime.now();

  /// Compatibility getters for existing codebase references.
  String get name => username;
  String? get phoneNumber => phone;

  /// Returns true if the user has completed required profile details (Hostel and Phone).
  bool get isProfileComplete =>
      hostel != null &&
      hostel!.trim().isNotEmpty &&
      phone != null &&
      phone!.trim().isNotEmpty;

  /// Creates a copy of this UserProfile with updated fields.
  UserProfile copyWith({
    String? uid,
    String? username,
    String? name,
    String? email,
    String? hostel,
    String? phone,
    String? phoneNumber,
    String? role,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      username: username ?? name ?? this.username,
      email: email ?? this.email,
      hostel: hostel ?? this.hostel,
      phone: phone ?? phoneNumber ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the UserProfile into a clean Map without duplicates,
  /// ordered strictly alphabetically for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'email': email,
      'hostel': hostel ?? '',
      'isProfileComplete': isProfileComplete,
      'phone': phone ?? '',
      'photoUrl': photoUrl ?? '',
      'role': role.trim().isEmpty ? 'student' : role,
      'uid': uid,
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      'username': username,
    };
  }

  /// Creates a UserProfile from a Firebase map/document.
  /// Handles both new clean schema and legacy documents gracefully.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final phoneVal = (map['phone'] as String?)?.trim() ??
        (map['phoneNumber'] as String?)?.trim() ??
        '';
    final userVal = (map['username'] as String?)?.trim() ??
        (map['name'] as String?)?.trim() ??
        '';
    final hostelVal = (map['hostel'] as String?)?.trim() ?? '';
    final rawRole = (map['role'] as String?)?.trim();

    return UserProfile(
      uid: map['uid'] as String? ?? '',
      username: userVal.isNotEmpty ? userVal : 'Student',
      email: (map['email'] as String?)?.trim() ?? '',
      hostel: hostelVal.isNotEmpty ? hostelVal : null,
      phone: phoneVal.isNotEmpty ? phoneVal : null,
      role: (rawRole != null && rawRole.isNotEmpty) ? rawRole : 'student',
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}
