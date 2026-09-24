import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agosalert/main.dart';
import 'package:agosalert/screens/evacuation_centers_screen.dart';
import 'package:agosalert/screens/home_shell.dart';
import 'package:agosalert/screens/info_screens.dart';
import 'package:agosalert/screens/map_tab.dart';
import 'package:agosalert/screens/report_incident_screen.dart';
import 'package:agosalert/screens/settings_screen.dart';
import 'package:agosalert/theme.dart';

/// Shows [page] on a phone-sized screen (390 x 844, like an iPhone).
Future<void> pumpPhone(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildDarkTheme(), home: page));
  // pump() not pumpAndSettle(): several animations repeat forever,
  // so the app never "settles".
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('App starts on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AgosAlertApp());
    await tester.pump();

    expect(find.text('Login to your account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  // Each tab and screen should build on a phone without layout errors
  // (a "RenderFlex overflowed" error makes the test fail).
  testWidgets('All tabs render on a phone', (tester) async {
    await pumpPhone(tester, const HomeShell());
    for (final tab in ['Map', 'Alerts', 'Assistance', 'More', 'Home']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(seconds: 1));
    }
  });

  // Regression test: switching tabs must hide the previous tab
  // (it once stayed visible on top of the new one).
  testWidgets('Switching tabs hides the previous tab', (tester) async {
    await pumpPhone(tester, const HomeShell());
    await tester.tap(find.text('More').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Home').last);
    await tester.pump(); // rebuild: the fade starts here
    await tester.pump(const Duration(seconds: 1)); // let it finish

    // The tab's fade is the nearest AnimatedOpacity above the text; read
    // the value it is actually drawing (from its inner FadeTransition).
    double opacityOf(String text) {
      final tabFade = find
          .ancestor(of: find.text(text), matching: find.byType(AnimatedOpacity))
          .first;
      return tester
          .widget<FadeTransition>(
            find
                .descendant(of: tabFade, matching: find.byType(FadeTransition))
                .first,
          )
          .opacity
          .value;
    }

    expect(opacityOf('Log out'), 0); // More tab is hidden
    expect(opacityOf('Quick actions'), 1); // Home tab is visible
  });

  // The map must stay inside Mabalacat City, however far you drag it.
  testWidgets('Map cannot be dragged outside Mabalacat', (tester) async {
    await pumpPhone(tester, const Scaffold(body: MapTab()));
    for (final drag in [
      const Offset(0, 2000), // far north
      const Offset(0, -4000), // far south
      const Offset(3000, 0), // far west
      const Offset(-6000, 0), // far east
    ]) {
      await tester.drag(find.byType(FlutterMap), drag);
      await tester.pump(const Duration(seconds: 1));
      final view = MapCamera.of(tester.element(find.byType(TileLayer).first))
          .visibleBounds;
      const margin = 0.001; // rounding
      expect(view.north, lessThanOrEqualTo(kMabalacatBounds.north + margin));
      expect(view.south, greaterThanOrEqualTo(kMabalacatBounds.south - margin));
      expect(view.west, greaterThanOrEqualTo(kMabalacatBounds.west - margin));
      expect(view.east, lessThanOrEqualTo(kMabalacatBounds.east + margin));
    }
  });

  for (final (name, page) in [
    ('Evacuation centers', const EvacuationCentersScreen()),
    ('Report incident', const ReportIncidentScreen()),
    ('Settings', const SettingsScreen()),
    ('About', const AboutScreen()),
    ('Help', const HelpScreen()),
  ]) {
    testWidgets('$name screen renders on a phone', (tester) async {
      await pumpPhone(tester, page);
    });
  }
}
