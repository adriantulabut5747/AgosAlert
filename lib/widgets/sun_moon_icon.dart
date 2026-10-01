import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================
/// SUN / MOON ICON for the theme button. Instead of swapping two icons,
/// one drawing morphs between them: the sun's rays pull in and fade, the
/// sun grows, and a "bite" slides in to leave a crescent moon, while the
/// whole icon turns a little. easeOutBack makes it overshoot slightly and
/// settle, which gives the bounce. Same idea as the landing page's icon
/// (landing.css, "Theme button").
/// ============================================================
class SunMoonIcon extends StatelessWidget {
  final bool moon;
  final Color sunColor;
  final Color moonColor;
  final double size;
  const SunMoonIcon({
    required this.moon,
    required this.sunColor,
    required this.moonColor,
    this.size = 21,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: moon ? 1 : 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => CustomPaint(
        size: Size.square(size),
        painter: _SunMoonPainter(t, sunColor, moonColor),
      ),
    );
  }
}

class _SunMoonPainter extends CustomPainter {
  final double t; // 0 = sun, 1 = moon (overshoots a little past both)
  final Color sunColor;
  final Color moonColor;
  _SunMoonPainter(this.t, this.sunColor, this.moonColor);

  @override
  void paint(Canvas canvas, Size size) {
    final k = t.clamp(0.0, 1.0);
    final color = Color.lerp(sunColor, moonColor, k)!;
    canvas.scale(size.width / 24);
    // Turn the whole icon a quarter turn as it changes, ending upright on
    // the moon (the sun's rays look the same at any angle).
    canvas.translate(12, 12);
    canvas.rotate((t - 1) * math.pi / 2);
    canvas.translate(-12, -12);

    // Rays: 8 short lines that shrink toward the sun and fade out.
    final rays = 1 - k;
    if (rays > 0.01) {
      final paint = Paint()
        ..color = color.withValues(alpha: rays)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final dir = Offset(math.cos(a), math.sin(a));
        final inner = 7.6;
        final outer = 7.6 + 2.6 * rays;
        canvas.drawLine(
          const Offset(12, 12) + dir * inner,
          const Offset(12, 12) + dir * outer,
          paint,
        );
      }
    }

    // Body: r 5 (sun) -> 9 (moon). The bite slides in from the top
    // right; what's left of the body is the crescent.
    final r = 5 + 4 * t;
    final body = Path()
      ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: r));
    final biteCenter = Offset.lerp(
      const Offset(25, -1),
      const Offset(17.5, 6.5),
      t,
    )!;
    final bite = Path()
      ..addOval(Rect.fromCircle(center: biteCenter, radius: 7.5));
    canvas.drawPath(
      Path.combine(PathOperation.difference, body, bite),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SunMoonPainter old) =>
      old.t != t || old.sunColor != sunColor || old.moonColor != moonColor;
}
