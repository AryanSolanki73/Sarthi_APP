enum UserRole { student, driver, admin }

class UserModel {
  const UserModel({required this.email, required this.role});

  final String email;
  final UserRole role;
}
