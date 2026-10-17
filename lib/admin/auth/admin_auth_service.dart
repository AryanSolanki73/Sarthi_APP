import 'package:firebase_auth/firebase_auth.dart';
class AdminAuthService {
  AdminAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign in with Google in Flutter Web.
  Future<UserCredential> signInWithGoogle() {
    final provider = GoogleAuthProvider();
    return _auth.signInWithPopup(provider);
  }

  // Sign out from Firebase.
  Future<void> signOut() {
    return _auth.signOut();
  }
}