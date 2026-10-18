import 'package:flutter/material.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/views/splash_screen.dart';

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
        home: home ?? const SplashScreen(),
      );
}
