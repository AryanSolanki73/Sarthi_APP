import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sarthi_app/models/user_model.dart';

/// Contract for authentication requests.
abstract class AuthService {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> createAccount({required String name, required String email, required String password});
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
}

/// Firebase authentication implementation.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _customAuth = firebaseAuth;

  final FirebaseAuth? _customAuth;
  bool _googleSignInInitialized = false;

  /// Web Client ID from Firebase Console / Google Cloud Credentials.
  /// If set, this overrides or provides the serverClientId needed on Android.
  /// (e.g. '751583488405-xxxxxxxxxxxx.apps.googleusercontent.com')
  static const String? serverClientId = null;

  /// Returns the Firebase Auth instance lazily.
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
      _googleSignInInitialized = true;
    }
  }

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

  /// Signs the user in using Google credentials with Firebase.
  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount account =
            await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = account.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User authentication failed.');
      }

      return UserModel(
        name: user.displayName,
        email: user.email ?? '',
        role: UserRole.student,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      final desc = e.description ?? e.code.name;
      if (desc.contains('serverClientId')) {
        throw Exception(
          'Missing Web Client ID. Please re-download google-services.json from Firebase Console or set serverClientId in auth_service.dart',
        );
      }
      throw Exception('Google sign-in error: $desc');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('abort')) {
        return null;
      }
      rethrow;
    }
  }

  /// Signs out of Firebase and Google.
  @override
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
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
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign-in was cancelled.';
      case 'popup-blocked':
        return 'The sign-in popup was blocked by your browser. Please allow popups and try again.';
      case 'account-exists-with-different-credential':
        return 'This email is already registered using another sign-in method.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled in Firebase Console. Please enable Google in Authentication > Sign-in method.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
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

  /// Simulates a successful Google sign-in.
  @override
  Future<UserModel?> signInWithGoogle() => Future.value(
    const UserModel(
      name: 'Google Student',
      email: 'student@iitrpr.ac.in',
      role: UserRole.student,
    ),
  );

  /// Simulates sign out.
  @override
  Future<void> signOut() => Future.value();
}
