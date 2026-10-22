import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/models/user_profile.dart';
import 'package:sarthi_app/services/credential_storage.dart';
import 'package:sarthi_app/views/login_page.dart';

/// User profile view showing Google account details and a logout button.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Loads current user details from Firebase Auth or Firestore database.
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Try fetching stored profile from Firestore database
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _profile = UserProfile.fromMap(doc.data()!);
      } else {
        // Fallback to Firebase Auth user info
        _profile = UserProfile(
          uid: user.uid,
          name: user.displayName ?? 'Student',
          email: user.email ?? '',
          photoUrl: user.photoURL,
          role: 'student',
        );
      }
    } catch (_) {
      // Offline fallback
      _profile = UserProfile(
        uid: user.uid,
        name: user.displayName ?? 'Student',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        role: 'student',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Signs the user out of Firebase and Google, then returns to login screen.
  Future<void> _logout() async {
    try {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
      await CredentialStorage.clearCredentials();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const BackButton(),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.emerald),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Avatar / Photo
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF009B6A),
                      backgroundImage: (_profile?.photoUrl != null && _profile!.photoUrl!.isNotEmpty)
                          ? NetworkImage(_profile!.photoUrl!)
                          : null,
                      child: (_profile?.photoUrl == null || _profile!.photoUrl!.isEmpty)
                          ? Text(
                              (_profile?.name.isNotEmpty == true)
                                  ? _profile!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User name
                  Text(
                    _profile?.name ?? 'Student',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14241F),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // User email
                  Text(
                    _profile?.email ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7873),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (_profile?.role ?? 'student').toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF00875A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.school_outlined, color: AppColors.emerald),
                          title: Text('Institution'),
                          subtitle: Text('IIT Ropar Transit Network'),
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: Icon(Icons.verified_user_outlined, color: AppColors.emerald),
                          title: Text('Account Status'),
                          subtitle: Text('Active Member'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
