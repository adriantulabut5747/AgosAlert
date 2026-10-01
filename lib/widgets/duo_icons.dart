import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../theme.dart';

/// ============================================================
/// DUOTONE ICONS: AgosAlert's own icons for the Assistance tab (Get
/// help tiles and hotlines), instead of the stock Material ones. The nav
/// tabs have their own one-color set in nav_icons.dart.
///
/// Each icon is drawn on a 24 x 24 grid from SVG path strings, in two
/// tones: a [base] color for the outline (navy, or near-white in the dark
/// theme) and an [accent] color for the filled detail (the logo's cyan).
/// Inactive tabs pass gray + faded gray instead.
///
/// To change or add an icon: edit the path strings below. They're normal
/// SVG `d` attributes, so you can preview one by pasting it into
/// `<svg viewBox="0 0 24 24"><path d="..."/></svg>`.
/// ============================================================

/// One layer of an icon: a path, which tone it uses, and whether it's
/// filled or drawn as a 1.8 px line (rounded ends).
class DuoLayer {
  final String d;
  final bool accent;
  final bool fill;
  const DuoLayer(this.d, this.accent, this.fill);
}

enum DuoIcons {
  /// Rescue boat on water.
  rescue([
    DuoLayer(
      'M3.4 12.6h17.2l-2.3 4.3a1.6 1.6 0 0 1-1.4.8H7.1a1.6 1.6 0 0 1-1.4-.8Z',
      true,
      true,
    ),
    DuoLayer(
      'M3.4 12.6h17.2l-2.3 4.3a1.6 1.6 0 0 1-1.4.8H7.1a1.6 1.6 0 0 1-1.4-.8Z',
      false,
      false,
    ),
    DuoLayer('M7.6 12.6V9a1 1 0 0 1 1-1h4.6l2.7 4.6', false, false),
    DuoLayer('M10.6 8V5', false, false),
    DuoLayer(
      'M2.4 20.6c1.6 0 2.3-1 3.9-1s2.3 1 3.9 1 2.3-1 3.9-1 2.3 1 3.9 1 2.3-1 3.9-1',
      true,
      false,
    ),
  ]),

  /// Shelter tent.
  evacuation([
    DuoLayer('M12 11.2 8.2 19.6h7.6Z', true, true),
    DuoLayer('M3.2 19.6 12 4.6l8.8 15', false, false),
    DuoLayer('M1.8 19.6h20.4', false, false),
    DuoLayer('M12 4.6 13.5 2.2', false, false),
  ]),

  /// Megaphone.
  report([
    DuoLayer('M14 5 7.6 9v6l6.4 4Z', true, true),
    DuoLayer(
      'M4.2 10v4c0 .6.4 1 1 1h2.4l6.4 4V5L7.6 9H5.2c-.6 0-1 .4-1 1Z',
      false,
      false,
    ),
    DuoLayer('M7.6 15l1.1 4.4', false, false),
    DuoLayer(
      'M17.2 9.2a3.9 3.9 0 0 1 0 5.6M19.7 6.7a7.4 7.4 0 0 1 0 10.6',
      false,
      false,
    ),
  ]),

  /// Person with a magnifier.
  missingPerson([
    DuoLayer(
      'M13.0 15.2a3.2 3.2 0 1 0 6.4 0a3.2 3.2 0 1 0 -6.4 0Z',
      true,
      true,
    ),
    DuoLayer(
      'M6.1000000000000005 7.8a3.3 3.3 0 1 0 6.6 0a3.3 3.3 0 1 0 -6.6 0Z',
      false,
      false,
    ),
    DuoLayer('M3.4 19.8a6.1 6.1 0 0 1 8.2-5.7', false, false),
    DuoLayer(
      'M13.0 15.2a3.2 3.2 0 1 0 6.4 0a3.2 3.2 0 1 0 -6.4 0Z',
      false,
      false,
    ),
    DuoLayer('M18.5 17.5l2.7 2.7', false, false),
  ]),

  /// Phone with call waves.
  phone([
    DuoLayer(
      'M6.7 3.8h2.4l1.3 3.9-1.8 1.3a10.4 10.4 0 0 0 5.2 5.2l1.3-1.8 3.9 1.3v2.4a2.2 2.2 0 0 1-2.4 2.2A15.4 15.4 0 0 1 4.5 6.2a2.2 2.2 0 0 1 2.2-2.4Z',
      true,
      true,
    ),
    DuoLayer(
      'M6.7 3.8h2.4l1.3 3.9-1.8 1.3a10.4 10.4 0 0 0 5.2 5.2l1.3-1.8 3.9 1.3v2.4a2.2 2.2 0 0 1-2.4 2.2A15.4 15.4 0 0 1 4.5 6.2a2.2 2.2 0 0 1 2.2-2.4Z',
      false,
      false,
    ),
    DuoLayer(
      'M14.6 3.6a6 6 0 0 1 5.8 5.8M14.4 7.1a2.6 2.6 0 0 1 2.5 2.5',
      false,
      false,
    ),
  ]),

  /// Shield with a check (CDRRMO).
  shield([
    DuoLayer('M12 3l7.4 2.8v5.5c0 4.6-3 8.1-7.4 9.7Z', true, true),
    DuoLayer(
      'M12 3l7.4 2.8v5.5c0 4.6-3 8.1-7.4 9.7-4.4-1.6-7.4-5.1-7.4-9.7V5.8Z',
      false,
      false,
    ),
    DuoLayer('M8.7 11.9l2.3 2.3 4.3-4.5', false, false),
  ]),

  /// Flame (fire protection).
  fire([
    DuoLayer(
      'M12 21.2c-1.9 0-3.2-1.3-3.2-3c0-1.8 1.4-2.8 2.3-4.3.5 1 1.1 1.4 1.7 1.6.3-1 .9-1.9 1.7-2.5.4 1.5 1.7 2.4 1.7 4.6 0 2.3-1.6 3.6-4.2 3.6Z',
      true,
      true,
    ),
    DuoLayer(
      'M12 21.2c-3.9 0-6.7-2.7-6.7-6.3 0-3.2 2-5 3.4-7 .8 1.6 1.7 2.4 2.7 2.8C11.3 7.6 12.4 5 15 2.9c.3 3 1.3 4.4 2.5 6.1a8.6 8.6 0 0 1 1.2 5.9c0 3.6-2.8 6.3-6.7 6.3Z',
      false,
      false,
    ),
  ]),

  /// Badge with a star (police).
  police([
    DuoLayer(
      'M12.00 7.10L13.09 9.90L16.09 10.07L13.76 11.97L14.53 14.88L12.00 13.25L9.47 14.88L10.24 11.97L7.91 10.07L10.91 9.90Z',
      true,
      true,
    ),
    DuoLayer(
      'M12 2.9c2 1.5 4.3 2.1 7 2.1v6.2c0 5-3 8.4-7 10-4-1.6-7-5-7-10V5c2.7 0 5-.6 7-2.1Z',
      false,
      false,
    ),
  ]),

  /// Traffic cone (traffic enforcement).
  traffic([
    DuoLayer('M8.89 8H15.11L16.3 11.8H7.7Z', true, true),
    DuoLayer('M6.95 14.2H17.05L17.8 16.6H6.2Z', true, true),
    DuoLayer('M10.2 3.8h3.6l4.6 14.7H5.6Z', false, false),
    DuoLayer('M3.8 18.5h16.4v1.8H3.8Z', false, false),
  ]),

  /// City hall.
  cityHall([
    DuoLayer('M3.6 8.6 12 4l8.4 4.6Z', true, true),
    DuoLayer('M3.6 8.6 12 4l8.4 4.6Z', false, false),
    DuoLayer('M4.6 10.8h14.8', false, false),
    DuoLayer('M6.6 13v4.6M10.2 13v4.6M13.8 13v4.6M17.4 13v4.6', false, false),
    DuoLayer('M4.2 20.2h15.6M5.2 17.8h13.6', false, false),
  ]);

  final List<DuoLayer> layers;
  const DuoIcons(this.layers);
}

/// The two tones for the current theme: navy (near-white in the dark
/// theme) + the logo's cyan when [active], gray + faded gray when not. Usage: `final (base, accent) = duoTones(context);`
(Color, Color) duoTones(BuildContext context, {bool active = true}) {
  final c = AppColors(context);
  return active
      ? (c.textPrimary, kLogoCyan)
      : (c.textSecondary, c.textSecondary.withValues(alpha: 0.4));
}

// Parsing a path string is slow-ish, so each one is parsed once and kept.
final Map<String, Path> _parsed = {};
Path _path(String d) => _parsed.putIfAbsent(d, () => parseSvgPathData(d));

/// Draws a [DuoIcons] icon. Sizes like a normal Icon.
class DuoIcon extends StatelessWidget {
  final DuoIcons icon;
  final double size;
  final Color base;
  final Color accent;
  const DuoIcon(
    this.icon, {
    required this.base,
    required this.accent,
    this.size = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _DuoPainter(icon, base, accent)),
    );
  }
}

class _DuoPainter extends CustomPainter {
  final DuoIcons icon;
  final Color base;
  final Color accent;
  _DuoPainter(this.icon, this.base, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    // The paths are on a 24 x 24 grid: scale the canvas to the real size.
    canvas.scale(size.width / 24);
    for (final l in icon.layers) {
      final paint = Paint()
        ..isAntiAlias = true
        ..color = l.accent ? accent : base;
      if (!l.fill) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
      canvas.drawPath(_path(l.d), paint);
    }
  }

  @override
  bool shouldRepaint(_DuoPainter old) =>
      old.icon != icon || old.base != base || old.accent != accent;
}

/// A [DuoIcon] in a soft cyan circle (or rounded square with [squircle]),
/// the two-tone version of IconBadge in common.dart.
class DuoIconBadge extends StatelessWidget {
  final DuoIcons icon;
  final double size;
  final bool squircle;
  const DuoIconBadge(
    this.icon, {
    this.size = 40,
    this.squircle = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final (base, accent) = duoTones(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kLogoCyan.withValues(
          alpha: AppColors(context).isDark ? 0.14 : 0.12,
        ),
        shape: squircle ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: squircle ? BorderRadius.circular(size * 0.32) : null,
      ),
      child: DuoIcon(icon, base: base, accent: accent, size: size * 0.56),
    );
  }
}
