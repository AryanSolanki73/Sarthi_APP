import 'package:sarthi_app/models/user_model.dart';
import 'package:sarthi_app/services/auth_service.dart';

/// Controller: keeps authentication rules and actions out of the UI.
///
/// The service behind this controller can later call real login APIs.
class AuthController {
  AuthController(this._service);

  final AuthService _service;
  // Only email addresses from this college domain can create or access an account.
  static const collegeDomain = '@iitrpr.ac.in';

  /// Used by the email field in the view to show an error message, if needed.
  String? validateCollegeEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return 'Enter your college email address';
    if (!email.endsWith(collegeDomain)) {
      return 'Please use your $collegeDomain email';
    }
    return null;
  }

  String? validateName(String? value) {
    if ((value?.trim().length ?? 0) < 2) return 'Enter your full name';
    return null;
  }

  String? validatePassword(String? value) {
    if ((value?.length ?? 0) < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validatePasswordConfirmation(String? value, String password) {
    if (value != password) return 'Passwords do not match';
    return null;
  }

  Future<UserModel> signIn({required String email, required String password}) =>
      _service.signIn(email: email, password: password);

  Future<UserModel> createAccount({required String name, required String email, required String password}) =>
      _service.createAccount(name: name, email: email, password: password);

  Future<UserModel?> signInWithGoogle() => _service.signInWithGoogle();

  Future<void> signOut() => _service.signOut();
}
