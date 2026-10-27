import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/models/user_profile.dart';
import 'package:sarthi_app/services/auth_service.dart';
import 'package:sarthi_app/services/credential_storage.dart';
import 'package:sarthi_app/views/login_page.dart';
import 'package:sarthi_app/views/transit/transit_home_view.dart';

/// User profile view allowing students to view and update their profile details
/// (username, email, hostel, phone number, and default student role) in Firestore.
/// Also serves as the mandatory onboarding screen on first-time login.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.isFirstTimeSetup = false,
    this.initialProfile,
    this.authService,
    this.onProfileSaved,
    this.onNavigateAfterSetup,
  });

  /// If true, this page acts as a mandatory profile completion gate for first-time logins.
  final bool isFirstTimeSetup;

  /// Optional pre-loaded profile for tests or immediate rendering.
  final UserProfile? initialProfile;

  /// Optional auth service for test injection.
  final AuthService? authService;

  /// Callback executed when the profile is successfully saved.
  final VoidCallback? onProfileSaved;

  /// Optional custom navigation handler after first time setup completion.
  final void Function(BuildContext context)? onNavigateAfterSetup;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  late bool _isEditing;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hostelController = TextEditingController();

  late final AuthController _authController;

  static const List<String> hostelOptions = [
    'Satluj (Boys Hostel)',
    'Beas (Boys Hostel)',
    'Chenab (Boys Hostel)',
    'Raavi (Girls Hostel)',
    'Brahmaputra (Girls Hostel)',
    'Day Scholar / Off-Campus',
  ];

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      widget.authService ?? FirebaseAuthService(),
    );
    _isEditing = widget.isFirstTimeSetup;

    if (widget.initialProfile != null) {
      _applyProfile(widget.initialProfile!);
      _isLoading = false;
    } else {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _hostelController.dispose();
    super.dispose();
  }

  String? _selectedHostel;

  List<String> get _availableHostelOptions {
    final options = List<String>.from(hostelOptions);
    if (_selectedHostel != null &&
        _selectedHostel!.isNotEmpty &&
        !options.contains(_selectedHostel)) {
      options.insert(0, _selectedHostel!);
    }
    return options;
  }

  void _applyProfile(UserProfile profile) {
    _profile = profile;
    _nameController.text = profile.name;
    _phoneController.text = profile.phoneNumber ?? '';
    _selectedHostel = profile.hostel;
    _hostelController.text = profile.hostel ?? '';
  }

  String? get _currentAuthUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String? get _currentAuthEmail {
    try {
      return FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  String? get _currentAuthPhoto {
    try {
      return FirebaseAuth.instance.currentUser?.photoURL;
    } catch (_) {
      return null;
    }
  }

  /// Loads current user details from Firestore database or Firebase Auth.
  Future<void> _loadProfile() async {
    try {
      final uid = _currentAuthUid;
      if (uid == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Try fetching stored profile from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromMap(doc.data()!);
        _applyProfile(profile);
      } else {
        // Fallback with Google/Auth info
        final fallback = UserProfile(
          uid: uid,
          name: 'Student',
          email: _currentAuthEmail ?? '',
          photoUrl: _currentAuthPhoto,
          role: 'student',
        );
        _applyProfile(fallback);
      }
    } catch (_) {
      final fallback = UserProfile(
        uid: _currentAuthUid ?? 'guest',
        name: 'Student',
        email: _currentAuthEmail ?? '',
        photoUrl: _currentAuthPhoto,
        role: 'student',
      );
      _applyProfile(fallback);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Validates and saves the updated profile to Firestore.
  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final currentUid = _profile?.uid ?? _currentAuthUid ?? 'unknown';
      final currentEmail = _profile?.email ?? _currentAuthEmail ?? '';
      final currentPhoto = _profile?.photoUrl ?? _currentAuthPhoto;

      final updatedProfile = UserProfile(
        uid: currentUid,
        name: _nameController.text.trim(),
        email: currentEmail,
        photoUrl: currentPhoto,
        phoneNumber: _phoneController.text.trim(),
        hostel: (_selectedHostel != null && _selectedHostel!.isNotEmpty)
            ? _selectedHostel
            : _hostelController.text.trim(),
        role: _profile?.role ?? 'student',
        createdAt: _profile?.createdAt,
        updatedAt: DateTime.now(),
      );

      // Save using auth controller service or direct Firestore merge
      try {
        await _authController.saveUserProfile(updatedProfile);
      } catch (_) {
        // Fallback direct Firestore update if Firebase is active
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .set(updatedProfile.toMap());
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
      });

      widget.onProfileSaved?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // If completing first-time login setup, navigate to home screen
      if (widget.isFirstTimeSetup) {
        if (widget.onNavigateAfterSetup != null) {
          widget.onNavigateAfterSetup!(context);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const TransitHomeView()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        title: Text(
          widget.isFirstTimeSetup ? 'Complete Your Profile' : 'My Profile',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: widget.isFirstTimeSetup ? null : const BackButton(),
        automaticallyImplyLeading: !widget.isFirstTimeSetup,
        actions: [
          if (!widget.isFirstTimeSetup && !_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
              tooltip: _isEditing ? 'Cancel Edit' : 'Edit Profile',
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    // Reset to current profile values
                    if (_profile != null) _applyProfile(_profile!);
                  }
                  _isEditing = !_isEditing;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.emerald),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // First time login banner
                    if (widget.isFirstTimeSetup) ...[
                      _buildFirstTimeBanner(),
                      const SizedBox(height: 24),
                    ],

                    // Avatar & Name Card
                    _buildAvatarHeader(),

                    const SizedBox(height: 24),

                    // Information / Form Fields Card
                    _buildDetailsCard(),

                    const SizedBox(height: 24),

                    // Transit Pass / Institution Info Card
                    _buildTransitPassCard(),

                    const SizedBox(height: 32),

                    // Action buttons
                    if (_isEditing || widget.isFirstTimeSetup)
                      _buildSaveButton()
                    else
                      _buildLogoutButton(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFirstTimeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.how_to_reg_rounded,
              color: AppColors.emerald,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First Time Setup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Welcome to Sarthi! Please provide your phone number and hostel to activate campus transit and ride requests.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF047857),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader() {
    final photoUrl = _profile?.photoUrl;
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : (_profile?.name ?? 'Student');
    final role = _profile?.role ?? 'student';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.emerald,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14241F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _profile?.email ?? '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7873)),
          ),
          const SizedBox(height: 10),
          // Role Chip: defaults to 'student'
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB4E6D2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 14,
                  color: Color(0xFF00875A),
                ),
                const SizedBox(width: 6),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF00875A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),

          // Full Name / Username
          if (_isEditing)
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                label: 'Full Name / Username',
                icon: Icons.person_outline,
              ),
              validator: _authController.validateName,
            )
          else
            _buildReadOnlyField(
              icon: Icons.person_outline,
              label: 'Full Name / Username',
              value: _profile?.name ?? 'Student',
            ),

          const SizedBox(height: 16),

          // College Email
          _buildReadOnlyField(
            icon: Icons.alternate_email,
            label: 'College Email Address',
            value: _profile?.email ?? '',
            helper: 'Linked to Google / Institute Account',
          ),

          const SizedBox(height: 16),

          // Hostel Dropdown
          if (_isEditing)
            DropdownButtonFormField<String>(
              key: const Key('hostel_dropdown'),
              initialValue:
                  (_selectedHostel != null &&
                      _availableHostelOptions.contains(_selectedHostel))
                  ? _selectedHostel
                  : null,
              isExpanded: true,
              hint: const Text(
                'Select your hostel',
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.emerald,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(14),
              decoration: _inputDecoration(
                label: 'Hostel / Residence',
                icon: Icons.hotel_outlined,
              ),
              items: _availableHostelOptions.map((hostel) {
                return DropdownMenuItem<String>(
                  value: hostel,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home_work_outlined,
                        size: 18,
                        color: AppColors.emerald,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hostel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? val) {
                setState(() {
                  _selectedHostel = val;
                  _hostelController.text = val ?? '';
                });
              },
              validator: (val) =>
                  _authController.validateHostel(val ?? _selectedHostel),
            )
          else
            _buildReadOnlyField(
              icon: Icons.hotel_outlined,
              label: 'Hostel Residence',
              value: _profile?.hostel?.isNotEmpty == true
                  ? _profile!.hostel!
                  : 'Not specified',
              isWarning: _profile?.hostel == null || _profile!.hostel!.isEmpty,
            ),

          const SizedBox(height: 16),

          // Phone Number
          if (_isEditing)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                hint: 'e.g. 9876543210',
              ),
              validator: _authController.validatePhoneNumber,
            )
          else
            _buildReadOnlyField(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              value: _profile?.phoneNumber?.isNotEmpty == true
                  ? _profile!.phoneNumber!
                  : 'Not specified',
              isWarning:
                  _profile?.phoneNumber == null ||
                  _profile!.phoneNumber!.isEmpty,
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
    String? helper,
    bool isWarning = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.emerald, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isWarning
                      ? const Color(0xFFD97706)
                      : const Color(0xFF111827),
                ),
              ),
              if (helper != null) ...[
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.emerald),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.emerald, width: 2),
      ),
    );
  }

  Widget _buildTransitPassCard() {
    return Container(
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
            leading: Icon(
              Icons.verified_user_outlined,
              color: AppColors.emerald,
            ),
            title: Text('Account Status'),
            subtitle: Text('Active Student Rider'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                widget.isFirstTimeSetup
                    ? Icons.arrow_forward_rounded
                    : Icons.check_circle_outline,
              ),
        label: Text(
          _isSaving
              ? 'Saving...'
              : widget.isFirstTimeSetup
              ? 'Save & Continue to Transit'
              : 'Save Changes',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
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
    );
  }
}
