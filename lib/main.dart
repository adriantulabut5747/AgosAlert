import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AgosAlertApp());
}

/// ============================================================
/// THEME SYSTEM — all blue, no gold
/// ============================================================

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

// Brand palette — shades of blue, like water
const Color kMidnightBlue = Color(0xFF0B1130); // deepest navy - brand primary
const Color kDeepBlue = Color(0xFF060911); // near-black navy - dark gradient bottom
const Color kOceanBlue = Color(0xFF1E4E79); // secondary accent (moderate severity)
const Color kSkyBlue = Color(0xFF2D7DD2); // main accent - deeper cobalt, not pastel
const Color kSkyBlueLight = Color(0xFF4FA8DE); // accent gradient highlight (was primary)

// Dark theme surfaces
const Color kSurfaceDark = Color(0xFF101828);
const Color kSurfaceDarkAlt = Color(0xFF16223A);
const Color kTextPrimaryDark = Color(0xFFF3F7FB);
const Color kTextSecondaryDark = Color(0xFF9FB4CC);

// Light theme surfaces
const Color kBgLightTop = Color(0xFFEAF4FC);
const Color kBgLightBottom = Color(0xFFFFFFFF);
const Color kSurfaceLight = Color(0xFFFFFFFF);
const Color kSurfaceLightAlt = Color(0xFFEFF6FC);
const Color kTextPrimaryLight = Color(0xFF0B1130);
const Color kTextSecondaryLight = Color(0xFF5D7A99);

class AppColors {
  final BuildContext context;
  AppColors(this.context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get gradientTop => isDark ? kMidnightBlue : kBgLightTop;
  Color get gradientBottom => isDark ? kDeepBlue : kBgLightBottom;
  Color get surface => isDark ? kSurfaceDark : kSurfaceLight;
  Color get surfaceAlt => isDark ? kSurfaceDarkAlt : kSurfaceLightAlt;
  Color get textPrimary => isDark ? kTextPrimaryDark : kTextPrimaryLight;
  Color get textSecondary =>
      isDark ? kTextSecondaryDark : kTextSecondaryLight;
  Color get border =>
      isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.06);
  Color get accent => kSkyBlue;
  Color get accentDeep => kOceanBlue;
  Color get primaryBlue => kMidnightBlue;
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kMidnightBlue,
    colorScheme: const ColorScheme.dark(
      primary: kSkyBlue,
      secondary: kOceanBlue,
      surface: kSurfaceDark,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
  );
}

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: kBgLightTop,
    colorScheme: const ColorScheme.light(
      primary: kMidnightBlue,
      secondary: kSkyBlue,
      surface: kSurfaceLight,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto',
  );
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    // Fill the whole screen, even when the child (e.g. a scroll view) is
    // shorter — otherwise the area below it shows as a blank strip.
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.gradientTop, c.gradientBottom],
        ),
      ),
      child: child,
    );
  }
}

/// Shows an image from assets/images/, or [fallback] if it fails to load.
class _AssetImageWithFallback extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final Widget fallback;
  const _AssetImageWithFallback(this.path,
      {this.width, this.height, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}

class AgosAlertApp extends StatelessWidget {
  const AgosAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'AGOSALERT',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          home: const LoginScreen(),
        );
      },
    );
  }
}

/// ============================================================
/// LOGIN SCREEN — Google only, no Facebook
/// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(_slideRoute(const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // The logo image already includes the "agosalert." text.
                // If it fails to load, show the old glowing icon + title.
                _AssetImageWithFallback(
                  'assets/images/logo_icon.png',
                  height: 170,
                  fallback: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          final glow = 12 + (_glowController.value * 10);
                          return Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [c.accent, kSkyBlueLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.accent.withValues(alpha: 0.5),
                                  blurRadius: glow,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.waves_rounded,
                                color: Colors.white, size: 44),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'AGOSALERT',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Flood Monitoring & Emergency Assistance',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 32),
                _GlassCard(
                  child: Column(
                    children: [
                      Text(
                        'Login to your account',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(c,
                          hint: 'Email or Phone Number',
                          icon: Icons.email_outlined),
                      const SizedBox(height: 14),
                      _buildTextField(
                        c,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: c.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text('Forgot Password?',
                              style: TextStyle(
                                  color: c.textSecondary, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                                colors: [c.accent, kSkyBlueLight]),
                            boxShadow: [
                              BoxShadow(
                                  color: c.accent.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _goToHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Login',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: Divider(color: c.border)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('or',
                                style: TextStyle(
                                    color: c.textSecondary, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: c.border)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _socialButton(
                        c,
                        'Continue with Google',
                        _AssetImageWithFallback(
                          'assets/images/google_logo.png',
                          width: 18,
                          height: 18,
                          fallback: Icon(Icons.g_mobiledata,
                              color: c.textPrimary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('No sign up needed for this demo',
                    style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    AppColors c, {
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: c.surfaceAlt, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        obscureText: obscure,
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: c.textSecondary, size: 20),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _socialButton(AppColors c, String label, Widget icon) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: icon,
        label: Text(label, style: TextStyle(color: c.textPrimary)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ============================================================
/// HOME SHELL — persistent top bar (theme toggle always visible)
/// + glassy bottom nav
/// ============================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void switchTab(int index) => setState(() => _currentIndex = index);

  final List<Widget> _tabs = const [
    HomeTab(),
    MapTab(),
    AlertsTab(),
    AssistanceTab(),
    MoreTab(),
  ];

  final List<String> _labels = const [
    'Home',
    'Map',
    'Alerts',
    'Assistance',
    'More',
  ];

  final List<IconData> _icons = const [
    Icons.home_rounded,
    Icons.map_rounded,
    Icons.notifications_rounded,
    Icons.groups_rounded,
    Icons.more_horiz_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(c),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: _tabs),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: c.isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / _labels.length;
                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          left: itemWidth * _currentIndex,
                          top: 8,
                          bottom: 8,
                          width: itemWidth,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(_labels.length, (i) {
                            final selected = i == _currentIndex;
                            return Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () =>
                                    setState(() => _currentIndex = i),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _icons[i],
                                      color: selected
                                          ? c.accent
                                          : c.textSecondary,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _labels[i],
                                      style: TextStyle(
                                        color: selected
                                            ? c.accent
                                            : c.textSecondary,
                                        fontSize: 10.5,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Wordmark logo; falls back to the old icon + text if it fails.
          _AssetImageWithFallback(
            'assets/images/logo_wordmark.png',
            height: 30,
            fallback: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [c.accent, kSkyBlueLight]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.waves_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('AGOSALERT',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded,
                    color: c.textPrimary, size: 22),
                onPressed: () {},
              ),
              // Always-visible theme toggle
              IconButton(
                tooltip: c.isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(
                  c.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: c.accent,
                  size: 22,
                ),
                onPressed: () {
                  themeNotifier.value =
                      c.isDark ? ThemeMode.light : ThemeMode.dark;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// HOME TAB — expanded with more scrollable content
/// ============================================================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mabalacat City',
              style: TextStyle(
                  color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('Here is today\'s flood situation',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
          const SizedBox(height: 18),
          _WeatherCard(c: c),
          const SizedBox(height: 24),
          Text('Quick Actions',
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _quickAction(context, c, Icons.map_rounded, 'Live Map',
                  onTap: () => _switchTab(context, 1)),
              _quickAction(context, c, Icons.water_drop_rounded, 'Flood Levels'),
              _quickAction(
                  context, c, Icons.support_agent_rounded, 'Emergency Assistance',
                  onTap: () => _switchTab(context, 3)),
              _quickAction(context, c, Icons.report_rounded, 'Report Incident',
                  onTap: () {
                Navigator.of(context)
                    .push(_slideRoute(const ReportIncidentScreen()));
              }),
            ],
          ),
          const SizedBox(height: 28),
          Text('River Water Levels',
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          _RiverLevelsCard(c: c),
          const SizedBox(height: 28),
          Text('Nearby Evacuation Centers',
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          _evacRow(c, 'Mabalacat Sports Complex', '2.1 km away', Icons.sports_rounded),
          _evacRow(c, 'San Agustin Barangay Hall', '1.4 km away', Icons.apartment_rounded),
          _evacRow(c, 'Mabalacat City Hall Grounds', '3.0 km away', Icons.account_balance_rounded),
          const SizedBox(height: 28),
          Text('Safety Tips',
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          _tipRow(c, Icons.arrow_upward_rounded, 'Move to higher ground early, before the water rises further.'),
          _tipRow(c, Icons.power_off_rounded, 'Turn off electrical appliances and the main breaker if flooding reaches your home.'),
          _tipRow(c, Icons.block_rounded, 'Avoid wading through floodwater. It can hide debris, current, and open drains.'),
          _tipRow(c, Icons.battery_charging_full_rounded, 'Keep your phone charged and check AGOSALERT alerts regularly.'),
        ],
      ),
    );
  }

  void _switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_HomeShellState>()?.switchTab(index);
  }

  Widget _quickAction(
    BuildContext context,
    AppColors c,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [c.accent, kSkyBlueLight]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _evacRow(AppColors c, String name, String distance, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration:
                BoxDecoration(color: c.accent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: c.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Text(distance, style: TextStyle(color: c.textSecondary, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _tipRow(AppColors c, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: c.accent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: c.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(color: c.textSecondary, fontSize: 12.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Live weather for Mabalacat City from Open-Meteo (https://open-meteo.com).
/// Free, no API key, and it allows browser requests, so it works on web.
class MabalacatWeather {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double precipitation; // mm in the last 15 minutes
  final double windSpeed; // km/h
  final int weatherCode; // WMO code, see _weatherInfo
  final int rainChanceToday; // %
  final DateTime time; // local Manila time

  const MabalacatWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.weatherCode,
    required this.rainChanceToday,
    required this.time,
  });

  static final _url = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '15.2236', // Mabalacat City
    'longitude': '120.5714',
    'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,'
        'precipitation,weather_code,wind_speed_10m',
    'daily': 'precipitation_probability_max',
    'forecast_days': '1',
    'timezone': 'Asia/Manila',
  });

  static Future<MabalacatWeather> fetch() async {
    final res = await http.get(_url).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Weather API returned ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final cur = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    return MabalacatWeather(
      temperature: (cur['temperature_2m'] as num).toDouble(),
      feelsLike: (cur['apparent_temperature'] as num).toDouble(),
      humidity: (cur['relative_humidity_2m'] as num).toInt(),
      precipitation: (cur['precipitation'] as num).toDouble(),
      windSpeed: (cur['wind_speed_10m'] as num).toDouble(),
      weatherCode: (cur['weather_code'] as num).toInt(),
      rainChanceToday:
          ((daily['precipitation_probability_max'] as List).first as num?)
                  ?.toInt() ??
              0,
      time: DateTime.parse(cur['time'] as String),
    );
  }
}

/// Turns a WMO weather code into a label and icon.
(String, IconData) _weatherInfo(int code) {
  if (code == 0) return ('Clear sky', Icons.wb_sunny_rounded);
  if (code <= 2) return ('Partly cloudy', Icons.wb_cloudy_outlined);
  if (code == 3) return ('Overcast', Icons.cloud_rounded);
  if (code <= 48) return ('Foggy', Icons.foggy);
  if (code <= 57) return ('Drizzle', Icons.grain_rounded);
  if (code <= 67) return ('Rain', Icons.water_drop_rounded);
  if (code <= 77) return ('Snow', Icons.ac_unit_rounded);
  if (code <= 82) return ('Rain showers', Icons.umbrella_rounded);
  return ('Thunderstorm', Icons.thunderstorm_rounded);
}

String _formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

class _WeatherCard extends StatefulWidget {
  final AppColors c;
  const _WeatherCard({required this.c});

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  late Future<MabalacatWeather> _weather;

  @override
  void initState() {
    super.initState();
    _weather = MabalacatWeather.fetch();
  }

  void _refresh() => setState(() => _weather = MabalacatWeather.fetch());

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.isDark
              ? [kOceanBlue, kSurfaceDarkAlt]
              : [kSurfaceLightAlt, kSurfaceLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: c.accent.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: FutureBuilder<MabalacatWeather>(
        future: _weather,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              height: 90,
              child: Center(
                  child: CircularProgressIndicator(color: c.accent)),
            );
          }
          if (snap.hasError) {
            return Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: c.textSecondary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Couldn\'t load the weather. Check your internet.',
                      style: TextStyle(color: c.textSecondary, fontSize: 12.5)),
                ),
                TextButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            );
          }
          final w = snap.data!;
          final (label, icon) = _weatherInfo(w.weatherCode);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.22),
                        shape: BoxShape.circle),
                    child: Icon(icon, color: c.accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${w.temperature.round()}°C · $label',
                            style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(height: 2),
                        Text('Feels like ${w.feelsLike.round()}°C',
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refresh,
                    icon: Icon(Icons.refresh_rounded,
                        color: c.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stat(c, Icons.umbrella_rounded, '${w.rainChanceToday}%',
                      'Rain today'),
                  _stat(c, Icons.water_drop_outlined,
                      '${w.precipitation} mm', 'Rain now'),
                  _stat(c, Icons.opacity_rounded, '${w.humidity}%',
                      'Humidity'),
                  _stat(c, Icons.air_rounded, '${w.windSpeed.round()} km/h',
                      'Wind'),
                ],
              ),
              const SizedBox(height: 12),
              Text('Updated ${_formatTime(w.time)} · Open-Meteo',
                  style: TextStyle(color: c.textSecondary, fontSize: 11)),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(AppColors c, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: c.accent, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5)),
        Text(label, style: TextStyle(color: c.textSecondary, fontSize: 10.5)),
      ],
    );
  }
}

class _RiverLevelsCard extends StatelessWidget {
  final AppColors c;
  const _RiverLevelsCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final rivers = [
      {'name': 'Mabalacat River', 'loc': 'Brgy. San Agustin', 'level': 4.2, 'max': 5.0, 'status': 'High'},
      {'name': 'Pampanga River', 'loc': 'Mabalacat Area', 'level': 2.8, 'max': 5.0, 'status': 'Moderate'},
      {'name': 'Dona Maria River', 'loc': 'Mabalacat City', 'level': 1.6, 'max': 5.0, 'status': 'Low'},
      {'name': 'Libtong River', 'loc': 'Mabalacat City', 'level': 0.8, 'max': 5.0, 'status': 'Normal'},
    ];

    Color statusColor(String status) {
      switch (status) {
        case 'High':
          return Colors.redAccent;
        case 'Moderate':
          return kOceanBlue;
        default:
          return Colors.green.shade600;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: rivers.map((r) {
          final ratio = (r['level'] as double) / (r['max'] as double);
          final color = statusColor(r['status'] as String);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['name'] as String,
                            style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(r['loc'] as String,
                            style: TextStyle(color: c.textSecondary, fontSize: 11)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(r['status'] as String,
                              style: TextStyle(
                                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 2),
                        Text('${r['level']}m / ${r['max']}m',
                            style: TextStyle(color: c.textSecondary, fontSize: 10.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: c.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ============================================================
/// MAP TAB — real map image (OpenStreetMap static tiles),
/// centered on Mabalacat City, with pin overlay + legend
/// ============================================================
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  // Mabalacat City, Pampanga approx. coordinates
  static const double _lat = 15.2213;
  static const double _lng = 120.5730;
  static const String _mapUrl =
      'https://staticmap.openstreetmap.de/staticmap.php?center=$_lat,$_lng&zoom=13&size=640x420&maptype=mapnik&markers=$_lat,$_lng,red-pushpin';

  static const List<Map<String, Object>> _pins = [
    {'name': 'Brgy. San Agustin', 'risk': 'High', 'level': '1.8 m', 'top': 50.0, 'left': 40.0},
    {'name': 'Brgy. Tabun', 'risk': 'Moderate', 'level': '0.9 m', 'top': 130.0, 'left': 150.0},
    {'name': 'Brgy. Dapdap', 'risk': 'Moderate', 'level': '0.7 m', 'top': 90.0, 'left': 220.0},
    {'name': 'Brgy. Duquit', 'risk': 'Low', 'level': '0.3 m', 'top': 210.0, 'left': 70.0},
  ];

  Color _riskColor(String risk) {
    switch (risk) {
      case 'High':
        return Colors.redAccent;
      case 'Moderate':
        return kOceanBlue;
      default:
        return Colors.green.shade600;
    }
  }

  String _riskGuidance(String risk) {
    switch (risk) {
      case 'High':
        return 'Move to higher ground now. Avoid this area until conditions improve.';
      case 'Moderate':
        return 'Stay alert and keep monitoring updates. Avoid unnecessary travel here.';
      default:
        return 'Situation is normal for this area. No action needed right now.';
    }
  }

  void _showFloodStatus(BuildContext context, Map<String, Object> pin) {
    final c = AppColors(context);
    final risk = pin['risk'] as String;
    final color = _riskColor(risk);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration:
                        BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                    child: Icon(Icons.location_on, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pin['name'] as String,
                            style: TextStyle(
                                color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Mabalacat City',
                            style: TextStyle(color: c.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration:
                          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                      child: Text('$risk RISK'.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Text('Water level: ${pin['level']}',
                        style: TextStyle(
                            color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(_riskGuidance(risk),
                  style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.45)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Close', style: TextStyle(color: c.textPrimary)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Flood Map',
              style: TextStyle(
                  color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Mabalacat City, Pampanga — tap a pin for details',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _mapUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: c.surfaceAlt,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stack) => _mapFallback(c),
                  ),
                  for (final pin in _pins)
                    Positioned(
                      top: pin['top'] as double,
                      left: pin['left'] as double,
                      child: GestureDetector(
                        onTap: () => _showFloodStatus(context, pin),
                        child: _PulsingPin(color: _riskColor(pin['risk'] as String)),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: c.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: c.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FLOOD STATUS',
                                  style: TextStyle(
                                      color: c.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6)),
                              const SizedBox(height: 6),
                              _legendRow(c, Colors.redAccent, 'High Risk', '> 1.5 m'),
                              _legendRow(c, kOceanBlue, 'Moderate', '0.5–1.5 m'),
                              _legendRow(c, Colors.green.shade600, 'Low Risk', '< 0.5 m'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: Text('Map data © OpenStreetMap contributors',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85), fontSize: 9)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapFallback(AppColors c) {
    return Container(
      color: c.surfaceAlt,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: c.textSecondary, size: 32),
            const SizedBox(height: 8),
            Text('Map preview unavailable offline',
                style: TextStyle(color: c.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(AppColors c, Color color, String label, String range) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label  ', style: TextStyle(color: c.textPrimary, fontSize: 11)),
          Text(range, style: TextStyle(color: c.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _PulsingPin extends StatefulWidget {
  final Color color;
  const _PulsingPin({required this.color});

  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final scale = 0.5 + _ctrl.value * 0.8;
              final opacity = (1 - _ctrl.value).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.4), shape: BoxShape.circle),
                  ),
                ),
              );
            },
          ),
          Icon(Icons.location_on, color: widget.color, size: 28),
        ],
      ),
    );
  }
}

/// ============================================================
/// ALERTS TAB — redesigned: filter chips, grouped, minimal list
/// ============================================================
class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  String _filter = 'All';
  final List<String> _filters = const ['All', 'Flood', 'Weather', 'Road', 'Shelter'];

  final List<Map<String, String>> _alerts = const [
    {
      'icon': 'warning',
      'category': 'Flood',
      'title': 'Flood Alert',
      'desc': 'Moderate flooding expected in Brgy. San Agustin.',
      'time': '10:24 AM',
      'level': 'high',
    },
    {
      'icon': 'rain',
      'category': 'Weather',
      'title': 'Heavy Rainfall Advisory',
      'desc': 'Expect continuous rainfall for the next 3 hours.',
      'time': '08:15 AM',
      'level': 'moderate',
    },
    {
      'icon': 'road',
      'category': 'Road',
      'title': 'Road Closure',
      'desc': 'MacArthur Highway (near Dau) impassable.',
      'time': '07:50 AM',
      'level': 'moderate',
    },
    {
      'icon': 'shelter',
      'category': 'Shelter',
      'title': 'Evacuation Center Open',
      'desc': 'Mabalacat Sports Complex now accepting evacuees.',
      'time': '06:30 AM',
      'level': 'normal',
    },
  ];

  IconData _iconFor(String key) {
    switch (key) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'rain':
        return Icons.water_drop_rounded;
      case 'road':
        return Icons.block_rounded;
      case 'shelter':
        return Icons.home_work_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'high':
        return Colors.redAccent;
      case 'moderate':
        return kOceanBlue;
      default:
        return Colors.green.shade600;
    }
  }

  List<Map<String, String>> get _filtered => _filter == 'All'
      ? _alerts
      : _alerts.where((a) => a['category'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final items = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alerts',
              style: TextStyle(
                  color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${items.length} update${items.length == 1 ? '' : 's'}',
              style: TextStyle(color: c.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = f == _filter;
                return ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: c.accent,
                  backgroundColor: c.surfaceAlt,
                  side: BorderSide(color: c.border),
                  shape: const StadiumBorder(),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : c.textSecondary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text('TODAY',
              style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('No alerts in this category',
                        style: TextStyle(color: c.textSecondary, fontSize: 13)))
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
                    itemBuilder: (context, i) {
                      final a = items[i];
                      final color = _levelColor(a['level']!);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(top: 5),
                              decoration:
                                  BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Icon(_iconFor(a['icon']!), color: c.textSecondary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['title']!,
                                      style: TextStyle(
                                          color: c.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5)),
                                  const SizedBox(height: 3),
                                  Text(a['desc']!,
                                      style: TextStyle(
                                          color: c.textSecondary,
                                          fontSize: 12.5,
                                          height: 1.4)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(a['time']!,
                                style: TextStyle(color: c.textSecondary, fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// ASSISTANCE TAB — real Mabalacat City hotline directory
/// ============================================================
class AssistanceTab extends StatelessWidget {
  const AssistanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);

    final quickActions = [
      {'icon': Icons.directions_run_rounded, 'label': 'Request Rescue'},
      {'icon': Icons.location_city_rounded, 'label': 'Evacuation Centers'},
      {'icon': Icons.person_search_rounded, 'label': 'Missing Person'},
    ];

    final hotlines = [
      {'name': 'National Emergency Hotline', 'number': '911', 'icon': Icons.phone_in_talk_rounded},
      {'name': 'Mabalacat CDRRMO', 'number': '0998-999-4357', 'icon': Icons.security_rounded},
      {
        'name': 'Mabalacat Bureau of Fire Protection',
        'number': '0933-990-9960',
        'icon': Icons.local_fire_department_rounded,
      },
      {
        'name': 'Mabalacat Police Station (PNP)',
        'number': '0998-598-5458',
        'icon': Icons.local_police_rounded,
      },
      {
        'name': 'Mabalacat City Hall',
        'number': '(045) 649-8620',
        'icon': Icons.account_balance_rounded,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Assistance',
                style: TextStyle(
                    color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Reach help fast', style: TextStyle(color: c.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: quickActions.map((item) => _quickTile(c, item)).toList(),
            ),
            const SizedBox(height: 24),
            Text('HOTLINE DIRECTORY',
                style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            ...hotlines.map((h) => _hotlineRow(c, h)),
            const SizedBox(height: 10),
            Text(
              'Numbers sourced from Mabalacat City government channels. Verify locally before relying on them in an actual emergency.',
              style: TextStyle(color: c.textSecondary, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTile(AppColors c, Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item['icon'] as IconData, color: c.accent, size: 22),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item['label'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hotlineRow(AppColors c, Map<String, dynamic> h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration:
                BoxDecoration(color: c.accent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(h['icon'] as IconData, color: c.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(h['name'] as String,
                style: TextStyle(color: c.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500)),
          ),
          Text(h['number'] as String,
              style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// ============================================================
/// MORE TAB
/// ============================================================
class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: c.accent,
                child: const Text('AP',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AC Parcore',
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('ac.parcore@mcc.edu.ph',
                      style: TextStyle(color: c.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel(c, 'GENERAL'),
          _tile(context, c, Icons.person_outline_rounded, 'Profile'),
          _tile(context, c, Icons.settings_outlined, 'Settings', onTap: () {
            Navigator.of(context).push(_slideRoute(const SettingsScreen()));
          }),
          const SizedBox(height: 16),
          _sectionLabel(c, 'SUPPORT'),
          _tile(context, c, Icons.help_outline_rounded, 'Help & Support'),
          _tile(context, c, Icons.info_outline_rounded, 'About AGOSALERT'),
          const SizedBox(height: 16),
          _tile(context, c, Icons.logout_rounded, 'Log Out',
              isDestructive: true, onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppColors c, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text,
          style: TextStyle(
              color: c.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }

  Widget _tile(
    BuildContext context,
    AppColors c,
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border)),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.redAccent : c.accent),
        title: Text(label,
            style: TextStyle(
                color: isDestructive ? Colors.redAccent : c.textPrimary,
                fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: c.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}

/// ============================================================
/// SETTINGS SCREEN — light / dark / system toggle (detailed)
/// ============================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: c.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text('Settings',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('APPEARANCE',
                    style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) {
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border)),
                      child: Row(
                        children: [
                          _themeOption(c, 'Light', Icons.light_mode_rounded,
                              mode == ThemeMode.light,
                              () => themeNotifier.value = ThemeMode.light),
                          _themeOption(c, 'Dark', Icons.dark_mode_rounded,
                              mode == ThemeMode.dark,
                              () => themeNotifier.value = ThemeMode.dark),
                          _themeOption(
                              c, 'System', Icons.phone_android_rounded,
                              mode == ThemeMode.system,
                              () => themeNotifier.value = ThemeMode.system),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('NOTIFICATIONS',
                    style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                _switchTile(c, Icons.notifications_active_outlined, 'Flood Alerts', true),
                _switchTile(c, Icons.campaign_outlined, 'Community Updates', true),
                _switchTile(c, Icons.location_on_outlined, 'Location Sharing', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeOption(
      AppColors c, String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? c.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : c.textSecondary, size: 20),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : c.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchTile(AppColors c, IconData icon, String label, bool initial) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        bool value = initial;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border)),
          child: Row(
            children: [
              Icon(icon, color: c.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: c.textPrimary, fontSize: 13))),
              Switch(
                value: value,
                activeThumbColor: c.accent,
                onChanged: (v) => setLocal(() => value = v),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================
/// REPORT INCIDENT SCREEN
/// ============================================================
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: c.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text('Report Incident',
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border)),
                  child: Row(
                    children: [_tabButton(c, 'Photo', 0), _tabButton(c, 'Location', 1)],
                  ),
                ),
                const SizedBox(height: 20),
                if (_tab == 0)
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border, width: 1.5)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: c.textSecondary, size: 32),
                        const SizedBox(height: 10),
                        Text('Tap to take a photo or upload from gallery',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                        color: c.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                    child: Center(
                        child: Icon(Icons.location_on_rounded, color: c.accent, size: 36)),
                  ),
                const SizedBox(height: 20),
                Text('Description (optional)',
                    style: TextStyle(color: c.textPrimary, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border)),
                  child: TextField(
                    maxLines: 3,
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g., Flooding in my area, blocked road, etc.',
                      hintStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(colors: [c.accent, kSkyBlueLight]),
                      boxShadow: [
                        BoxShadow(
                            color: c.accent.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Submit Report',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(AppColors c, String label, int index) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: selected ? c.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(14)),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? Colors.white : c.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
