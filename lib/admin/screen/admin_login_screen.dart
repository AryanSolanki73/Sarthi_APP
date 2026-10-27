import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../views/widgets/google_logo_icon.dart';
import '../auth/admin_auth_service.dart';
import 'admin_dashboard_screen.dart';

const _green = Color(0xFF087F5B);
const _mint = Color(0xFFE7F6EF);
const _ink = Color(0xFF18231F);
const _muted = Color(0xFF7B8983);
const _line = Color(0xFFE7ECE9);
const _pageBackground = Color(0xFFF5F7F6);

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AdminAuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openDashboard() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AdminDashboardScreen(),
      ),
    );
  }

  // Email and password sign-in
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      _openDashboard();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful. Welcome to Admin Portal.'),
          backgroundColor: _green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = switch (e.code) {
          'admin-not-authorized' =>
            'Access denied. This account does not have administrator privileges.',
          'invalid-credential' =>
            'Invalid email or password.',
          'user-not-found' =>
            'No account exists with this email.',
          'wrong-password' =>
            'Incorrect password.',
          'invalid-email' =>
            'Please enter a valid email address.',
          'user-disabled' =>
            'This administrator account has been disabled.',
          'too-many-requests' =>
            'Too many failed attempts. Please try again later.',
          'network-request-failed' =>
            'Network error. Check your internet connection.',
          'operation-not-allowed' =>
            'Email/password sign-in is not enabled in Firebase.',
          _ =>
            e.message ?? 'Sign-in failed. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Google sign-in
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();

      if (!mounted) return;
      _openDashboard();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google login successful. Welcome to Admin Portal.'),
          backgroundColor: _green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = switch (e.code) {
          'admin-not-authorized' =>
            'Access denied. This Google account is not an authorized administrator.',
          'popup-closed-by-user' =>
            'Google sign-in was cancelled.',
          'popup-blocked' =>
            'Your browser blocked the sign-in popup. Allow popups and try again.',
          'account-exists-with-different-credential' =>
            'This email is already registered using another sign-in method.',
          'operation-not-allowed' =>
            'Google sign-in is not enabled in Firebase.',
          'network-request-failed' =>
            'Network error. Check your internet connection.',
          _ =>
            e.message ?? 'Google sign-in failed. Please try again.',
        };
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C203B2B),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sarthi Brand Header matching Dashboard Sidebar
                      Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: _green.withOpacity(0.24),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.alt_route,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'SARTHI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _mint,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TRANSIT CONTROL',
                            style: TextStyle(
                              color: _green,
                              fontSize: 9,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Admin Portal Sign In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Sign in to manage student accounts, fleet operations, and campus rides.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Email field
                      const Text(
                        'EMAIL ADDRESS',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: InputDecoration(
                          hintText: 'admin@iitrpr.ac.in',
                          hintStyle: TextStyle(
                            color: _muted.withOpacity(0.6),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: _muted,
                            size: 19,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFCFA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _green,
                              width: 1.8,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE03131),
                              width: 1.2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE03131),
                              width: 1.6,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Please enter your email';
                          }

                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password field
                      const Text(
                        'PASSWORD',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        autofillHints: const [
                          AutofillHints.password,
                        ],
                        onFieldSubmitted: (_) {
                          if (!_isLoading) {
                            _signInWithEmail();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(
                            color: _muted.withOpacity(0.6),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: _muted,
                            size: 19,
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _muted,
                              size: 19,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFCFA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _green,
                              width: 1.8,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE03131),
                              width: 1.2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE03131),
                              width: 1.6,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Error message banner
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: const Color(0xFFFFD8D8),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFE03131),
                                size: 17,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFC92A2A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email sign-in button
                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _signInWithEmail,
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _green.withOpacity(0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In to Dashboard',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Separator
                      Row(
                        children: [
                          const Expanded(child: Divider(color: _line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: _muted.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: _line)),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Google sign-in button
                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ink,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: _line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GoogleLogoIcon(size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Security / Operating Area badge matching Dashboard
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAF8),
                          border: Border.all(color: _line),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _mint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: _green,
                              ),
                            ),
                            const SizedBox(width: 9),
                            const Flexible(
                              child: Text(
                                'Restricted access • IIT Ropar Transit Admins',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
