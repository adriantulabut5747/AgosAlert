import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../services/weather.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'evacuation_centers_screen.dart';
import 'home_shell.dart';
import 'report_incident_screen.dart';

/// ============================================================
/// HOME TAB — live Mabalacat weather, flood outlook, forecast,
/// quick actions, river levels, evacuation centers, safety tips
/// ============================================================
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<MabalacatWeather> _weather = MabalacatWeather.fetch();

  Future<void> _refresh() async {
    final next = MabalacatWeather.fetch();
    setState(() => _weather = next);
    await next.catchError((_) => _weather);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      color: c.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          FadeSlideIn(child: _greeting(c)),
          const SizedBox(height: 18),
          FutureBuilder<MabalacatWeather>(
            future: _weather,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const _WeatherSkeleton();
              }
              if (snap.hasError) return _weatherError(c);
              return _WeatherSection(weather: snap.data!);
            },
          ),
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 250),
            child: _quickActions(context, c),
          ),
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 330),
            child: const _RiverLevels(),
          ),
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 400),
            child: _evacuationCenters(context, c),
          ),
          const SizedBox(height: 28),
          FadeSlideIn(
            delay: const Duration(milliseconds: 460),
            child: const _SafetyTips(),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Weather by Open-Meteo · Sections marked SAMPLE use demo data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _greeting(AppColors c) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatDate(now).toUpperCase(),
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$greeting!',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 15, color: c.accent),
              const SizedBox(width: 4),
              Text(
                'Mabalacat City, Pampanga',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weatherError(AppColors c) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconBadge(Icons.cloud_off_rounded, c.textSecondary, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather unavailable',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Check your internet connection.',
                  style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          FilledButton.tonal(onPressed: _refresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, AppColors c) {
    final actions = [
      (
        Icons.map_rounded,
        'Flood\nMap',
        kSkyBlue,
        () => HomeShell.of(context)?.switchTab(1),
      ),
      (
        Icons.campaign_rounded,
        'Report\nIncident',
        const Color(0xFFF97316),
        () =>
            Navigator.of(context)
                .push(slideRoute(const ReportIncidentScreen())),
      ),
      (
        Icons.night_shelter_rounded,
        'Evacuation\nCenters',
        kSafe,
        () =>
            Navigator.of(context)
                .push(slideRoute(const EvacuationCentersScreen())),
      ),
      (
        Icons.phone_in_talk_rounded,
        'Emergency\nHotlines',
        kDanger,
        () => HomeShell.of(context)?.switchTab(3),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Quick actions'),
        Row(
          children: [
            for (final (icon, label, color, onTap) in actions)
              Expanded(
                child: PressableScale(
                  onTap: onTap,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              Color.lerp(color, Colors.white, 0.3)!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 27),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 11.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _evacuationCenters(BuildContext context, AppColors c) {
    final centers = [...kEvacCenters]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Evacuation centers',
          badge: const SampleBadge(),
          actionLabel: 'See all',
          onAction: () =>
              Navigator.of(context)
                  .push(slideRoute(const EvacuationCentersScreen())),
        ),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: centers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(
              width: 220,
              child: EvacCenterCard(center: centers[i], compact: true),
            ),
          ),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// Weather: hero card, flood outlook, hourly strip, next days
/// ------------------------------------------------------------
class _WeatherSection extends StatelessWidget {
  final MabalacatWeather weather;
  const _WeatherSection({required this.weather});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final w = weather;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(child: _hero(w)),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 90),
          child: _outlook(c, w.floodOutlook),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: _hourly(c, w),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          child: _daily(c, w),
        ),
      ],
    );
  }

  Widget _hero(MabalacatWeather w) {
    final (label, icon) = weatherInfo(w.weatherCode, isDay: w.isDay);
    final colors = weatherGradient(w.weatherCode, w.isDay);
    const white70 = Color(0xB3FFFFFF);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Big faded icon in the corner for depth
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                icon,
                size: 190,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedWaves(
                height: 70,
                colors: [
                  Color(0x14FFFFFF),
                  Color(0x1AFFFFFF),
                  Color(0x22FFFFFF),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const LiveDot(color: Color(0xFF7CFFB2)),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE WEATHER · MABALACAT CITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatTime(w.time),
                        style: const TextStyle(color: white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: w.temperature),
                              duration: const Duration(milliseconds: 1100),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => Text(
                                '${v.round()}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 72,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'H ${w.today.max.round()}°  ·  L ${w.today.min.round()}°  ·  Feels ${w.feelsLike.round()}°',
                              style: const TextStyle(
                                color: white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(icon, color: Colors.white, size: 64),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        _heroStat(
                          Icons.umbrella_rounded,
                          '${w.today.rainChance}%',
                          'Rain chance',
                        ),
                        _heroStat(
                          Icons.water_drop_rounded,
                          '${w.today.rainSum.toStringAsFixed(1)} mm',
                          'Rain today',
                        ),
                        _heroStat(
                          Icons.opacity_rounded,
                          '${w.humidity}%',
                          'Humidity',
                        ),
                        _heroStat(
                          Icons.air_rounded,
                          '${w.windSpeed.round()} km/h',
                          'Wind',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _outlook(AppColors c, FloodOutlook o) {
    final color = o.level.color;
    final step = RiskLevel.values.indexOf(o.level);
    return AppCard(
      borderColor: color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(Icons.flood_rounded, color, size: 44, squircle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FLOOD OUTLOOK TODAY',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      o.title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                o.level == RiskLevel.normal ? 'Low' : o.level.label,
                color,
                solid: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            o.message,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          // Three-step meter: Low · Moderate · High
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: i <= step ? 1 : 0),
                    duration: Duration(milliseconds: 500 + i * 250),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: c.surfaceAlt,
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: RiskLevel.values[i].color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: c.textSecondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Estimated from the rain forecast. Not an official warning. Follow PAGASA & CDRRMO.',
                  style: TextStyle(color: c.textSecondary, fontSize: 10.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hourly(AppColors c, MabalacatWeather w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Next 12 hours'),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: w.hourly.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final h = w.hourly[i];
              final now = i == 0;
              final (_, icon) = weatherInfo(h.weatherCode, isDay: h.isDay);
              final fg = now ? Colors.white : c.textPrimary;
              final sub = now ? const Color(0xCCFFFFFF) : c.textSecondary;
              return Container(
                width: 66,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: now ? kBrandGradient : null,
                  color: now ? null : c.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: now ? Colors.transparent : c.border,
                  ),
                  boxShadow: now
                      ? [
                          BoxShadow(
                            color: kSkyBlue.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      now ? 'Now' : formatHour(h.time),
                      style: TextStyle(
                        color: sub,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(icon, color: now ? Colors.white : c.accent, size: 24),
                    Text(
                      '${h.temperature.round()}°',
                      style: TextStyle(
                        color: fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          size: 10,
                          color: now ? Colors.white : kLogoCyan,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${h.rainChance}%',
                          style: TextStyle(
                            color: sub,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _daily(AppColors c, MabalacatWeather w) {
    final lo = w.daily.map((d) => d.min).reduce((a, b) => a < b ? a : b);
    final hi = w.daily.map((d) => d.max).reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).clamp(1, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('5-day forecast'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < w.daily.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          i == 0 ? 'Today' : formatWeekday(w.daily[i].date),
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Icon(
                        weatherInfo(w.daily[i].weatherCode).$2,
                        color: c.accent,
                        size: 20,
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${w.daily[i].rainChance}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: kLogoCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '${w.daily[i].min.round()}°',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Temperature range bar, scaled across all 5 days
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final d = w.daily[i];
                            final left = (d.min - lo) / span * box.maxWidth;
                            final width =
                                ((d.max - d.min) / span * box.maxWidth).clamp(
                                  6.0,
                                  box.maxWidth,
                                );
                            return Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: c.surfaceAlt,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: left,
                                    width: width,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        gradient: const LinearGradient(
                                          colors: [kLogoCyan, kCaution],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${w.daily[i].max.round()}°',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Pulsing placeholder while the weather loads.
class _WeatherSkeleton extends StatefulWidget {
  const _WeatherSkeleton();

  @override
  State<_WeatherSkeleton> createState() => _WeatherSkeletonState();
}

class _WeatherSkeletonState extends State<_WeatherSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    Widget block(double h) => Container(
      height: h,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
      ),
    );
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_ctrl),
      child: Column(
        children: [block(250), const SizedBox(height: 14), block(150)],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// River water levels (sample data)
/// ------------------------------------------------------------
class _RiverLevels extends StatelessWidget {
  const _RiverLevels();

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('River water levels', badge: SampleBadge()),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < kRivers.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: c.border),
                  ),
                _river(c, kRivers[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _river(AppColors c, River r) {
    final color = r.risk.color;
    final rising = r.change > 0;
    return Column(
      children: [
        Row(
          children: [
            IconBadge(Icons.water_rounded, color, size: 38, squircle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    r.location,
                    style: TextStyle(color: c.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${r.level}',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${r.critical} m',
                        style: TextStyle(color: c.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rising
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: rising ? kDanger : kSafe,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${rising ? '+' : ''}${r.change} m/hr',
                      style: TextStyle(
                        color: rising ? kDanger : kSafe,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: r.ratio),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: c.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            StatusPill(r.risk.label, color),
          ],
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// Safety tips carousel
/// ------------------------------------------------------------
class _SafetyTips extends StatefulWidget {
  const _SafetyTips();

  @override
  State<_SafetyTips> createState() => _SafetyTipsState();
}

class _SafetyTipsState extends State<_SafetyTips> {
  final _page = PageController(viewportFraction: 0.9);
  int _current = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Flood safety tips'),
        SizedBox(
          height: 128,
          child: PageView.builder(
            controller: _page,
            padEnds: false,
            itemCount: kSafetyTips.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final t = kSafetyTips[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AppCard(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      t.color.withValues(alpha: c.isDark ? 0.28 : 0.16),
                      c.surface,
                    ],
                  ),
                  borderColor: t.color.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      IconBadge(t.icon, t.color, size: 52, squircle: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.body,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < kSafetyTips.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _current
                      ? c.accent
                      : c.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
