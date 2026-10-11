import 'package:flutter/material.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authController = AuthController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);
    final user = await _authController.sendSignInCode(_emailController.text);
    if (!mounted) return;
    setState(() => _isSending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sign-in code sent to ${user.email}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(26, 72, 26, 26 + keyboardInset),
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
                _SignInCard(
                  formKey: _formKey,
                  emailController: _emailController,
                  emailValidator: _authController.validateCollegeEmail,
                  isSending: _isSending,
                  onSubmit: _sendCode,
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
        child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 37),
      );
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.formKey,
    required this.emailController,
    required this.emailValidator,
    required this.isSending,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final String? Function(String?) emailValidator;
  final bool isSending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E6E3)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign in with college email',
                style: TextStyle(color: Color(0xFF202724), fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Use an @iitrpr.ac.in address. Your assigned role\nopens automatically.',
                style: TextStyle(color: Color(0xFF838B88), fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                validator: emailValidator,
                decoration: InputDecoration(
                  hintText: 'College email',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F3),
                  contentPadding: const EdgeInsets.symmetric(vertical: 17),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isSending ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF009B6A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF7ACDB4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send sign-in code', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
}
