import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import 'login_screen.dart';
// "deferred as" = compiled into a separate file that's only downloaded the
// first time it's needed. The map package is big, so the Map tab and the
// Report incident screen (which has a map preview and photo picker) stay
// out of the first download. Always open them through this file.
import 'alerts_tab.dart' deferred as alerts;
import 'assistance_tab.dart' deferred as assistance;
import 'info_screens.dart' deferred as info;
import 'map_tab.dart' deferred as map_tab;
import 'more_tab.dart' deferred as more;
import 'report_incident_screen.dart' deferred as report;
import 'settings_screen.dart' deferred as settings;

/// The Map tab, downloaded the first time the tab is opened.
///
/// `map_tab.loadLibrary` downloads the split-off file. Until it's done,
/// nothing inside `map_tab.` may be touched, which is why `builder` is a
/// function: DeferredView only calls it after loading finishes. (Also why
/// it's `map_tab.MapTab()` without `const`: Dart doesn't allow const for
/// deferred classes.)
Widget deferredMapTab() => DeferredView(
  load: map_tab.loadLibrary,
  builder: () => map_tab.MapTab(),
  placeholder: const MapSkeleton(),
);

/// Opens the Report incident screen (downloading it the first time).
/// Guests can only view, so they get the "log in" popup instead.
void openReportIncident(BuildContext context) {
  if (isGuest) {
    showLoginRequired(context, action: 'report');
    return;
  }
  Navigator.of(context).push(
    slideRoute(
      DeferredView(
        load: report.loadLibrary,
        builder: () => report.ReportIncidentScreen(),
        placeholder: const FormPageSkeleton(title: 'Report incident'),
      ),
    ),
  );
}

/// Downloads the Map tab and Report incident code in the background, so
/// they open instantly later. Errors are ignored: if it fails, they'll
/// simply download when first opened, as before.
///
/// Calling loadLibrary() again later is fine: once a library has been
/// downloaded, it returns immediately.
/// `.then((_) {}, onError: ...)` swallows the error so a failed download
/// isn't reported as a crash.
Future<void> preloadDeferredScreens() async {
  await Future.wait([
    map_tab.loadLibrary().then((_) {}, onError: (Object _) {}),
    report.loadLibrary().then((_) {}, onError: (Object _) {}),
  ]);
}

// ------------------------------------------------------------
// Every other page is split off the same way, so the first download
// only has what's needed to log in and see Home. Each page downloads
// the first time it's opened (a skeleton shows meanwhile), and after
// that it opens instantly.
// ------------------------------------------------------------

Widget deferredAlertsTab() => DeferredView(
  load: alerts.loadLibrary,
  builder: () => alerts.AlertsTab(),
  placeholder: const ListPageSkeleton(),
);

Widget deferredAssistanceTab() => DeferredView(
  load: assistance.loadLibrary,
  builder: () => assistance.AssistanceTab(),
  placeholder: const ListPageSkeleton(),
);

Widget deferredMoreTab() => DeferredView(
  load: more.loadLibrary,
  builder: () => more.MoreTab(),
  placeholder: const ListPageSkeleton(),
);

void openSettings(BuildContext context) => _openPage(
  context,
  load: settings.loadLibrary,
  builder: () => settings.SettingsScreen(),
  title: 'Settings',
);

void openHelp(BuildContext context) => _openPage(
  context,
  load: info.loadLibrary,
  builder: () => info.HelpScreen(),
  title: 'Help & FAQ',
);

void openAbout(BuildContext context) => _openPage(
  context,
  load: info.loadLibrary,
  builder: () => info.AboutScreen(),
  title: 'About',
);

// Opens a split-off page on top of the current one.
void _openPage(
  BuildContext context, {
  required Future<void> Function() load,
  required Widget Function() builder,
  required String title,
}) {
  Navigator.of(context).push(
    slideRoute(
      DeferredView(
        load: load,
        builder: builder,
        placeholder: FormPageSkeleton(title: title),
      ),
    ),
  );
}
