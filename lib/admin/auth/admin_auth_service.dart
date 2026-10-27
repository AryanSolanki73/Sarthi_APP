
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  AdminAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Email/password login, followed by admin verification.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    try {
      await _verifyAdminAccess(credential.user!);
      return credential;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  // Google login, followed by admin verification.
  Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();

    final credential = await _auth.signInWithPopup(provider);

    try {
      await _verifyAdminAccess(credential.user!);
      return credential;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  // Verify the authenticated user's Firestore admin record.
  Future<void> _verifyAdminAccess(User user) async {
    final document = await _firestore
        .collection('admins')
        .doc(user.uid)
        .get();

    if (!document.exists) {
      throw FirebaseAuthException(
        code: 'admin-not-authorized',
        message: 'This account is not authorized as an administrator.',
      );
    }

    final data = document.data();

    final isAdmin = data?['role'] == 'admin';
    final isActive = data?['active'] == true;

    if (!isAdmin || !isActive) {
      throw FirebaseAuthException(
        code: 'admin-not-authorized',
        message: 'This account is not authorized as an administrator.',
      );
    }
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
