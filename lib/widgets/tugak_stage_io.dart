import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';
import 'tugak.dart';
import 'tugak_stage.dart';

/// Tugak's terrace outside the browser.
/// - Android / iOS (Nov 20 2026): the same three.js scene as the web app,
///   in a WebView showing web/tugak/stage.html from the live site, driven
///   with the same calls as tugak_stage_web.dart.
/// - Tests, desktop builds, no internet, no WebGL: his still picture with
///   his line. Tapping him gives a tip either way.
// shortcut: the scene loads from the live site (needs internet, like the
// weather does); bundle web/tugak/ into the app if it must work offline.
const _stageUrl =
    'https://adriantulabut5747.github.io/AgosAlert/app/tugak/stage.html';

class TugakStage extends StatefulWidget {
  final TugakWeather weather;
  final String line;
  final ValueChanged<StageTap>? onTap;
  final StageReserve? reserve; // the part the live readings cover
  const TugakStage({
    required this.weather,
    required this.line,
    this.onTap,
    this.reserve,
    super.key,
  });

  @override
  State<TugakStage> createState() => _TugakStageState();
}

class _TugakStageState extends State<TugakStage> {
  // Only phones have a WebView (tests run on the PC: still picture).
  final bool _live = Platform.isAndroid || Platform.isIOS;
  WebViewController? _web;
  bool _ready = false;
  bool _failed = false;
  String? _sentWeather, _sentLine;
  StageReserve? _sentReserve;
  bool? _sentActive, _sentVisible, _sentDark;

  @override
  void initState() {
    super.initState();
    if (_live) _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TugakStage old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _fail() {
    if (mounted) setState(() => _failed = true);
  }

  void _start() {
    final web = WebViewController();
    _web = web;
    web
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'Agos',
        onMessageReceived: (m) {
          if (m.message == 'ready') {
            if (mounted) setState(() => _ready = true);
            _sync();
          } else {
            _fail();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            final opts = jsonEncode({
              'dark': AppColors(context).isDark,
              'weather': widget.weather.toJson(),
              'reserve': ?widget.reserve?.toJson(),
            });
            // opts goes in as a JS string (create() parses the JSON itself).
            web
                .runJavaScript('start(${jsonEncode(opts)})')
                .catchError((_) => _fail());
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) _fail();
          },
        ),
      )
      ..loadRequest(Uri.parse(_stageUrl)).catchError((_) => _fail());
    // Slow network or a silent failure: don't leave him "typing" forever.
    Future.delayed(const Duration(seconds: 25), () {
      if (!_ready) _fail();
    });
  }

  void _js(String code) => _web?.runJavaScript(code).catchError((_) {});

  // Sends whatever changed since last time (only once the scene is up).
  void _sync() {
    if (!_ready || !mounted) return;
    final weather = jsonEncode(widget.weather.toJson());
    if (weather != _sentWeather) {
      _js('stage.setWeather(${jsonEncode(_sentWeather = weather)})');
    }
    if (widget.line != _sentLine) {
      _js('stage.say(${jsonEncode(_sentLine = widget.line)})');
    }
    final reserve = widget.reserve;
    if (reserve != null && reserve != _sentReserve) {
      _js(
        'stage.setReserve(${jsonEncode(jsonEncode((_sentReserve = reserve).toJson()))})',
      );
    }
    final dark = AppColors(context).isDark;
    if (dark != _sentDark) _js('stage.setTheme(${_sentDark = dark})');
    // Hidden tab or behind a popup: stop drawing (saves the battery).
    final visible = TickerMode.valuesOf(context).enabled;
    final active = ModalRoute.of(context)?.isCurrent ?? true;
    if (visible != _sentVisible || active != _sentActive) {
      _sentVisible = visible;
      _sentActive = active;
      _js('stage.setActive($active, $visible)');
    }
  }

  Future<void> _tap(Offset p, Size size) async {
    final web = _web;
    if (!_ready || web == null) return widget.onTap?.call(StageTap.tugak);
    // -1..1 across the stage, y up (three.js's way), like the web version.
    final x = p.dx / size.width * 2 - 1, y = -(p.dy / size.height * 2 - 1);
    try {
      final hit = await web.runJavaScriptReturningResult('stage.tap($x, $y)');
      if ('$hit'.contains('tugak')) widget.onTap?.call(StageTap.tugak);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final web = _web;
    return LayoutBuilder(
      builder: (context, box) => Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _ready ? 0 : 1,
            duration: const Duration(milliseconds: 600),
            child: TugakStill(
              weather: widget.weather,
              line: (_failed || !_live) ? widget.line : null,
              loading: _live && !_failed,
              reserve: widget.reserve,
            ),
          ),
          // The WebView never takes touches: a swipe over it must still
          // scroll the page. Taps come from the layer on top.
          if (web != null && !_failed)
            IgnorePointer(
              child: Opacity(
                opacity: _ready ? 1 : 0,
                child: WebViewWidget(controller: web),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (d) => _tap(d.localPosition, box.biggest),
          ),
        ],
      ),
    );
  }
}
