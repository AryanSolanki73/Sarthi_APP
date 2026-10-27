
class StudentModel {
  final String uid;
  final String username;
  final String email;
  final String role;
  final String hostel;
  final String phone;
  final String enrollmentStatus;
  final DateTime? createdAt;

  StudentModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.role,
    required this.hostel,
    required this.phone,
    required this.enrollmentStatus,
    this.createdAt,
  });

  // Convert Firestore data into a StudentModel.
  factory StudentModel.fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    return StudentModel(
      uid: uid,
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      hostel: data['hostel'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      enrollmentStatus:
          data['enrollmentStatus'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
    );
  }

  // Convert the model into data for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'hostel': hostel,
      'phone': phone,
      'enrollmentStatus': enrollmentStatus,
      'createdAt': createdAt,
    };
  }
}
