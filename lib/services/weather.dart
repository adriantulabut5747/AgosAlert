import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme.dart';

/// ============================================================
/// LIVE WEATHER for Mabalacat City from Open-Meteo
/// (https://open-meteo.com). Free, no API key, and it allows
/// browser requests, so it works on Flutter web.
/// ============================================================

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int rainChance; // %
  final int weatherCode;
  final bool isDay;
  const HourlyForecast(
    this.time,
    this.temperature,
    this.rainChance,
    this.weatherCode,
    this.isDay,
  );
}

class DailyForecast {
  final DateTime date;
  final double max;
  final double min;
  final int rainChance; // %
  final double rainSum; // mm
  final int weatherCode;
  const DailyForecast(
    this.date,
    this.max,
    this.min,
    this.rainChance,
    this.rainSum,
    this.weatherCode,
  );
}

class MabalacatWeather {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double precipitation; // mm in the last 15 minutes
  final double windSpeed; // km/h
  final int weatherCode; // WMO code, see weatherInfo()
  final bool isDay;
  final DateTime time; // local Manila time
  final List<HourlyForecast> hourly; // next 12 hours
  final List<DailyForecast> daily; // today + next days

  const MabalacatWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    required this.time,
    required this.hourly,
    required this.daily,
  });

  DailyForecast get today => daily.first;

  static final _url = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '15.2236', // Mabalacat City
    'longitude': '120.5714',
    'current':
        'temperature_2m,relative_humidity_2m,apparent_temperature,'
        'precipitation,weather_code,wind_speed_10m,is_day',
    'hourly': 'temperature_2m,precipitation_probability,weather_code,is_day',
    'daily':
        'weather_code,temperature_2m_max,temperature_2m_min,'
        'precipitation_probability_max,precipitation_sum',
    'forecast_days': '5',
    'timezone': 'Asia/Manila',
  });

  // The last request, shared by everyone who asks, so the weather can be
  // downloaded while the user is still on the login screen and Home shows
  // it instantly.
  static Future<MabalacatWeather>? _cached;
  static DateTime? _cachedAt;

  /// Returns the shared weather request, starting a new one if there is
  /// none yet, it's older than 10 minutes, it failed, or [refresh] is true.
  static Future<MabalacatWeather> load({bool refresh = false}) {
    final stale =
        _cachedAt == null ||
        DateTime.now().difference(_cachedAt!) > const Duration(minutes: 10);
    if (refresh || stale || _cached == null) {
      final request = fetch();
      _cached = request;
      _cachedAt = DateTime.now();
      // If it fails, forget it so the next load() tries again. (Listening
      // here also stops a failed background download from being reported
      // as an uncaught error.)
      request.then(
        (_) {},
        onError: (Object _) {
          if (identical(_cached, request)) {
            _cached = null;
            _cachedAt = null;
          }
        },
      );
    }
    return _cached!;
  }

  static Future<MabalacatWeather> fetch() async {
    final res = await http.get(_url).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Weather API returned ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final cur = json['current'] as Map<String, dynamic>;
    final h = json['hourly'] as Map<String, dynamic>;
    final d = json['daily'] as Map<String, dynamic>;
    final now = DateTime.parse(cur['time'] as String);

    num n(List list, int i) => (list[i] as num?) ?? 0;

    // Hourly data starts at midnight today; keep the next 12 hours.
    final hTimes = (h['time'] as List).cast<String>();
    final hourly = <HourlyForecast>[];
    for (var i = 0; i < hTimes.length && hourly.length < 12; i++) {
      final t = DateTime.parse(hTimes[i]);
      if (t.isBefore(DateTime(now.year, now.month, now.day, now.hour))) {
        continue;
      }
      hourly.add(
        HourlyForecast(
          t,
          n(h['temperature_2m'], i).toDouble(),
          n(h['precipitation_probability'], i).toInt(),
          n(h['weather_code'], i).toInt(),
          n(h['is_day'], i) == 1,
        ),
      );
    }

    final dTimes = (d['time'] as List).cast<String>();
    final daily = [
      for (var i = 0; i < dTimes.length; i++)
        DailyForecast(
          DateTime.parse(dTimes[i]),
          n(d['temperature_2m_max'], i).toDouble(),
          n(d['temperature_2m_min'], i).toDouble(),
          n(d['precipitation_probability_max'], i).toInt(),
          n(d['precipitation_sum'], i).toDouble(),
          n(d['weather_code'], i).toInt(),
        ),
    ];

    return MabalacatWeather(
      temperature: (cur['temperature_2m'] as num).toDouble(),
      feelsLike: (cur['apparent_temperature'] as num).toDouble(),
      humidity: (cur['relative_humidity_2m'] as num).toInt(),
      precipitation: (cur['precipitation'] as num).toDouble(),
      windSpeed: (cur['wind_speed_10m'] as num).toDouble(),
      weatherCode: (cur['weather_code'] as num).toInt(),
      isDay: cur['is_day'] == 1,
      time: now,
      hourly: hourly,
      daily: daily,
    );
  }

  /// A rough flood outlook from today's rain forecast.
  /// Not an official warning — PAGASA / CDRRMO are the authority.
  FloodOutlook get floodOutlook {
    final sum = today.rainSum;
    final chance = today.rainChance;
    final stormy = weatherCode >= 95 || weatherCode == 65 || weatherCode == 82;
    if (sum >= 30 || (stormy && chance >= 60)) {
      return const FloodOutlook(
        RiskLevel.high,
        'High flood risk',
        'Heavy rain expected. Flooding is likely in low-lying areas. Prepare to evacuate if told to.',
      );
    }
    if (sum >= 10 || chance >= 70) {
      return const FloodOutlook(
        RiskLevel.moderate,
        'Moderate flood risk',
        'Significant rain expected. Stay alert near rivers and low-lying streets.',
      );
    }
    return const FloodOutlook(
      RiskLevel.normal,
      'Low flood risk',
      'Little rain expected today. No flooding expected.',
    );
  }
}

class FloodOutlook {
  final RiskLevel level;
  final String title;
  final String message;
  const FloodOutlook(this.level, this.title, this.message);
}

/// Turns a WMO weather code into a label and icon.
(String, IconData) weatherInfo(int code, {bool isDay = true}) {
  if (code == 0) {
    return isDay
        ? ('Clear sky', Icons.wb_sunny_rounded)
        : ('Clear night', Icons.nightlight_round);
  }
  if (code <= 2) {
    return isDay
        ? ('Partly cloudy', Icons.wb_cloudy_rounded)
        : ('Partly cloudy', Icons.nights_stay_rounded);
  }
  if (code == 3) return ('Overcast', Icons.cloud_rounded);
  if (code <= 48) return ('Foggy', Icons.foggy);
  if (code <= 57) return ('Drizzle', Icons.grain_rounded);
  if (code <= 67) return ('Rain', Icons.water_drop_rounded);
  if (code <= 77) return ('Snow', Icons.ac_unit_rounded);
  if (code <= 82) return ('Rain showers', Icons.umbrella_rounded);
  return ('Thunderstorm', Icons.thunderstorm_rounded);
}

/// Card background colors that match the weather.
List<Color> weatherGradient(int code, bool isDay) {
  if (!isDay) return const [Color(0xFF1B2556), Color(0xFF0B1130)];
  if (code == 0 || code <= 2) {
    return const [Color(0xFF2D7DD2), Color(0xFF29C5F6)];
  }
  if (code >= 95) return const [Color(0xFF3B3F6B), Color(0xFF1E2140)];
  if (code >= 51) return const [Color(0xFF1E4E79), Color(0xFF2D6FA8)];
  return const [Color(0xFF3A5A80), Color(0xFF5B84B1)];
}

String formatHour(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h ${t.hour < 12 ? 'AM' : 'PM'}';
}

String formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatWeekday(DateTime d) => _weekdays[d.weekday - 1];
String formatDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
