import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'screens/account.dart' show showChangePassword;
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/alerts.dart';
import 'services/auth.dart';
import 'services/centers.dart';
import 'services/rescue.dart';
import 'services/reports.dart';
import 'services/session.dart';
import 'theme.dart';

// The app starts here. runApp() puts AgosAlertApp on the screen.
Future<void> main() async {
  // Needed before anything (like Supabase) touches the browser's storage
  // ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // The theme picked on the landing page (services/session.dart).
  applyLaunchOptions();
  // Connect to Supabase and pick up a login saved in this browser. The
  // HTML loading screen stays up meanwhile (services/auth.dart).
  await initAuth();
  startAlerts(); // the bell's alerts + live updates (not awaited)
  loadMyRescue(); // this device's last rescue request, if any (not awaited)
  startCenters(); // evacuation centers + live updates (not awaited)
  startReports(); // the flood reports + live updates (not awaited: the app opens meanwhile)
  _addLicenses();
  runApp(const AgosAlertApp());
}

// About > Open-source licences lists the Dart packages by itself; these
// are the files we ship that it can't see (fonts, the map and 3D code).
// Read only when that page opens.
void _addLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (packages, file) in [
      (['Inter (font)'], 'assets/fonts/Inter-LICENSE.txt'),
      (['MapLibre GL JS'], 'web/map/LICENSE.txt'),
      (['three.js'], 'web/tugak/three/LICENSE.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks(
        packages,
        await rootBundle.loadString(file),
      );
    }
  });
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
        scrollBehavior: const _AppleScroll(),
        // Snack bars: a 400 px pill centered on wide screens instead of a
        // window-wide bar. The theme can't know the screen width, so it's here.
        builder: (context, child) {
          final theme = Theme.of(context);
          final w = MediaQuery.sizeOf(context).width;
          return Theme(
            data: theme.copyWith(
              snackBarTheme: theme.snackBarTheme.copyWith(
                width: w > 432 ? 400 : null,
              ),
            ),
            child: child!,
          );
        },
        // Logged in (or ?as=guest from the landing page): straight into
        // the app, usually on Weather. Otherwise the login screen.
        // From a password reset email: logged in, so open the app and ask
        // for the new password at once; a dead link lands on the login
        // screen with Tugak saying so.
        home: resetLinkWorked == true && !isGuest
            ? const _AfterReset()
            : !isGuest || openAsGuest
            ? HomeShell(initialTab: launchTab)
            : LoginScreen(
                message: resetLinkWorked == false
                    ? 'That reset link was already used or is over an hour old. Tap "Forgot password?" for a fresh one.'
                    : null,
              ),
      ),
    );
  }
}

/// The app, with "Set a new password" opened on top once it's shown.
class _AfterReset extends StatefulWidget {
  const _AfterReset();

  @override
  State<_AfterReset> createState() => _AfterResetState();
}

class _AfterResetState extends State<_AfterReset> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showChangePassword(context, afterReset: true),
    );
  }

  @override
  Widget build(BuildContext context) => HomeShell(initialTab: launchTab);
}

/// iOS scrolling everywhere: lists rubber-band past their ends and spring
/// back, instead of Android's glow / stretch. (Sheets switch back to the
/// clamping kind: pulling one down to close reads its overscroll.)
class _AppleScroll extends MaterialScrollBehavior {
  const _AppleScroll();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: RangeMaintainingScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
