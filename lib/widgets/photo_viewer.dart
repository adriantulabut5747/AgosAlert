import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'common.dart';

/// ============================================================
/// PHOTO VIEWER — a report photo full screen, Messenger style
/// ============================================================
/// Black backdrop, the photo fit to the screen, a top bar with x, who
/// posted it and when, and zoom out / zoom in. Pinch or the mouse wheel
/// zooms around the fingers / pointer, double-tap (or double-click) zooms
/// in on that spot and back out, drag pans while zoomed, and dragging the
/// photo down (not zoomed) closes it while the black fades. Esc closes.
/// The Laravel site has the same viewer (partials/photo-viewer.blade.php):
/// change both together.
Future<void> openPhotoViewer(
  BuildContext context, {
  required String url,
  required Object heroTag,
  String title = '',
  String subtitle = '',
}) {
  HapticFeedback.selectionClick();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => _PhotoViewer(
        url: url,
        heroTag: heroTag,
        title: title,
        subtitle: subtitle,
      ),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _PhotoViewer extends StatefulWidget {
  final String url, title, subtitle;
  final Object heroTag;
  const _PhotoViewer({
    required this.url,
    required this.heroTag,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer>
    with SingleTickerProviderStateMixin {
  static const _maxScale = 5.0;
  final _tc = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addListener(() => _tc.value = _tween!.evaluate(_curve));
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _anim,
    curve: kSnappyCurve,
  );
  Matrix4Tween? _tween;
  Offset _doubleTapAt = Offset.zero;
  double _drag = 0; // how far the (unzoomed) photo is dragged down
  int _fingers = 0;

  double get _scale => _tc.value.getMaxScaleOnAxis();

  @override
  void initState() {
    super.initState();
    // Rebuild when the zoom crosses 1 (panning on / off, buttons enabled).
    _tc.addListener(() {
      final zoomed = _scale > 1.01;
      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    });
  }

  bool _zoomed = false;

  @override
  void dispose() {
    _anim.dispose();
    _tc.dispose();
    super.dispose();
  }

  // Zoom to [target], keeping the screen point [at] where it is.
  void _zoomTo(double target, Offset at) {
    target = target.clamp(1.0, _maxScale);
    final k = target / _scale;
    // Back at 1x = no zoom, no pan. Otherwise scale around [at] on top of
    // the current zoom (parenthesized: a bare `..multiply` would apply to
    // the whole `? :` and undo the reset).
    final end = target <= 1.0
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(at.dx, at.dy, 0, 1)
            ..scaleByDouble(k, k, 1, 1)
            ..translateByDouble(-at.dx, -at.dy, 0, 1)
            ..multiply(_tc.value));
    _tween = Matrix4Tween(begin: _tc.value, end: end);
    _anim.forward(from: 0);
  }

  Offset get _center => MediaQuery.sizeOf(context).center(Offset.zero);

  @override
  Widget build(BuildContext context) {
    final fade = (1 - _drag.abs() / 400).clamp(0.2, 1.0);
    return Material(
      type: MaterialType.transparency,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
          const SingleActivator(LogicalKeyboardKey.equal): () =>
              _zoomTo(_scale * 1.6, _center),
          const SingleActivator(LogicalKeyboardKey.minus): () =>
              _zoomTo(_scale / 1.6, _center),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black.withValues(alpha: fade)),
              GestureDetector(
                onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
                onDoubleTap: () => _zoomTo(_zoomed ? 1 : 2.5, _doubleTapAt),
                child: Transform.translate(
                  offset: Offset(0, _drag),
                  child: InteractiveViewer(
                    transformationController: _tc,
                    minScale: 1,
                    maxScale: _maxScale,
                    // Mouse wheel speed, same as the Laravel viewer (exp(-dy / 450)).
                    scaleFactor: 450,
                    // Not zoomed: a one-finger drag is the drag-to-close below.
                    panEnabled: _zoomed,
                    onInteractionStart: (d) {
                      _anim.stop();
                      _fingers = d.pointerCount;
                    },
                    onInteractionUpdate: (d) {
                      if (!_zoomed && _fingers == 1 && d.pointerCount == 1) {
                        setState(() => _drag += d.focalPointDelta.dy);
                      }
                    },
                    onInteractionEnd: (_) {
                      if (_drag.abs() > 120) {
                        Navigator.of(context).maybePop();
                      } else if (_drag != 0) {
                        setState(() => _drag = 0);
                      }
                    },
                    child: Center(
                      child: Hero(
                        tag: widget.heroTag,
                        child: Image.network(
                          widget.url,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => Icon(
                            CupertinoIcons.photo,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The top bar, on a soft dark fade so it reads over bright photos.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: IgnorePointer(
                  ignoring: _drag != 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _drag == 0 ? 1 : 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x99000000), Color(0x00000000)],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                          child: Row(
                            children: [
                              _button(
                                CupertinoIcons.xmark,
                                'Close',
                                () => Navigator.of(context).maybePop(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: _who()),
                              _button(
                                CupertinoIcons.zoom_out,
                                'Zoom out',
                                _zoomed
                                    ? () => _zoomTo(_scale / 1.6, _center)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              _button(
                                CupertinoIcons.zoom_in,
                                'Zoom in',
                                _scale < _maxScale - 0.01
                                    ? () => _zoomTo(_scale * 1.6, _center)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _who() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (widget.title.isNotEmpty)
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      if (widget.subtitle.isNotEmpty)
        Text(
          widget.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            decoration: TextDecoration.none,
          ),
        ),
    ],
  );

  Widget _button(IconData icon, String tip, VoidCallback? onTap) => Tooltip(
    message: tip,
    child: Semantics(
      button: true,
      label: tip,
      enabled: onTap != null,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
      ),
    ),
  );
}
