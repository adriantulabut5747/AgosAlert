import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/session.dart';
import 'theme.dart';

// The app starts here. runApp() puts AgosAlertApp on the screen.
void main() {
  // Opened from the landing page's login popup? Read who logged in and
  // which theme they picked from the web address (services/session.dart).
  applyLaunchOptions();
  // Opened /app/ directly on the published site: log in on the landing
  // page first. runApp is skipped, so the app never flashes on screen.
  if (shouldSendToLanding) {
    goToLanding(openLogin: true);
    return;
  }
  runApp(const AgosAlertApp());
}

class AgosAlertApp extends StatelessWidget {
  const AgosAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    // themeNotifier (theme.dart) holds the current mode: light or dark.
    // ValueListenableBuilder rebuilds the MaterialApp whenever it changes,
    // which is how the dark/light button in the top bar switches the
    // whole app at once. MaterialApp gets both themes and `themeMode`
    // picks which one to use; it animates the colors over 400 ms.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: 'AgosAlert',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: mode,
        themeAnimationDuration: const Duration(milliseconds: 400),
        // No login screen: the landing page already asked (see
        // screens/account.dart). launchTab is usually Home.
        home: HomeShell(initialTab: launchTab),
      ),
    );
  }
}
