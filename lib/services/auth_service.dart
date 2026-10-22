import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sarthi_app/models/user_model.dart';
import 'package:sarthi_app/models/user_profile.dart';

/// Contract for authentication requests.
abstract class AuthService {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> createAccount({
    required String name,
    required String email,
    required String password,
  });
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
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
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

      // Save user profile to Firebase Firestore database
      final profile = UserProfile(
        uid: user.uid,
        name: name.trim(),
        email: user.email ?? email,
        role: 'student',
      );
      await saveUserToDatabase(profile);

      return UserModel(
        name: name.trim(),
        email: user.email ?? email,
        role: UserRole.student,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    }
  }

  /// Signs in or registers the user using Google Sign-In.
  @override
  Future<UserProfile?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the Google sign-in dialog
        return null;
      }

      // 2. Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a credential for Firebase Auth
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with Google.');
      }

      // 5. Create user profile with data populated from Google account
      final profile = UserProfile(
        uid: user.uid,
        name: user.displayName ?? googleUser.displayName ?? 'Student',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
        role: 'student',
      );

      // 6. Store user in Firebase database
      await saveUserToDatabase(profile);

      return profile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e.code));
    } catch (e) {
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('cancelled')) {
        return null;
      }
      throw Exception(
        'Google Sign-In failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Stores or updates user profile in Firebase Firestore database.
  Future<void> saveUserToDatabase(UserProfile profile) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Note: Could not save user profile to Firestore: $e');
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
  @override
  Future<UserModel> signIn({required String email, required String password}) =>
      Future.value(
        UserModel(email: email.trim().toLowerCase(), role: UserRole.student),
      );

  @override
  Future<UserModel> createAccount({
    required String name,
    required String email,
    required String password,
  }) => Future.value(
    UserModel(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      role: UserRole.student,
    ),
  );

  @override
  Future<UserProfile?> signInWithGoogle() => Future.value(
    UserProfile(
      uid: 'mock_google_uid',
      name: 'Google Student',
      email: 'student@iitrpr.ac.in',
      photoUrl: null,
      role: 'student',
    ),
  );
}
