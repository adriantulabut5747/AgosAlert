import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import 'login_screen.dart';
// "deferred as" = compiled into a separate file that's only downloaded the
// first time it's needed. The map package is big, so the Map tab and the
// Report incident screen (which has a map preview and photo picker) stay
// out of the first download. Always open them through this file.
import 'map_tab.dart' deferred as map_tab;
import 'report_incident_screen.dart' deferred as report;

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
