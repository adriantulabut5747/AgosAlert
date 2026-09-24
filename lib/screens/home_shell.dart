import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'alerts_tab.dart';
import 'assistance_tab.dart';
import 'home_tab.dart';
import 'map_tab.dart';
import 'more_tab.dart';

/// On wide screens (laptop browsers), keep the app phone-width and centered.
const double kMaxContentWidth = 560;

/// ============================================================
/// HOME SHELL — top bar + the five tabs + floating bottom nav
/// ============================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// Lets any tab switch tabs: `HomeShell.of(context)?.switchTab(1)`.
  static HomeShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Tabs are only built the first time they're opened (so, e.g., the map
  // doesn't download tiles until someone opens the Map tab). After that
  // they stay alive, so scroll position and filters are kept.
  final Set<int> _opened = {0};

  void switchTab(int index) => setState(() {
    _index = index;
    _opened.add(index);
  });

  static const _tabs = [
    HomeTab(),
    MapTab(),
    AlertsTab(),
    AssistanceTab(),
    MoreTab(),
  ];

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.map_outlined, Icons.map_rounded, 'Map'),
    (Icons.notifications_none_rounded, Icons.notifications_rounded, 'Alerts'),
    (Icons.support_outlined, Icons.support_rounded, 'Assistance'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'More'),
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: Column(
                children: [
                  _topBar(c),
                  Expanded(
                    child: Stack(
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          if (_opened.contains(i))
                            _TabLayer(
                              key: ValueKey(i),
                              active: i == _index,
                              child: _tabs[i],
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _bottomNav(c),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          // Wordmark logo; falls back to the old icon + text if it fails.
          AssetImageWithFallback(
            'assets/images/logo_wordmark.png',
            height: 28,
            fallback: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    gradient: kBrandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waves_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AGOSALERT',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<Set<String>>(
            valueListenable: readAlerts,
            builder: (context, _, _) => _roundButton(
              c,
              icon: Icons.notifications_none_rounded,
              tooltip: 'Alerts',
              badge: unreadAlertCount,
              onTap: () => switchTab(2),
            ),
          ),
          const SizedBox(width: 8),
          _roundButton(
            c,
            icon: c.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: c.isDark ? 'Switch to light mode' : 'Switch to dark mode',
            color: c.isDark ? kLogoYellow : kSkyBlue,
            onTap: () => themeNotifier.value = c.isDark
                ? ThemeMode.light
                : ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _roundButton(
    AppColors c, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    int badge = 0,
  }) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween(begin: 0.6, end: 1.0).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  color: color ?? c.textPrimary,
                  size: 21,
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: kDanger,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.gradientTop, width: 2),
                  ),
                  child: Text(
                    '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav(AppColors c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: c.isDark ? 0.55 : 0.75),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white,
            ),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  // Sliding highlight behind the selected tab
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    left: itemWidth * _index + 8,
                    top: 8,
                    bottom: 8,
                    width: itemWidth - 16,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kSkyBlue.withValues(alpha: 0.25),
                            kLogoCyan.withValues(alpha: 0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(child: _navItem(c, i)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _navItem(AppColors c, int i) {
    final selected = i == _index;
    final (outline, filled, label) = _items[i];
    final color = selected ? c.accent : c.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => switchTab(i),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.12 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      selected ? filled : outline,
                      color: color,
                      size: 23,
                    ),
                  ),
                  if (i == 2)
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: readAlerts,
                      builder: (context, _, _) => unreadAlertCount == 0
                          ? const SizedBox.shrink()
                          : Positioned(
                              top: -1,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: kDanger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab in the shell. The active tab fades and slides in; hidden tabs
/// are invisible, can't be tapped, and pause their animations.
class _TabLayer extends StatelessWidget {
  final bool active;
  final Widget child;
  const _TabLayer({required this.active, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 280);
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: duration,
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.02),
            duration: duration,
            curve: Curves.easeOutCubic,
            // Pause only the tab's own animations. TickerMode must stay
            // INSIDE the fade: wrapped around it, it also froze the
            // fade-out, so old tabs stayed visible on top of each other.
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      ),
    );
  }
}
