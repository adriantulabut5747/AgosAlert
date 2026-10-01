import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme.dart';

/// ============================================================
/// THEME REVEAL: switching light <-> dark spreads the new theme out in
/// a circle from where the user tapped, across the whole screen.
///
/// How it works:
///  1. Take a picture of the screen as it is (old theme).
///  2. Lay that picture over the app, so nothing seems to change yet.
///  3. Switch the theme underneath.
///  4. Cut a growing circular hole in the picture, starting at the tap,
///     until the picture is gone and the new theme shows everywhere.
///
/// [ThemeReveal] wraps the whole app (main.dart). To switch themes with
/// the effect, call [setThemeMode] instead of setting themeNotifier.
/// ============================================================

final GlobalKey<_ThemeRevealState> _revealKey = GlobalKey();

/// Switches to [mode] with the circle reveal (or instantly if the
/// device asks for less motion, or the picture can't be taken).
void setThemeMode(ThemeMode mode) {
  final state = _revealKey.currentState;
  if (state == null) {
    themeNotifier.value = mode;
  } else {
    state._reveal(mode);
  }
}

class ThemeReveal extends StatefulWidget {
  final Widget child;
  ThemeReveal({required this.child}) : super(key: _revealKey);

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeInOutCubic,
  );
  ui.Image? _old; // the picture of the old theme
  Offset _origin = Offset.zero; // where the circle starts
  Offset _lastTap = Offset.zero;

  @override
  void dispose() {
    _ctrl.dispose();
    _old?.dispose();
    super.dispose();
  }

  Future<void> _reveal(ThemeMode mode) async {
    if (mode == themeNotifier.value) return;
    final boundary =
        _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (boundary == null || reduceMotion || _ctrl.isAnimating) {
      themeNotifier.value = mode;
      return;
    }
    ui.Image image;
    try {
      image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
    } catch (_) {
      themeNotifier.value = mode; // e.g. a renderer that can't do it
      return;
    }
    if (!mounted) return;
    setState(() {
      _old?.dispose();
      _old = image;
      _origin = _lastTap;
    });
    themeNotifier.value = mode;
    await _ctrl.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _old?.dispose();
      _old = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listener notes where every tap lands (without stopping it), so the
    // circle can start from the button that was pressed.
    return Listener(
      onPointerDown: (e) => _lastTap = e.position,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          RepaintBoundary(key: _boundary, child: widget.child),
          if (_old != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _curve,
                  builder: (context, _) => CustomPaint(
                    painter: _HolePainter(_old!, _origin, _curve.value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints the old-theme picture with a circular hole of growing size.
class _HolePainter extends CustomPainter {
  final ui.Image image;
  final Offset origin;
  final double t; // 0 = no hole, 1 = hole covers the whole screen
  _HolePainter(this.image, this.origin, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Far enough to reach the corner furthest from the tap.
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxR = corners.map((c) => (c - origin).distance).reduce(math.max);
    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: origin, radius: maxR * t));
    canvas.clipPath(hole);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) =>
      old.t != t || old.image != image || old.origin != origin;
}
