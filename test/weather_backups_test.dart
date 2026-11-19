import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agosalert/services/weather.dart';
import 'package:agosalert/services/weather_backups.dart';

// Saved real responses for Mabalacat City, Nov 18 2026 ~9 PM Manila.
String _read(String name) => File('test/fixtures/$name').readAsStringSync();
final _now = DateTime(2026, 11, 18, 21, 10);

void main() {
  test('MET Norway fills the hours, hides what it lacks', () {
    final w = parseMetNorway(jsonDecode(_read('met_norway.json')), _now);
    expect(w.source, 'MET Norway');
    expect(w.hourly, hasLength(24));
    expect(w.hourly.first.time, DateTime(2026, 11, 18, 21));
    expect(w.hourly[1].time, DateTime(2026, 11, 18, 22));
    expect(w.hourly.first.rainChance, isNull);
    expect(w.visibility, isNull);
    expect(w.gusts, isNull);
    expect(w.pastRain, isEmpty);
    expect(w.isDay, isFalse); // 9 PM
    expect(w.daily.first.date, DateTime(2026, 11, 18));
    expect(w.daily, hasLength(5));
    for (final d in w.daily) {
      expect(d.max, greaterThanOrEqualTo(d.min));
      expect(d.min, inInclusiveRange(15, 40)); // real Mabalacat numbers
    }
  });

  test('wttr.in fills the hours from its 3-hour blocks', () {
    final w = parseWttr(jsonDecode(_read('wttr.json')), _now);
    expect(w.source, 'wttr.in');
    expect(w.hourly, hasLength(24));
    expect(w.hourly.first.time, DateTime(2026, 11, 18, 21));
    expect(w.hourly.last.time, DateTime(2026, 11, 19, 20));
    expect(w.hourly.first.rainChance, isNotNull);
    expect(w.visibility, 10000);
    expect(w.daily, hasLength(3));
    expect(w.daily.first.sunset, DateTime(2026, 11, 18, 17, 25));
  });

  test('computed sun times match the published ones', () {
    // wttr.in: 6:01 AM / 5:25 PM on Nov 18; Open-Meteo: 5:58 / 5:25 PM on Nov 13.
    void near(DateTime got, DateTime want) =>
        expect(got.difference(want).inMinutes.abs(), lessThanOrEqualTo(2));
    final (rise18, set18) = sunTimes(DateTime(2026, 11, 18));
    near(rise18, DateTime(2026, 11, 18, 6, 1));
    near(set18, DateTime(2026, 11, 18, 17, 25));
    final (rise13, set13) = sunTimes(DateTime(2026, 11, 13));
    near(rise13, DateTime(2026, 11, 13, 5, 58));
    near(set13, DateTime(2026, 11, 13, 17, 25));
  });

  test('falls back in order; fails only when all three do', () async {
    final asked = <String>[];
    final client = MockClient((req) async {
      // The 5-model rain chance request isn't a source of its own.
      if (!req.url.queryParameters.containsKey('models')) {
        asked.add(req.url.host);
      }
      return http.Response('down', 503);
    });
    await http.runWithClient(() async {
      await expectLater(MabalacatWeather.fetch(), throwsException);
    }, () => client);
    expect(asked, ['api.open-meteo.com', 'api.met.no', 'wttr.in']);
  });
}
