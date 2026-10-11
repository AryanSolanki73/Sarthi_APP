import 'package:sarthi_app/models/user_model.dart';

class AuthController {
  static const collegeDomain = '@iitrpr.ac.in';

  String? validateCollegeEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return 'Enter your college email address';
    if (!email.endsWith(collegeDomain)) {
      return 'Please use your $collegeDomain email';
    }
    return null;
  }

  /// Placeholder for the OTP API call. It returns the user identity that a
  /// backend would use to decide which dashboard is opened after verification.
  Future<UserModel> sendSignInCode(String email) => Future.value(
        UserModel(email: email.trim().toLowerCase(), role: UserRole.student),
      );
}
