import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/demo_data.dart';
import '../theme.dart';

/// ============================================================
/// SESSION — who is using the app, handed over by the landing page
/// ============================================================
///
/// Logging in happens on the landing page (a plain HTML page, see
/// `landing/`), not in Flutter. Its login popup opens the app with the
/// answers in the web address:
///
///   .../AgosAlert/app/?as=user&theme=dark
///   .../AgosAlert/app/?as=guest&theme=light&tab=map
///
///   as     user | guest   logged in, or just looking around
///   theme  light | dark   so the app matches the landing page
///   tab    home | map | alerts | assistance | more   (optional)
///
/// It's a demo, so this is not real security: anyone can type ?as=user.
/// A real backend would hand over a login token here instead.

/// The web address's `?...` part. Uri.base is the page's address on the
/// web; in tests and on phones it's a file path with no query, so every
/// value below falls back to its default there.
Map<String, String> get _query => Uri.base.queryParameters;

/// True when the landing page sent someone here (there's an `as=`).
bool get cameFromLanding => _query.containsKey('as');

/// Reads the web address once, before the app starts (see main.dart).
void applyLaunchOptions() {
  isGuest = _query['as'] == 'guest';
  switch (_query['theme']) {
    case 'light':
      themeNotifier.value = ThemeMode.light;
    case 'dark':
      themeNotifier.value = ThemeMode.dark;
  }
}

/// Which tab to open first: 0 Home, 1 Map, 2 Alerts, 3 Assistance, 4 More.
int get launchTab {
  const tabs = ['home', 'map', 'alerts', 'assistance', 'more'];
  final i = tabs.indexOf(_query['tab'] ?? '');
  return i < 0 ? 0 : i;
}

/// The published website with no `as=` in the address means someone
/// opened /app/ directly (a bookmark, an old link): send them to the
/// landing page to log in first. Only on the published site: while
/// developing (`flutter run`) there is no landing page to go to, so the
/// app just opens as a logged-in user.
bool get shouldSendToLanding => kIsWeb && kReleaseMode && !cameFromLanding;

/// Leaves the app for the landing page. [openLogin] opens its login
/// popup straight away (the page checks for `#login`).
///
/// The app lives in /AgosAlert/app/, the landing page one folder up, so
/// `resolve('../')` turns .../AgosAlert/app/?as=user into .../AgosAlert/.
/// `_self` = in this same tab, instead of opening a new one.
Future<void> goToLanding({bool openLogin = false}) async {
  final dark = themeNotifier.value == ThemeMode.dark;
  final landing = Uri.base
      .resolve('../')
      .replace(
        queryParameters: {'theme': dark ? 'dark' : 'light'},
        fragment: openLogin ? 'login' : null,
      );
  await launchUrl(landing, webOnlyWindowName: '_self');
}
