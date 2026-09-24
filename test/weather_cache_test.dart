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
    final client = MockClient((_) async {
      requests++;
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
}
