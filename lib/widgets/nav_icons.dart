import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// ============================================================
/// NAV ICONS: the tab bar's icons, Facebook-style. One color only:
/// a thin outline when the tab isn't selected, solid when it is.
///
/// Drawn on a 24 x 24 grid from SVG path strings (same idea as
/// duo_icons.dart, which has the two-tone Assistance icons). To tweak
/// one, paste its `d` string into `<svg viewBox="0 0 24 24">`.
/// ============================================================

enum NavStyle { stroke, fill, fillEvenOdd }

/// One layer: a path and how it's painted. [NavStyle.fillEvenOdd] cuts
/// holes where shapes overlap (the door in the house, the hole in the pin).
class NavLayer {
  final String d;
  final NavStyle style;
  const NavLayer(this.d, this.style);
}

enum NavIcons {
  /// House.
  home(
    outline: [
      NavLayer(
        'M3.6 10.3 12 3.6l8.4 6.7V19a1.7 1.7 0 0 1-1.7 1.7H5.3A1.7 1.7 0 0 1 3.6 19Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M9.9 20.7v-4.4a1.1 1.1 0 0 1 1.1-1.1h2a1.1 1.1 0 0 1 1.1 1.1v4.4',
        NavStyle.stroke,
      ),
    ],
    filled: [
      NavLayer(
        'M3.6 10.3 12 3.6l8.4 6.7V19a1.7 1.7 0 0 1-1.7 1.7H5.3A1.7 1.7 0 0 1 3.6 19ZM10.5 20.7v-4a.9.9 0 0 1 .9-.9h1.2a.9.9 0 0 1 .9.9v4Z',
        NavStyle.fillEvenOdd,
      ),
      NavLayer(
        'M3.6 10.3 12 3.6l8.4 6.7V19a1.7 1.7 0 0 1-1.7 1.7H5.3A1.7 1.7 0 0 1 3.6 19Z',
        NavStyle.stroke,
      ),
    ],
  ),

  /// Map pin.
  map(
    outline: [
      NavLayer(
        'M12 21.3s-6.7-6-6.7-11.4a6.7 6.7 0 0 1 13.4 0c0 5.4-6.7 11.4-6.7 11.4Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M9.5 9.9a2.5 2.5 0 1 0 5.0 0a2.5 2.5 0 1 0 -5.0 0Z',
        NavStyle.stroke,
      ),
    ],
    filled: [
      NavLayer(
        'M12 21.3s-6.7-6-6.7-11.4a6.7 6.7 0 0 1 13.4 0c0 5.4-6.7 11.4-6.7 11.4ZM9.6 9.9a2.4 2.4 0 1 0 4.8 0a2.4 2.4 0 1 0 -4.8 0Z',
        NavStyle.fillEvenOdd,
      ),
      NavLayer(
        'M12 21.3s-6.7-6-6.7-11.4a6.7 6.7 0 0 1 13.4 0c0 5.4-6.7 11.4-6.7 11.4Z',
        NavStyle.stroke,
      ),
    ],
  ),

  /// Bell.
  alerts(
    outline: [
      NavLayer(
        'M12 3.4c.6 0 1 .4 1 1v.7a5.7 5.7 0 0 1 4.7 5.6v3.6l1.6 2.5c.4.6 0 1.4-.7 1.4H5.4c-.7 0-1.1-.8-.7-1.4l1.6-2.5v-3.6A5.7 5.7 0 0 1 11 5.1v-.7c0-.6.4-1 1-1Z',
        NavStyle.stroke,
      ),
      NavLayer('M9.9 20.6a2.3 2.3 0 0 0 4.2 0', NavStyle.stroke),
    ],
    filled: [
      NavLayer(
        'M12 3.4c.6 0 1 .4 1 1v.7a5.7 5.7 0 0 1 4.7 5.6v3.6l1.6 2.5c.4.6 0 1.4-.7 1.4H5.4c-.7 0-1.1-.8-.7-1.4l1.6-2.5v-3.6A5.7 5.7 0 0 1 11 5.1v-.7c0-.6.4-1 1-1Z',
        NavStyle.fill,
      ),
      NavLayer(
        'M12 3.4c.6 0 1 .4 1 1v.7a5.7 5.7 0 0 1 4.7 5.6v3.6l1.6 2.5c.4.6 0 1.4-.7 1.4H5.4c-.7 0-1.1-.8-.7-1.4l1.6-2.5v-3.6A5.7 5.7 0 0 1 11 5.1v-.7c0-.6.4-1 1-1Z',
        NavStyle.stroke,
      ),
      NavLayer('M9.6 20.2a2.6 2.6 0 0 0 4.8 0Z', NavStyle.fill),
    ],
  ),

  /// Life buoy.
  assistance(
    outline: [
      NavLayer(
        'M3.3000000000000007 12a8.7 8.7 0 1 0 17.4 0a8.7 8.7 0 1 0 -17.4 0Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M8.3 12a3.7 3.7 0 1 0 7.4 0a3.7 3.7 0 1 0 -7.4 0Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M14.6 9.4l3.6-3.6M9.4 9.4 5.8 5.8M9.4 14.6l-3.6 3.6M14.6 14.6l3.6 3.6',
        NavStyle.stroke,
      ),
    ],
    filled: [
      NavLayer(
        'M19.67 6.22A9.6 9.6 0 0 1 19.67 17.78L14.88 14.17A3.6 3.6 0 0 0 14.88 9.83ZM17.78 19.67A9.6 9.6 0 0 1 6.22 19.67L9.83 14.88A3.6 3.6 0 0 0 14.17 14.88ZM4.33 17.78A9.6 9.6 0 0 1 4.33 6.22L9.12 9.83A3.6 3.6 0 0 0 9.12 14.17ZM6.22 4.33A9.6 9.6 0 0 1 17.78 4.33L14.17 9.12A3.6 3.6 0 0 0 9.83 9.12Z',
        NavStyle.fill,
      ),
    ],
  ),

  /// Grid of four tiles.
  more(
    outline: [
      NavLayer(
        'M5.8 3.8h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M15.5 3.8h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M5.8 13.5h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M15.5 13.5h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.stroke,
      ),
    ],
    filled: [
      NavLayer(
        'M5.8 3.8h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.fill,
      ),
      NavLayer(
        'M15.5 3.8h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.fill,
      ),
      NavLayer(
        'M5.8 13.5h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.fill,
      ),
      NavLayer(
        'M15.5 13.5h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.fill,
      ),
      NavLayer(
        'M5.8 3.8h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M15.5 3.8h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M5.8 13.5h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.stroke,
      ),
      NavLayer(
        'M15.5 13.5h2.7a2 2 0 0 1 2 2v2.7a2 2 0 0 1 -2 2h-2.7a2 2 0 0 1 -2 -2v-2.7a2 2 0 0 1 2 -2Z',
        NavStyle.stroke,
      ),
    ],
  );

  final List<NavLayer> outline;
  final List<NavLayer> filled;
  const NavIcons({required this.outline, required this.filled});
}

final Map<String, Path> _parsed = {};
Path _path(String d, bool evenOdd) => _parsed.putIfAbsent(
  '$evenOdd$d',
  () =>
      parseSvgPathData(d)
        ..fillType = evenOdd ? PathFillType.evenOdd : PathFillType.nonZero,
);

/// Draws a [NavIcons] icon in one [color]: solid when [filled].
class NavIcon extends StatelessWidget {
  final NavIcons icon;
  final bool filled;
  final Color color;
  final double size;
  const NavIcon(
    this.icon, {
    required this.filled,
    required this.color,
    this.size = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _NavPainter(filled ? icon.filled : icon.outline, color),
      ),
    );
  }
}

class _NavPainter extends CustomPainter {
  final List<NavLayer> layers;
  final Color color;
  _NavPainter(this.layers, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    for (final l in layers) {
      final paint = Paint()
        ..isAntiAlias = true
        ..color = color;
      if (l.style == NavStyle.stroke) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
      canvas.drawPath(_path(l.d, l.style == NavStyle.fillEvenOdd), paint);
    }
  }

  @override
  bool shouldRepaint(_NavPainter old) =>
      old.layers != layers || old.color != color;
}
