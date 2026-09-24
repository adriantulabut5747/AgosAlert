import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// ============================================================
/// SHARED WIDGETS — the building blocks every screen uses
/// ============================================================

/// Full-screen brand gradient with two soft glows for depth.
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
      child: Stack(
        children: [
          _glow(c, top: -140, right: -120, size: 340, color: kSkyBlue),
          _glow(c, bottom: 80, left: -160, size: 320, color: kLogoCyan),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _glow(
    AppColors c, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: c.isDark ? 0.22 : 0.16),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows an image from assets/images/, or [fallback] if it fails to load.
class AssetImageWithFallback extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;
  const AssetImageWithFallback(
    this.path, {
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    required this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      // Keep showing the old image while a new one loads (no flicker).
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// The AgosAlert logo, in the right colors for the current theme:
/// the white-text versions (`*_dark.png`) in dark mode, the navy-text
/// versions in light mode. If a file is missing it falls back to the other
/// version, then to [fallback].
class BrandLogo extends StatelessWidget {
  final bool wordmark; // true = wide "agosalert." text, false = round icon
  final double height;
  final Widget fallback;
  const BrandLogo.icon({
    required this.height,
    this.fallback = const SizedBox.shrink(),
    super.key,
  }) : wordmark = false;
  const BrandLogo.wordmark({
    required this.height,
    this.fallback = const SizedBox.shrink(),
    super.key,
  }) : wordmark = true;

  static const _light = [
    'assets/images/logo_icon.png',
    'assets/images/logo_wordmark.png',
  ];
  static const _dark = [
    'assets/images/logo_icon_dark.png',
    'assets/images/logo_wordmark_dark.png',
  ];

  /// Loads the current theme's two logos ahead of time. (Only the current
  /// theme's: loading all four cost phones ~150 KB extra at startup. The
  /// other pair loads when the theme is switched; gaplessPlayback in
  /// AssetImageWithFallback keeps the old logo visible meanwhile.)
  static void precache(BuildContext context) {
    final paths = AppColors(context).isDark ? _dark : _light;
    for (final path in paths) {
      precacheImage(AssetImage(path), context, onError: (_, _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = wordmark ? 1 : 0;
    final dark = AppColors(context).isDark;
    final first = dark ? _dark[i] : _light[i];
    final second = dark ? _light[i] : _dark[i];
    return AssetImageWithFallback(
      first,
      height: height,
      fallback: AssetImageWithFallback(
        second,
        height: height,
        fallback: fallback,
      ),
    );
  }
}

/// Frosted-glass card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: c.isDark ? 0.62 : 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The standard card: surface color, soft border and shadow.
/// Pass [onTap] to make it pressable (it shrinks slightly when pressed).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Gradient? gradient;
  final double radius;
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.gradient,
    this.radius = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final card = Container(
      decoration: BoxDecoration(
        color: gradient == null ? c.surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // A see-through Material so tap ripples (InkWell, ListTile) show on
      // top of the card color instead of hiding behind it.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null) return card;
    return PressableScale(onTap: onTap, child: card);
  }
}

/// Shrinks its child a little while pressed — makes taps feel physical.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const PressableScale({
    required this.child,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fades and slides its child up when it first appears.
/// Give each item a bigger [delay] for a staggered entrance.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 520);
  // The delay is built into the animation (it waits during the first part)
  // instead of using a timer, so nothing is left pending in tests.
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.delay + _run,
  )..forward();
  late final Animation<double> _curve = CurvedAnimation(
    parent: _ctrl,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _run).inMilliseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Big brand-gradient button with a glow.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Gradient gradient;
  const GradientButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.gradient = kBrandGradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final glow = gradient.colors.first;
    return PressableScale(
      onTap: loading ? null : onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onPressed == null ? 0.5 : 1,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, color: Colors.white, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Small rounded colored label, e.g. "HIGH" or "Open".
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool solid;
  const StatusPill(this.label, this.color, {this.solid = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: solid ? Colors.white : color,
          fontSize: 9.5,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Marks a section that still shows made-up demo data.
class SampleBadge extends StatelessWidget {
  const SampleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Tooltip(
      message: 'Demo data — live readings coming soon',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: c.textSecondary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'SAMPLE',
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 8.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Section title with an optional badge and "See all" style action.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? badge;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(
    this.title, {
    this.badge,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (badge != null) ...[const SizedBox(width: 8), badge!],
          const Spacer(),
          if (actionLabel != null)
            PressableScale(
              onTap: onAction,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      color: c.accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.accent, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Round tinted icon, used in lists and cards.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool squircle;
  const IconBadge(
    this.icon,
    this.color, {
    this.size = 40,
    this.squircle = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: squircle ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: squircle ? BorderRadius.circular(size * 0.32) : null,
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Small pulsing dot that says "this is live".
class LiveDot extends StatefulWidget {
  final Color color;
  const LiveDot({this.color = kSafe, super.key});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6 + 8 * _ctrl.value,
              height: 6 + 8 * _ctrl.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.5 * (1 - _ctrl.value)),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated layered water waves — the "agos" (current) brand element.
class AnimatedWaves extends StatefulWidget {
  final double height;
  final List<Color> colors;
  const AnimatedWaves({
    this.height = 80,
    this.colors = const [
      Color(0x332D7DD2),
      Color(0x4429C5F6),
      Color(0x552D7DD2),
    ],
    super.key,
  });

  @override
  State<AnimatedWaves> createState() => _AnimatedWavesState();
}

class _AnimatedWavesState extends State<AnimatedWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: RepaintBoundary(
          child: CustomPaint(painter: _WavePainter(_ctrl, widget.colors)),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Animation<double> anim;
  final List<Color> colors;
  _WavePainter(this.anim, this.colors) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < colors.length; i++) {
      final phase = anim.value * 2 * math.pi * (i.isEven ? 1 : -1) + i * 1.3;
      final amp = size.height * (0.12 + i * 0.04);
      final base = size.height * (0.35 + i * 0.18);
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 4) {
        final y =
            base +
            math.sin(x / size.width * 2 * math.pi * (1.2 + i * 0.3) + phase) *
                amp;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.colors != colors;
}

/// Title row at the top of each tab.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const PageHeader(this.title, {this.subtitle, this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Scaffold for screens opened on top of the tabs (with a back button).
class SubpageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottom;
  const SubpageScaffold({
    required this.title,
    required this.body,
    this.bottom,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: c.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}

Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Opens a rounded bottom sheet with a drag handle.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final c = AppColors(sheetContext);
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: c.border),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                      color: c.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                builder(sheetContext),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Animated "done" popup, e.g. after submitting a report.
Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (dialogContext, _, _) {
      final c = AppColors(dialogContext);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [kSafe, Color(0xFF4ADE80)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kSafe.withValues(alpha: 0.45),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Done',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: child,
      ),
    ),
  );
}

/// Text field styled to match the app.
class AppTextField extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  const AppTextField({
    required this.hint,
    this.icon,
    this.obscure = false,
    this.suffix,
    this.maxLines = 1,
    this.controller,
    this.keyboardType,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      cursorColor: c.accent,
      decoration: InputDecoration(
        filled: true,
        fillColor: c.surfaceAlt,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: c.textSecondary, size: 20),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: TextStyle(color: c.textSecondary, fontSize: 13.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(c.accent, 1.5),
      ),
    );
  }
}

/// Selectable chip used for categories and filters.
class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  const SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final tint = color ?? c.accent;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? tint : c.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: selected ? tint : c.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : c.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : c.textSecondary,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase label above a group of fields.
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: c.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
