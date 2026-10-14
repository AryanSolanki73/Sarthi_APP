import 'package:sarthi_app/models/user_model.dart';

/// Contract for authentication requests. A future HttpAuthService can use the
/// backend API while views and controllers continue using this same contract.
abstract class AuthService {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> createAccount({required String name, required String email, required String password});
}

/// Temporary frontend-only authentication response.
class MockAuthService implements AuthService {
  @override
  Future<UserModel> signIn({required String email, required String password}) => Future.value(
    UserModel(email: email.trim().toLowerCase(), role: UserRole.student),
  );

  @override
  Future<UserModel> createAccount({required String name, required String email, required String password}) => Future.value(
    UserModel(name: name.trim(), email: email.trim().toLowerCase(), role: UserRole.student),
  );
}
