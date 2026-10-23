/// The roles that the backend can assign after a user verifies their email.
enum UserRole { student, admin }

/// Model: a plain object that represents a signed-in user.
///
/// It contains data only; it does not contain UI widgets or sign-in logic.
class UserModel {
  const UserModel({this.name, required this.email, required this.role});

  final String? name;
  final String email;
  final UserRole role;
}
