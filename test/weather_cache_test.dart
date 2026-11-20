import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agosalert/services/weather.dart';

// A saved real Open-Meteo response for Mabalacat City.
final _json = File('test/fixtures/weather.json').readAsStringSync();

void main() {
  test('weather is downloaded once and shared', () async {
    var requests = 0;
    var fail = true; // the first request fails
    final client = MockClient((req) async {
      // Count Open-Meteo's main request only: a failure also asks the two
      // backups, and the 5-model rain chance is a second request.
      if (req.url.host == 'api.open-meteo.com' &&
          !req.url.queryParameters.containsKey('models')) {
        requests++;
      }
      if (fail) return http.Response('oops', 500);
      return http.Response(
        _json,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await http.runWithClient(() async {
      // 1. A failed download isn't kept: the next load() tries again.
      await expectLater(MabalacatWeather.load(), throwsException);
      fail = false;
      final first = await MabalacatWeather.load();
      expect(requests, 2);

      // 2. A recent download is reused (this is what the login-screen
      //    prefetch relies on).
      final again = await MabalacatWeather.load();
      expect(identical(first, again), isTrue);
      expect(requests, 2);

      // 3. Pull-to-refresh downloads a fresh copy.
      await MabalacatWeather.load(refresh: true);
      expect(requests, 3);
    }, () => client);
  });

  test('rain chance = the models\' average, under the hour it covers', () {
    final avg = averageChances({
      'hourly': {
        'time': ['2026-11-19T17:00', '2026-11-19T18:00'],
        'precipitation_probability_ecmwf_ifs025': [98, 94],
        'precipitation_probability_gfs_seamless': [100, null],
        'precipitation_probability_ukmo_seamless': [0, 0],
      },
    });
    expect(avg[DateTime(2026, 11, 19, 16)], 66); // (98 + 100 + 0) / 3
    expect(avg[DateTime(2026, 11, 19, 17)], 47); // null skipped
  });

  test('5-day icon shows rain only at a 60%+ chance', () {
    final t = DateTime(2026, 11, 20);
    DailyForecast day(int? chance, int code) => DailyForecast(t, 31, 25, chance, 0, code, t, t);
    expect(day(58, 95).iconCode, 3); // storm code, low chance = cloudy
    expect(day(60, 95).iconCode, 95);
    expect(day(null, 61).iconCode, 61); // source gives no chance
    expect(day(10, 2).iconCode, 2); // not a rain code: unchanged
  });
}
