import 'package:flutter/material.dart';

/// ============================================================
/// THEME — colors, text, and light/dark switching
/// ============================================================

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

const String kFontFamily = 'PlusJakartaSans';

// Brand palette — shades of blue, like water
const Color kMidnightBlue = Color(0xFF0B1130); // deepest navy - brand primary
const Color kDeepBlue = Color(
  0xFF060911,
); // near-black navy - dark gradient bottom
const Color kOceanBlue = Color(0xFF1E4E79);
const Color kSkyBlue = Color(0xFF2D7DD2); // main accent
const Color kSkyBlueLight = Color(0xFF4FA8DE);
const Color kLogoCyan = Color(0xFF29C5F6); // the "agos" blue in the logo
const Color kLogoYellow = Color(0xFFFFD21F); // the dot in the logo

// Status colors (same in both themes)
const Color kSafe = Color(0xFF22C55E);
const Color kCaution = Color(0xFFF59E0B);
const Color kDanger = Color(0xFFEF4444);

// Dark theme surfaces
const Color kSurfaceDark = Color(0xFF101828);
const Color kSurfaceDarkAlt = Color(0xFF16223A);
const Color kTextPrimaryDark = Color(0xFFF3F7FB);
const Color kTextSecondaryDark = Color(0xFF9FB4CC);

// Light theme surfaces
const Color kBgLightTop = Color(0xFFE6F1FB);
const Color kBgLightBottom = Color(0xFFF8FBFE);
const Color kSurfaceLight = Color(0xFFFFFFFF);
const Color kSurfaceLightAlt = Color(0xFFEFF6FC);
const Color kTextPrimaryLight = Color(0xFF0B1130);
const Color kTextSecondaryLight = Color(0xFF5D7A99);

const LinearGradient kBrandGradient = LinearGradient(
  colors: [kSkyBlue, kLogoCyan],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AppColors {
  final BuildContext context;
  AppColors(this.context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get gradientTop => isDark ? kMidnightBlue : kBgLightTop;
  Color get gradientBottom => isDark ? kDeepBlue : kBgLightBottom;
  Color get surface => isDark ? kSurfaceDark : kSurfaceLight;
  Color get surfaceAlt => isDark ? kSurfaceDarkAlt : kSurfaceLightAlt;
  Color get textPrimary => isDark ? kTextPrimaryDark : kTextPrimaryLight;
  Color get textSecondary => isDark ? kTextSecondaryDark : kTextSecondaryLight;
  Color get border => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFF0B1130).withValues(alpha: 0.07);
  Color get shadow => Colors.black.withValues(alpha: isDark ? 0.35 : 0.06);
  Color get accent => kSkyBlue;
}

/// Flood / alert severity, shared by the map, alerts, and river levels.
enum RiskLevel {
  normal('Normal', kSafe, Icons.check_circle_rounded),
  moderate('Moderate', kCaution, Icons.error_rounded),
  high('High', kDanger, Icons.warning_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const RiskLevel(this.label, this.color, this.icon);
}

ThemeData _baseTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: kSkyBlue,
    brightness: b,
    primary: kSkyBlue,
    surface: dark ? kSurfaceDark : kSurfaceLight,
  );
  return ThemeData(
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? kMidnightBlue : kBgLightTop,
    useMaterial3: true,
    fontFamily: kFontFamily,
    splashFactory: InkSparkle.splashFactory,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? kSurfaceDarkAlt : kMidnightBlue,
      contentTextStyle: const TextStyle(
        fontFamily: kFontFamily,
        color: Colors.white,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      color: dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
    ),
  );
}

ThemeData buildDarkTheme() => _baseTheme(Brightness.dark);
ThemeData buildLightTheme() => _baseTheme(Brightness.light);
