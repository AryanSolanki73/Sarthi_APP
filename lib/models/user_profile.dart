/// Model representing the user profile information.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // student, driver, admin
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role = 'student',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Converts the UserProfile into a Map to store in Firebase (Firestore database).
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl ?? '',
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a UserProfile from a Firebase map/document.
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? 'Student',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String? ?? 'student',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
