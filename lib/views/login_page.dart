import 'package:flutter/material.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';
import 'package:sarthi_app/services/auth_service.dart';
import 'package:sarthi_app/views/sign_up_page.dart';
import 'package:sarthi_app/views/transit/transit_home_view.dart';

/// Email-and-password sign-in screen.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController(MockAuthService());
  bool _hidePassword = true;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSigningIn = true);
    await _authController.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSigningIn = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const TransitHomeView()),
    );
  }

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
                          onSubmitted: (_) => _signIn(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            onPressed: _isSigningIn ? null : _signIn,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SignUpPage(),
                      ),
                    ),
                    child: const Text(
                      'New to Sarthi? Sign Up',
                      style: TextStyle(
                        color: Color(0xFF167150),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Student · Driver · Admin',
                  style: TextStyle(color: Color(0xFF9BA3A0), fontSize: 12),
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

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF009B6A),
          borderRadius: BorderRadius.circular(23),
        ),
        child: const Icon(
          Icons.directions_bus_rounded,
          color: Colors.white,
          size: 37,
        ),
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