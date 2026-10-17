import 'package:firebase_auth/firebase_auth.dart';
import 'package:sarthi_app/models/user_model.dart';

/// Contract for authentication requests.
abstract class AuthService {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> createAccount({required String name, required String email, required String password});
}

/// Firebase authentication implementation.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _customAuth = firebaseAuth;

  final FirebaseAuth? _customAuth;

  /// Returns the Firebase Auth instance lazily.
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  /// Signs the user into Firebase using email and password.
  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('User authentication failed.');
      }

      return UserModel(
        email: user.email ?? email,
        name: user.displayName,
        role: UserRole.student,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    }
  }

  /// Creates a new user account with Firebase authentication.
  @override
  Future<UserModel> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Failed to create account.');
      }

      await user.updateDisplayName(name.trim());

      return UserModel(
        name: name.trim(),
        email: user.email ?? email,
        role: UserRole.student,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    }
  }

  /// Converts Firebase error codes to readable user messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Account not registered or invalid password. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'Authentication failed. Please check your network and try again.';
    }
  }
}

/// Temporary mock authentication service for testing.
class MockAuthService implements AuthService {
  /// Signs the user in with mock credentials.
  @override
  Future<UserModel> signIn({required String email, required String password}) => Future.value(
    UserModel(email: email.trim().toLowerCase(), role: UserRole.student),
  );

  /// Creates a mock user account.
  @override
  Future<UserModel> createAccount({required String name, required String email, required String password}) => Future.value(
    UserModel(name: name.trim(), email: email.trim().toLowerCase(), role: UserRole.student),
  );
}
