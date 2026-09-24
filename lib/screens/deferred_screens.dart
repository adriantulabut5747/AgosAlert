import 'package:flutter/material.dart';

import '../widgets/common.dart';
import '../widgets/skeleton.dart';
// "deferred as" = compiled into a separate file that's only downloaded the
// first time it's needed. The map package is big, so the Map tab and the
// Report incident screen (which has a map preview and photo picker) stay
// out of the first download. Always open them through this file.
import 'map_tab.dart' deferred as map_tab;
import 'report_incident_screen.dart' deferred as report;

/// The Map tab, downloaded the first time the tab is opened.
Widget deferredMapTab() => DeferredView(
  load: map_tab.loadLibrary,
  builder: () => map_tab.MapTab(),
  placeholder: const MapSkeleton(),
);

/// Opens the Report incident screen (downloading it the first time).
void openReportIncident(BuildContext context) {
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
