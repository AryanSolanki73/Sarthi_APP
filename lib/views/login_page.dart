import 'package:flutter/material.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/services/auth_service.dart';
import 'package:sarthi_app/services/credential_storage.dart';
import 'package:sarthi_app/views/transit/transit_home_view.dart';
import 'package:sarthi_app/views/widgets/google_logo_icon.dart';

/// Screen for authenticating users via college email & password or Google Sign-In.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@iitrpr\.ac\.in$',
    caseSensitive: false,
  );

  static const _primaryGreen = Color(0xFF009B6A);
  static const _errorRed = Color(0xFFBA1A1A);
  static const _neutralText = Color(0xFF17201E);
  static const _mutedText = Color(0xFF7B8582);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController(FirebaseAuthService());

  bool _hidePassword = true;
  bool _isSigningIn = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Loads saved user credentials from local secure storage.
  Future<void> _loadSavedCredentials() async {
    final credentials = await CredentialStorage.loadCredentials();
    if (credentials != null && mounted) {
      setState(() {
        _emailController.text = credentials['email'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
      });
    }
  }

  /// Displays an error toast with user-friendly formatting.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: _errorRed,
      ),
    );
  }

  /// Navigates to the main transit home view after successful authentication.
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const TransitHomeView()),
    );
  }

  /// Authenticates using IIT Ropar email and password credentials.
  Future<void> _signInWithEmail() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_emailRegex.hasMatch(email)) {
      _showError('Please enter a valid @iitrpr.ac.in email address');
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      await _authController.signIn(email: email, password: password);
      await CredentialStorage.saveCredentials(email: email, password: password);
      _navigateToHome();
    } catch (e) {
      await CredentialStorage.clearCredentials();
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  /// Signs in using Google Authentication.
  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    try {
      final profile = await _authController.signInWithGoogle();
      if (profile == null) return; // User cancelled
      _navigateToHome();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(26, 72, 26, 28 + keyboardInset),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _VehicleMark(),
                const SizedBox(height: 30),
                _buildHeadline(),
                const SizedBox(height: 32),
                _buildFormCard(),
                const SizedBox(height: 28),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your campus.\nOne easy ride.',
          style: TextStyle(
            color: _neutralText,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.08,
            letterSpacing: -1.1,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Free EV carts and city shuttles, together.',
          style: TextStyle(color: _mutedText, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E6E3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign in with college email',
              style: TextStyle(
                color: Color(0xFF202724),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use an @iitrpr.ac.in address. Your assigned role opens automatically.',
              style: TextStyle(
                color: Color(0xFF838B88),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            _AuthTextField(
              controller: _emailController,
              hintText: 'College email',
              icon: Icons.alternate_email_rounded,
              validator: _authController.validateCollegeEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _AuthTextField(
              controller: _passwordController,
              hintText: 'Password',
              icon: Icons.lock_outline_rounded,
              validator: _authController.validatePassword,
              obscureText: _hidePassword,
              suffix: IconButton(
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                tooltip: _hidePassword ? 'Show password' : 'Hide password',
              ),
              onSubmitted: (_) => _signInWithEmail(),
            ),
            const SizedBox(height: 20),
            _buildEmailSignInButton(),
            const SizedBox(height: 18),
            _buildDivider(),
            const SizedBox(height: 18),
            _buildGoogleSignInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSignInButton() {
    final bool isBusy = _isSigningIn || _isGoogleLoading;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: isBusy ? null : _signInWithEmail,
        style: FilledButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSigningIn
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFD1D5DB))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B9692),
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFD1D5DB))),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    final bool isBusy = _isSigningIn || _isGoogleLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isBusy ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryGreen,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleLogoIcon(size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        'IIT Ropar Mobility · Student · Driver · Admin',
        style: TextStyle(color: Color(0xFF9BA3A0), fontSize: 13),
      ),
    );
  }
}

/// Logo mark displaying the campus transit shuttle icon.
class _VehicleMark extends StatelessWidget {
  const _VehicleMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFF009B6A),
      borderRadius: BorderRadius.circular(23),
    ),
    child: const Icon(Icons.directions_bus, color: Colors.white, size: 37),
  );
}

/// Reusable styled text field for email and password input.
class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    obscureText: obscureText,
    onFieldSubmitted: onSubmitted,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF3F4F3),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
    ),
  );
}
