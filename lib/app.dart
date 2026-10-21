import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/services/credential_storage.dart';
import 'package:sarthi_app/views/login_page.dart';
import 'package:sarthi_app/views/transit/transit_home_view.dart';

/// Root application widget.
class SarthiApp extends StatelessWidget {
  const SarthiApp({super.key, this.home});

  final Widget? home;

  /// Builds the root MaterialApp configuration for the application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sarthi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.emerald),
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        home: home ?? const _AuthGate(),
      );
}

/// Checks local storage for saved user credentials before choosing the first screen.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  /// Creates the mutable state for the authentication gate widget.
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<bool> _authCheckFuture;

  /// Initializes the widget state and starts the saved login verification.
  @override
  void initState() {
    super.initState();
    _authCheckFuture = _checkSavedLogin();
  }

  /// Reads saved user credentials from local storage and authenticates the user.
  Future<bool> _checkSavedLogin() async {
    try {
      // 1. If Firebase already has an active session (e.g. from Google Sign-In)
      if (FirebaseAuth.instance.currentUser != null) {
        return true;
      }

      // 2. Otherwise try restoring saved email/password credentials
      final saved = await CredentialStorage.loadCredentials();
      if (saved == null) {
        return false;
      }

      final email = saved['email']?.trim() ?? '';
      final password = saved['password'] ?? '';

      if (email.isNotEmpty && password.isNotEmpty) {
        // Authenticate with Firebase if no session is active
        try {
          if (FirebaseAuth.instance.currentUser == null) {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          }
          return FirebaseAuth.instance.currentUser != null;
        } catch (e) {
          debugPrint('Firebase auto-sign-in failed: $e');
          await CredentialStorage.clearCredentials();
          return false;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Builds the initial screen based on the authentication check result.
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: _authCheckFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.emerald,
                ),
              ),
            );
          }

          final isLoggedIn = snapshot.data ?? false;
          if (isLoggedIn) {
            return const TransitHomeView();
          }

          return const LoginPage();
        },
      );
}
