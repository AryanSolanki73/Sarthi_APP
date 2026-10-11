import 'package:flutter/material.dart';
import 'package:sarthi_app/views/auth/login_page.dart';

void main() => runApp(const SarthiApp());

class SarthiApp extends StatelessWidget {
  const SarthiApp({super.key});

  static const _brandGreen = Color(0xFF009B6A);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sarthi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _brandGreen),
          scaffoldBackgroundColor: const Color(0xFFF4FCF9),
          useMaterial3: true,
        ),
        home: const LoginPage(),
      );
}
