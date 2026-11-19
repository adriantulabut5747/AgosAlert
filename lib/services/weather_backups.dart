import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'weather.dart';

/// ============================================================
/// BACKUP WEATHER, for when Open-Meteo is down (Nov 18 2026:
/// api.open-meteo.com stopped answering). MabalacatWeather.fetch tries
/// Open-Meteo, then MET Norway, then wttr.in. Both backups are free,
/// keyless and allow browser requests, but send less: whatever they
/// lack stays null / empty and the screens hide it (real data only).
/// ============================================================

const _lat = 15.2236, _lng = 120.5714; // Mabalacat City

/// GET [url] and decode its JSON. Anything but a quick 200 throws, so
/// [MabalacatWeather.fetch] moves on to the next source.
Future<Map<String, dynamic>> getWeatherJson(
  Uri url, {
  Map<String, String>? headers,
}) async {
  final res = await http
      .get(url, headers: headers)
      .timeout(const Duration(seconds: 6));
  if (res.statusCode != 200) {
    throw Exception('${url.host} returned ${res.statusCode}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Manila wall-clock time (UTC+8, no daylight saving) as a plain
/// DateTime, the same kind Open-Meteo's times parse into.
DateTime manilaTime(DateTime t) {
  final m = t.toUtc().add(const Duration(hours: 8));
  return DateTime(m.year, m.month, m.day, m.hour, m.minute, m.second);
}

/// Sunrise and sunset in Mabalacat on [day] (Manila time), from NOAA's
/// solar equations (within a minute or two). MET Norway doesn't send them.
(DateTime, DateTime) sunTimes(DateTime day) {
  const rad = math.pi / 180;
  final n = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(day.year)).inDays;
  final g = 2 * math.pi / 365 * n; // how far through the year, as an angle
  final eqTime =
      229.18 *
      (0.000075 +
          0.001868 * math.cos(g) -
          0.032077 * math.sin(g) -
          0.014615 * math.cos(2 * g) -
          0.040849 * math.sin(2 * g));
  final decl =
      0.006918 -
      0.399912 * math.cos(g) +
      0.070257 * math.sin(g) -
      0.006758 * math.cos(2 * g) +
      0.000907 * math.sin(2 * g) -
      0.002697 * math.cos(3 * g) +
      0.00148 * math.sin(3 * g);
  final ha =
      math.acos(
        math.cos(90.833 * rad) / (math.cos(_lat * rad) * math.cos(decl)) -
            math.tan(_lat * rad) * math.tan(decl),
      ) /
      rad;
  // Minutes after UTC midnight -> Manila time (+480 min).
  DateTime at(double utcMin) => DateTime(
    day.year,
    day.month,
    day.day,
    0,
    0,
    ((utcMin + 480) * 60).round(),
  );
  return (
    at(720 - 4 * (_lng + ha) - eqTime),
    at(720 - 4 * (_lng - ha) - eqTime),
  );
}

bool _isDay(DateTime t) {
  final (rise, set) = sunTimes(t);
  return !t.isBefore(rise) && t.isBefore(set);
}

/// MET Norway (api.met.no, the Norwegian weather service): hourly for
/// ~2.5 days, then every 6 hours. No rain chance, gusts, visibility or
/// past rain. Its UV is the clear-sky value (the most it can be).
Future<MabalacatWeather> fetchMetNorway() async => parseMetNorway(
  await getWeatherJson(
    Uri.https('api.met.no', '/weatherapi/locationforecast/2.0/complete', {
      'lat': '$_lat',
      'lon': '$_lng',
    }),
    // Their terms ask apps to name themselves. Browsers send their own
    // User-Agent and don't let a page change it.
    headers: kIsWeb
        ? null
        : {'User-Agent': 'AgosAlert github.com/adriantulabut5747/AgosAlert'},
  ),
  manilaTime(DateTime.now()),
);

MabalacatWeather parseMetNorway(Map<String, dynamic> json, DateTime now) {
  final thisHour = DateTime(now.year, now.month, now.day, now.hour);
  final steps = [
    for (final s in json['properties']['timeseries'] as List)
      (
        manilaTime(DateTime.parse(s['time'] as String)),
        s['data'] as Map<String, dynamic>,
      ),
  ].where((s) => !s.$1.isBefore(thisHour)).toList();
  double v(Map m, String k) => (m[k] as num).toDouble();

  final hourly = <HourlyForecast>[];
  final days = <DateTime, _Day>{};
  for (var i = 0; i < steps.length; i++) {
    final (t, d) = steps[i];
    final x = d['instant']['details'] as Map<String, dynamic>;
    final hour = d['next_1_hours'] as Map<String, dynamic>?;
    if (hour != null && hourly.length < 24) {
      hourly.add(
        HourlyForecast(
          t,
          v(x, 'air_temperature'),
          null,
          v(hour['details'], 'precipitation_amount'),
          _metCode(hour),
          _isDay(t),
          v(x, 'relative_humidity').round(),
          v(x, 'wind_speed') * 3.6, // m/s -> km/h
          v(x, 'apparent_air_temperature'),
          v(x, 'wind_from_direction').round(),
          v(x, 'air_pressure_at_sea_level'),
          v(x, 'cloud_area_fraction').round(),
          v(x, 'ultraviolet_index_clear_sky'),
          null,
        ),
      );
    }
    // Each step's rain block runs up to the next step: 1 h while the data
    // is hourly, then 6 h.
    // shortcut: a 6 h block counts for the day it starts in, though the
    // 8 PM one ends at 2 AM; fine for a backup's daily totals.
    final gap = i + 1 < steps.length
        ? steps[i + 1].$1.difference(t).inHours
        : 6;
    final block =
        (gap <= 1 ? hour : d['next_6_hours']) as Map<String, dynamic>?;
    final day = days.putIfAbsent(DateTime(t.year, t.month, t.day), _Day.new)
      ..temp(v(x, 'air_temperature'));
    if (block == null) continue;
    final b = block['details'] as Map<String, dynamic>;
    day.rain += v(b, 'precipitation_amount');
    if (b['air_temperature_max'] != null) day.temp(v(b, 'air_temperature_max'));
    if (b['air_temperature_min'] != null) day.temp(v(b, 'air_temperature_min'));
    day.code = math.max(day.code, _metCode(block));
  }
  if (hourly.length < 24) {
    throw const FormatException('MET Norway: too few hours');
  }

  final h = hourly.first;
  return MabalacatWeather(
    temperature: h.temperature,
    feelsLike: h.feelsLike,
    humidity: h.humidity,
    windSpeed: h.windSpeed,
    weatherCode: h.weatherCode,
    isDay: _isDay(now),
    windDir: h.windDir,
    gusts: null,
    pressure: h.pressure,
    cloud: h.cloud,
    uv: h.uv,
    visibility: null,
    time: now,
    hourly: hourly,
    pastRain: const [],
    // shortcut: today only covers the hours left (MET has no past), so
    // today's high, low and rain can read lower than Open-Meteo's.
    daily: [for (final e in days.entries.take(5)) e.value.at(e.key)],
    nextTwoHours: const [],
    source: 'MET Norway',
  );
}

class _Day {
  double max = -double.infinity, min = double.infinity, rain = 0;
  int code = 0;
  void temp(double t) {
    max = math.max(max, t);
    min = math.min(min, t);
  }

  DailyForecast at(DateTime date) {
    final (rise, set) = sunTimes(date);
    return DailyForecast(date, max, min, null, rain, code, rise, set);
  }
}

/// MET Norway's symbol ("rainshowers_day") -> the WMO code the app uses.
int _metCode(Map block) {
  final s = (block['summary']['symbol_code'] as String).split('_').first;
  if (s.contains('thunder')) return 95;
  return switch (s) {
    'clearsky' => 0,
    'fair' => 1,
    'partlycloudy' => 2,
    'cloudy' => 3,
    'fog' => 45,
    'lightrain' => 61,
    'rain' => 63,
    'heavyrain' => 65,
    'lightrainshowers' => 80,
    'rainshowers' => 81,
    'heavyrainshowers' => 82,
    _ => 71, // the rest are sleet and snow
  };
}

/// wttr.in (keyless, forecasts from WorldWeatherOnline): 3 days in 3-hour
/// blocks, no past or 15-minute rain. Often overloaded: the last resort.
Future<MabalacatWeather> fetchWttr() async => parseWttr(
  await getWeatherJson(Uri.https('wttr.in', '/$_lat,$_lng', {'format': 'j1'})),
  manilaTime(DateTime.now()),
);

MabalacatWeather parseWttr(Map<String, dynamic> json, DateTime now) {
  // wttr.in sends every number as a string.
  double v(Map m, String k) => double.parse(m[k] as String);
  int n(Map m, String k) => int.parse(m[k] as String);
  final thisHour = DateTime(now.year, now.month, now.day, now.hour);

  final hourly = <HourlyForecast>[];
  final daily = <DailyForecast>[];
  for (final d in json['weather'] as List) {
    final date = DateTime.parse(d['date'] as String);
    final sun = d['astronomy'][0] as Map;
    final rise = _clock(date, sun['sunrise'] as String);
    final set = _clock(date, sun['sunset'] as String);
    var rain = 0.0, code = 0, chance = 0;
    for (final b in d['hourly'] as List) {
      final bCode = _wwoCode(n(b, 'weatherCode'));
      rain += v(b, 'precipMM');
      code = math.max(code, bCode);
      chance = math.max(chance, n(b, 'chanceofrain'));
      // shortcut: each hour gets its 3-hour block's values and a third of
      // its rain; fine for a last-resort backup.
      for (var k = 0; k < 3; k++) {
        final t = DateTime(
          date.year,
          date.month,
          date.day,
          n(b, 'time') ~/ 100 + k,
        );
        if (t.isBefore(thisHour) || hourly.length == 24) continue;
        hourly.add(
          HourlyForecast(
            t,
            v(b, 'tempC'),
            n(b, 'chanceofrain'),
            v(b, 'precipMM') / 3,
            bCode,
            !t.isBefore(rise) && t.isBefore(set),
            n(b, 'humidity'),
            v(b, 'windspeedKmph'),
            v(b, 'FeelsLikeC'),
            n(b, 'winddirDegree'),
            v(b, 'pressure'),
            n(b, 'cloudcover'),
            v(b, 'uvIndex'),
            v(b, 'visibility') * 1000, // km -> m
          ),
        );
      }
    }
    daily.add(
      DailyForecast(
        date,
        v(d, 'maxtempC'),
        v(d, 'mintempC'),
        chance,
        rain,
        code,
        rise,
        set,
      ),
    );
  }
  if (hourly.length < 24) throw const FormatException('wttr.in: too few hours');

  final c = (json['current_condition'] as List).first as Map<String, dynamic>;
  final today = daily.first;
  return MabalacatWeather(
    temperature: v(c, 'temp_C'),
    feelsLike: v(c, 'FeelsLikeC'),
    humidity: n(c, 'humidity'),
    windSpeed: v(c, 'windspeedKmph'),
    weatherCode: _wwoCode(n(c, 'weatherCode')),
    isDay: !now.isBefore(today.sunrise) && now.isBefore(today.sunset),
    windDir: n(c, 'winddirDegree'),
    gusts: null,
    pressure: v(c, 'pressure'),
    cloud: n(c, 'cloudcover'),
    uv: v(c, 'uvIndex'),
    visibility: v(c, 'visibility') * 1000,
    time: now,
    hourly: hourly,
    pastRain: const [],
    daily: daily,
    nextTwoHours: const [],
    source: 'wttr.in',
  );
}

/// "06:01 AM" on [date].
DateTime _clock(DateTime date, String s) {
  final m = RegExp(r'(\d+):(\d+) ([AP]M)').firstMatch(s)!;
  final h = int.parse(m[1]!) % 12 + (m[3] == 'PM' ? 12 : 0);
  return DateTime(date.year, date.month, date.day, h, int.parse(m[2]!));
}

/// WorldWeatherOnline's code (wttr.in) -> the WMO code the app uses.
int _wwoCode(int c) => switch (c) {
  113 => 0,
  116 => 2,
  119 || 122 => 3,
  143 || 248 || 260 => 45,
  263 || 266 || 281 || 284 => 51,
  293 || 296 => 61,
  299 || 302 => 63,
  305 || 308 => 65,
  176 || 353 => 80, // 176 = "patchy rain nearby"
  356 => 81,
  359 => 82,
  200 || 386 || 389 || 392 || 395 => 95,
  _ => 71, // the rest are sleet, snow and ice
};
