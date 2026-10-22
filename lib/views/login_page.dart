import 'package:flutter/material.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';
import 'package:sarthi_app/services/auth_service.dart';
import 'package:sarthi_app/services/credential_storage.dart';
import 'package:sarthi_app/views/transit/transit_home_view.dart';
import 'package:sarthi_app/views/widgets/google_logo_icon.dart';

/// Email-and-password sign-in screen.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// Creates the state object for the login page widget.
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController(FirebaseAuthService());
  bool _hidePassword = true;
  bool _isSigningIn = false;
  bool _isGoogleLoading = false;

  /// Signs in using a Google account.
  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    try {
      final profile = await _authController.signInWithGoogle();
      if (profile == null) return;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const TransitHomeView()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  /// Initializes the widget state.
  /// Calls the procedure to load saved user credentials.
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Loads saved user credentials from the local storage file.
  /// Sets the email and password values in the input controllers.
  Future<void> _loadSavedCredentials() async {
    final credentials = await CredentialStorage.loadCredentials();
    if (credentials != null && mounted) {
      setState(() {
        _emailController.text = credentials['email'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
      });
    }
  }

  /// Releases the text editing controllers from memory.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@iitrpr\.ac\.in$',
    caseSensitive: false,
  );

  /// Validates the user inputs and authenticates the account.
  /// Saves credentials to local storage and navigates to the home view.
  Future<void> _signIn(String email, String pass) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid @iitrpr.ac.in email address'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      // 1. Verify with Firebase FIRST. This rejects unregistered accounts.
      await _authController.signIn(email: email, password: pass);

      // 2. Only save credentials locally if Firebase sign-in succeeded.
      await CredentialStorage.saveCredentials(email: email, password: pass);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const TransitHomeView()),
      );
    } catch (e) {
      // Clear any invalid saved credentials
      await CredentialStorage.clearCredentials();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  /// Signs the user in using Google authentication via Firebase.
  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleSigningIn = true);

    try {
      final user = await _authController.signInWithGoogle();
      if (user == null) {
        // Sign-in cancelled by user
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const TransitHomeView()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleSigningIn = false);
      }
    }
  }

  /// Builds the user interface for the login page.
  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
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
                const Text(
                  'Your campus.\nOne easy ride.',
                  style: TextStyle(
                    color: Color(0xFF17201E),
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Free EV carts and city shuttles, together.',
                  style: TextStyle(color: Color(0xFF7B8582), fontSize: 14),
                ),
                const SizedBox(height: 32),
                Container(
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
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            tooltip: _hidePassword
                                ? 'Show password'
                                : 'Hide password',
                          ),
                          onSubmitted: (_) => _signIn(
                            _emailController.text.trim(),
                            _passwordController.text,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: (_isSigningIn || _isGoogleSigningIn)
                                ? null
                                : () {
                                    _signIn(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF009B6A),
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
                        ),
                        const SizedBox(height: 18),
                        const Row(
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
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: (_isSigningIn || _isGoogleLoading)
                                ? null
                                : _signInWithGoogle,
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
                                      color: Color(0xFF009B6A),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
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
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'IIT Ropar Mobility · Student · Driver · Admin',
                    style: TextStyle(color: Color(0xFF9BA3A0), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleMark extends StatelessWidget {
  const _VehicleMark();

  /// Builds the graphical vehicle mark container.
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

/// Shared styled field used by the login and account-creation screens.
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

  /// Builds the styled text input field widget.
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
