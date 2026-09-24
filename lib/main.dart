import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  runApp(const AgosAlertApp());
}

class AgosAlertApp extends StatelessWidget {
  const AgosAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: 'AgosAlert',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: mode,
        themeAnimationDuration: const Duration(milliseconds: 400),
        home: const LoginScreen(),
      ),
    );
  }
}
