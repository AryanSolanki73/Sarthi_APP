import 'package:flutter/material.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/views/login_page.dart';

// Root application widget.
// This file contains app-wide configuration, such as the theme and the
// first page to display. Individual screen UI belongs in the `views` folder.
class SarthiApp extends StatelessWidget {
  const SarthiApp({super.key});

  // Shared brand colour used to generate the Material theme.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sarthi',
        debugShowCheckedModeBanner: false,
        // ThemeData controls the default appearance used throughout the app.
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.emerald),
          // background color - White
          scaffoldBackgroundColor: AppColors.background,
          useMaterial3: true,
        ),
        // The login page is the first screen a user sees.
        home: const LoginPage(),
      );
}
