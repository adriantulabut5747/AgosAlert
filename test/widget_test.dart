import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agosalert/main.dart';
import 'package:agosalert/screens/evacuation_centers_screen.dart';
import 'package:agosalert/screens/home_shell.dart';
import 'package:agosalert/screens/info_screens.dart';
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
