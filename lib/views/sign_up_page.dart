import 'package:flutter/material.dart';
import 'package:sarthi_app/controllers/auth_controller.dart';
import 'package:sarthi_app/services/auth_service.dart';
import 'package:sarthi_app/views/transit/transit_home_view.dart';

/// Account-creation view. The controller owns validation; this view owns only
/// form state and presentation.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authController = AuthController(MockAuthService());
  bool _hidePassword = true;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isCreating = true);
    await _authController.createAccount(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isCreating = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const TransitHomeView()),
      (_) => false,
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF7F8B87)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF009B6A), width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Create your profile', style: TextStyle(fontSize: 26)),
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(50, 60, 50, 32 + keyboardInset),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Join Sarthi',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Create a student account with your @iitrpr.ac.in email.',
                    style: TextStyle(fontSize: 17, height: 1.4),
                  ),
                  const SizedBox(height: 58),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: _authController.validateName,
                    decoration: _decoration('Full name', Icons.person_outline_rounded),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _authController.validateCollegeEmail,
                    decoration: _decoration('College email', Icons.alternate_email_rounded),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    validator: _authController.validatePassword,
                    decoration: _decoration(
                      'Password',
                      Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'At least 6 characters',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5E6865)),
                    ),
                  ),
                  const SizedBox(height: 34),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _hidePassword,
                    validator: (value) => _authController.validatePasswordConfirmation(
                      value,
                      _passwordController.text,
                    ),
                    onFieldSubmitted: (_) => _createAccount(),
                    decoration: _decoration('Confirm password', Icons.lock_outline_rounded),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _isCreating ? null : _createAccount,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF207252),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Already have an account? Sign In',
                        style: TextStyle(
                          color: Color(0xFF207252),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}