import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo_data.dart';
import '../services/centers.dart';
import '../services/rescue.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';
import '../widgets/check_in.dart';
import '../widgets/links.dart';
import '../widgets/tugak.dart';
import 'evacuation_centers_screen.dart';
import '../widgets/agos_icons.dart';

/// The Hotlines list on Help: everything but 911, which is the SOS button.
final _localHotlines = kHotlines.where((h) => h.number != '911').toList();

/// ============================================================
/// HELP TAB (file name kept from when it was "Assistance")
/// ============================================================
/// Two parts only:
/// 1. Need help now: one card with the SOS button (hold = call 911), one-tap
///    the local hotlines (911 = SOS), I'm safe, Request rescue; then the
///    nearest open shelter.
/// 2. Be ready: tips Before / During / After, with the go-bag checklist
///    inside Before (that's when you pack it).
class AssistanceTab extends StatefulWidget {
  const AssistanceTab({super.key});

  @override
  State<AssistanceTab> createState() => _AssistanceTabState();
}

class _AssistanceTabState extends State<AssistanceTab> {
  // Go-bag items the user has ticked, saved by NAME (not position), so
  // reordering kGoBagItems later doesn't tick the wrong ones.
  Set<String> _packed = {};
  static const _packedKey = 'go_bag_packed';

  // Which part of the flood timeline is open: 0 Before, 1 During, 2 After.
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    _loadPacked();
  }

  // The browser keeps the ticks (shared_preferences = localStorage on web),
  // so they survive a reload. Until Supabase, they stay on this device.
  Future<void> _loadPacked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_packedKey);
      if (saved != null && mounted) setState(() => _packed = saved.toSet());
    } catch (_) {
      // Storage blocked (e.g. some private windows): ticks just aren't saved.
    }
  }

  Future<void> _togglePacked(String item) async {
    setState(
      () => _packed.contains(item) ? _packed.remove(item) : _packed.add(item),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_packedKey, _packed.toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    // Phones and tablets (Nov 14 2026, Adrian): a compact SOS card, and
    // every hotline and shelter listed right away (no "All" tap).
    final desktop = screenSizeOf(context) == ScreenSize.desktop;
    final emergency = _emergency(context, c, compact: !desktop);
    final hotlines = _hotlines(context, c, all: !desktop);
    // Rebuilds when an admin changes a center or the user picks a barangay.
    final shelter = ListenableBuilder(
      listenable: Listenable.merge([evacCenters, myBarangay]),
      builder: (context, _) => _nearestShelter(context, c, all: !desktop),
    );
    final note = Text(
      'Hotline numbers are from Mabalacat City government channels. Check them locally before you rely on them.',
      style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.45),
    );
    const header = PageHeader(
      'Help',
      subtitle: 'Get help fast, and be ready before the rain',
    );
    // Desktop: two full-width bands, so nothing ends up lopsided.
    // Band 1: SOS (left) and hotlines + shelter (right), stretched to the
    // same height. Band 2: Be ready across the whole width.
    if (desktop) {
      return ListView(
        padding: pagePadding(context),
        children: [
          header,
          const SizedBox(height: 28),
          const MyRescueCard(),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 28,
              children: [
                Expanded(child: emergency),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      hotlines,
                      const SizedBox(height: 24),
                      shelter,
                      const Spacer(),
                      const SizedBox(height: 16),
                      note,
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _beReady(c, wide: true),
        ],
      );
    }
    return ListView(
      padding: pagePadding(context),
      children: [
        header,
        const SizedBox(height: 16),
        emergency,
        const SizedBox(height: 22),
        const MyRescueCard(),
        hotlines,
        const SizedBox(height: 22),
        shelter,
        const SizedBox(height: 26),
        _beReady(c),
        const SizedBox(height: 20),
        note,
      ],
    );
  }

  // The focal point of the page: the SOS button, alone and centered. It is
  // the only strong color here, so the eye lands on it first.
  // [compact] (phones, tablets): the button beside its caption, not above.
  Widget _emergency(BuildContext context, AppColors c, {bool compact = false}) {
    final sos = kHotlines.first; // 911
    return AppCard(
      padding: compact
          ? const EdgeInsets.fromLTRB(14, 12, 14, 14)
          : const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SosButton(
            number: sos.number,
            compact: compact,
            onHeld: () => callNumber(context, sos.number),
            onActivated: () => confirmCall(
              context,
              name: sos.name,
              number: sos.number,
              color: sos.color,
            ),
          ),
          SizedBox(height: compact ? 10 : 22),
          Divider(height: 1, color: c.border),
          SizedBox(height: compact ? 12 : 16),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _pill(
                  c,
                  CupertinoIcons.checkmark_shield_fill,
                  'I\'m safe',
                  kSafe,
                  () => showImSafe(context),
                ),
              ),
              Expanded(
                child: _pill(
                  c,
                  AgosIcons.boat,
                  'Request rescue',
                  c.textPrimary,
                  () => rescueSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(
    AppColors c,
    IconData icon,
    String label,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop: CDRRMO and Police one tap away, the rest behind "All".
  // [all] (phones, tablets): every hotline, no extra tap.
  Widget _hotlines(BuildContext context, AppColors c, {bool all = false}) {
    final quick = all
        ? _localHotlines
        : _localHotlines
              .where((h) => h.short == 'CDRRMO' || h.short == 'Police')
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        all
            ? const SectionHeader('Hotlines')
            : SectionHeader(
                'Hotlines',
                actionLabel: 'All ${_localHotlines.length}',
                onAction: () => _allHotlines(context),
              ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < quick.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 52, color: c.border),
                _hotlineRow(
                  c,
                  quick[i],
                  () => confirmCall(
                    context,
                    name: quick[i].name,
                    number: quick[i].number,
                    color: quick[i].color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Every hotline, in a sheet. Tapping one closes the sheet, then asks
  // before calling (so the two popups don't stack).
  void _allHotlines(BuildContext context) {
    showAppSheet(
      context,
      builder: (sheet) {
        final c = AppColors(sheet);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hotlines',
              style: TextStyle(
                fontFamily: kDisplayFont,
                color: c.textPrimary,
                fontSize: 22,
                letterSpacing: displayTracking(22),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a number to call. We ask first.',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < _localHotlines.length; i++) ...[
              if (i > 0) Divider(height: 1, indent: 52, color: c.border),
              _hotlineRow(c, _localHotlines[i], () {
                Navigator.of(sheet).pop();
                confirmCall(
                  context,
                  name: _localHotlines[i].name,
                  number: _localHotlines[i].number,
                  color: _localHotlines[i].color,
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _hotlineRow(AppColors c, Hotline h, VoidCallback onTap) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // makes the whole row tappable
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _Glyph(h.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    h.number,
                    style: TextStyle(color: c.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.phone_fill, color: c.accent, size: 19),
          ],
        ),
      ),
    );
  }

  // Desktop: the closest OPEN evacuation center, as one compact row.
  // [all] (phones, tablets): every center, open ones nearest first.
  Widget _nearestShelter(
    BuildContext context,
    AppColors c, {
    bool all = false,
  }) {
    final list = sortedCenters(evacCenters.value);
    final e = list.where((e) => e.open).firstOrNull;
    if (all) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            'Evacuation centers',
            badge: centersAreSample ? const SampleBadge() : null,
            actionLabel: 'Details',
            onAction: () =>
                Navigator.of(context)
                    .push(slideRoute(const EvacuationCentersScreen())),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < list.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 52, color: c.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _shelterRow(context, c, list[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          myBarangay.value == null ? 'Open shelter' : 'Nearest open shelter',
          badge: centersAreSample ? const SampleBadge() : null,
          actionLabel: 'All centers',
          onAction: () =>
              Navigator.of(context)
                  .push(slideRoute(const EvacuationCentersScreen())),
        ),
        if (e == null)
          Text(
            'No evacuation center is open right now.',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          )
        else
          AppCard(
            padding: const EdgeInsets.all(16),
            child: _shelterRow(context, c, e),
          ),
      ],
    );
  }

  // One center: icon, name, barangay + open/closed, and Directions (open
  // ones only).
  Widget _shelterRow(BuildContext context, AppColors c, EvacuationCenter e) {
    return Row(
      children: [
        _Glyph(e.icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.name,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                [
                  'Brgy. ${e.barangay}',
                  e.statusLabel,
                  if (e.distanceLabel.isNotEmpty) e.distanceLabel,
                ].join(' · '),
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        if (e.open) ...[
          const SizedBox(width: 10),
          PressableScale(
            onTap: () => openDirections(context, e.point),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.arrow_up_right_diamond_fill,
                    color: c.accent,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Directions',
                    style: TextStyle(
                      color: c.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Be ready: a Before → During → After timeline. Each step shows its tips,
  // plus one extra: the go-bag (Before) and the water-depth diagram (During).
  // [wide] (desktop): tips side by side, go-bag items in 3 columns.
  Widget _beReady(AppColors c, {bool wide = false}) {
    final (_, tips) = kSafetyPhases[_phase];
    Widget tip(SafetyTip t) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Glyph(t.icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.body,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final tipsCard = wide
        ? AppCard(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < tips.length; i++) ...[
                    if (i > 0) VerticalDivider(width: 1, color: c.border),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: tip(tips[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        : AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < tips.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 52, color: c.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: tip(tips[i]),
                  ),
                ],
              ],
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Be ready'),
        const TugakBeside(
          pose: 'handset',
          line: "Do the Before list today, while it's dry. Once the water rises, there's no time to read.",
        ),
        const SizedBox(height: 16),
        _PhaseTimeline(
          selected: _phase,
          onSelect: (i) => setState(() => _phase = i),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: Column(
            key: ValueKey(_phase),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tipsCard,
              if (_phase == 0) ...[
                const SizedBox(height: 14),
                _goBag(c, wide: wide),
              ],
              if (_phase == 1) ...[
                const SizedBox(height: 14),
                const _DepthDiagram(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _goBag(AppColors c, {bool wide = false}) {
    final done = kGoBagItems.where((i) => _packed.contains(i.$1)).length;
    final total = kGoBagItems.length;
    final ready = done == total;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ready ? 'Your go-bag is ready' : 'Pack a go-bag',
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: displayTracking(17),
                  ),
                ),
              ),
              Text(
                '$done/$total',
                style: TextStyle(
                  color: ready ? kSafe : c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Keep it by the door. Ticks are saved on this device.',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          // One segment per item: you see what's left at a glance.
          Row(
            spacing: 4,
            children: [
              for (var i = 0; i < total; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < done
                          ? (ready ? kSafe : c.accent)
                          : c.surfaceAlt,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (wide)
            // 3 columns, filled row by row.
            for (var r = 0; r < total; r += 3)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  for (var i = r; i < r + 3; i++)
                    Expanded(
                      child: i < total
                          ? _checkRow(
                              c,
                              kGoBagItems[i].$1,
                              kGoBagItems[i].$2,
                              _packed.contains(kGoBagItems[i].$1),
                            )
                          : const SizedBox(),
                    ),
                ],
              )
          else
            for (final (item, note) in kGoBagItems)
              _checkRow(c, item, note, _packed.contains(item)),
        ],
      ),
    );
  }

  Widget _checkRow(AppColors c, String item, String note, bool packed) {
    return Semantics(
      checked: packed,
      child: PressableScale(
        onTap: () => _togglePacked(item),
        child: Container(
          color: Colors.transparent, // whole row is tappable
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: packed ? c.accent : Colors.transparent,
                  border: packed
                      ? null
                      : Border.all(color: c.textSecondary, width: 1.5),
                ),
                child: packed
                    ? const Icon(
                        CupertinoIcons.checkmark,
                        color: Colors.white,
                        size: 13,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item,
                      style: TextStyle(
                        color: packed ? c.textSecondary : c.textPrimary,
                        decoration: packed ? TextDecoration.lineThrough : null,
                        decorationColor: c.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (note.isNotEmpty)
                      Text(
                        note,
                        style: TextStyle(color: c.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One neutral icon tile, used for every list icon on this page. Same color
/// everywhere on purpose: color is kept for SOS (red) and "I'm safe" (green).
class _Glyph extends StatelessWidget {
  final IconData icon;
  const _Glyph(this.icon);

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: c.textPrimary.withValues(alpha: 0.8), size: 18),
    );
  }
}

/// Before → During → After as a timeline: three dots on a line, the line
/// filled up to the open step. Tap a step to open it.
class _PhaseTimeline extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _PhaseTimeline({required this.selected, required this.onSelect});

  // What each step means, in one line.
  static const _hints = [
    'Rain is on the way',
    'Water is rising',
    'Water is going down',
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final n = kSafetyPhases.length;
    return LayoutBuilder(
      builder: (context, box) {
        // Dot centers sit in the middle of each third of the width.
        final step = box.maxWidth / n;
        return Stack(
          children: [
            // The track, then the filled part up to the open step.
            Positioned(
              left: step / 2,
              right: step / 2,
              top: 10,
              child: Container(height: 2, color: c.border),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              left: step / 2,
              width: step * selected,
              top: 10,
              child: Container(height: 2, color: c.accent),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == selected,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(i),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Column(
                            children: [
                              _dot(c, i),
                              const SizedBox(height: 10),
                              Text(
                                kSafetyPhases[i].$1,
                                style: TextStyle(
                                  color: i == selected
                                      ? c.textPrimary
                                      : c.textSecondary,
                                  fontSize: 15,
                                  fontWeight: i == selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _hints[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: c.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _dot(AppColors c, int i) {
    final open = i == selected;
    final passed = i < selected;
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: open ? 22 : 12,
          height: open ? 22 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: open || passed ? c.accent : c.background,
            border: open || passed
                ? null
                : Border.all(color: c.textSecondary, width: 1.5),
            boxShadow: open
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.25),
                      blurRadius: 0,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: open
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// How little MOVING water it takes: three tanks filled to 15, 30 and
/// 60 cm, on the same scale. Figures from the US National Weather
/// Service's "Turn Around, Don't Drown" safety campaign.
class _DepthDiagram extends StatelessWidget {
  const _DepthDiagram();

  static const _scaleCm = 75.0; // a full tank
  static const _levels = [
    (15, '6 in', 'Can knock an adult off their feet'),
    (30, '1 ft', 'Can carry away most cars'),
    (60, '2 ft', 'Can carry away SUVs and trucks'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moving water is stronger than it looks',
            style: TextStyle(
              fontFamily: kDisplayFont,
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: displayTracking(17),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'If it is flowing, don\'t walk or drive through it.',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              for (final (cm, imperial, what) in _levels)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tank(c, cm),
                      const SizedBox(height: 10),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$cm cm',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text: '  $imperial',
                              style: TextStyle(color: c.textSecondary),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        what,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Source: US National Weather Service, "Turn Around, Don\'t Drown"',
            style: TextStyle(color: c.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // A tank on a shared scale, the water rising to [cm] when it first shows.
  Widget _tank(AppColors c, int cm) {
    const height = 96.0;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.bottomCenter,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: cm / _scaleCm),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Container(
          height: height * v,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.28),
            border: Border(top: BorderSide(color: c.accent, width: 2)),
          ),
        ),
      ),
    );
  }
}

// ----- Sheets -----

void rescueSheet(BuildContext context) {
  final name = TextEditingController(text: defaultContactName);
  final phone = TextEditingController(text: defaultContactPhone);
  final note = TextEditingController();
  String? barangay = myBarangay.value;
  int people = 1;
  final needs = <String>{};
  LatLng? spot;
  var locating = false;
  var busy = false;
  String? error;
  showAppSheet(
    context,
    builder: (sheet) {
      return StatefulBuilder(
        builder: (sheet, setSheet) {
          final c = AppColors(sheet);

          Future<void> locate() async {
            setSheet(() {
              locating = true;
              error = null;
            });
            try {
              var perm = await Geolocator.checkPermission();
              if (perm == LocationPermission.denied) {
                perm = await Geolocator.requestPermission();
              }
              if (perm == LocationPermission.denied ||
                  perm == LocationPermission.deniedForever) {
                error = 'Location is blocked. Your barangay is enough.';
                return;
              }
              final pos = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 15),
                ),
              );
              final p = LatLng(pos.latitude, pos.longitude);
              final inCity =
                  p.latitude >= kCityBounds.south &&
                  p.latitude <= kCityBounds.north &&
                  p.longitude >= kCityBounds.west &&
                  p.longitude <= kCityBounds.east;
              if (inCity) {
                spot = p;
              } else {
                error = 'You seem to be outside Mabalacat. Your barangay is enough.';
              }
            } catch (_) {
              error = "Couldn't get your location. Your barangay is enough.";
            } finally {
              if (sheet.mounted) setSheet(() => locating = false);
            }
          }

          Future<void> send() async {
            final missing = name.text.trim().isEmpty
                ? 'Type the name of the person to contact.'
                : !isValidPhone(phone.text)
                ? 'Type a phone number the admins can call, like 0917 123 4567.'
                : barangay == null
                ? 'Pick the barangay where help is needed.'
                : null;
            if (missing != null) return setSheet(() => error = missing);
            setSheet(() {
              busy = true;
              error = null;
            });
            try {
              final id = await sendRescueRequest(
                contactName: name.text,
                contactPhone: phone.text,
                barangay: barangay!,
                point: spot,
                peopleCount: people,
                specialNeeds: needs,
                note: note.text,
              );
              if (!sheet.mounted) return;
              Navigator.of(sheet).pop();
              if (context.mounted) {
                showSuccessDialog(
                  context,
                  title: 'Request #$id saved',
                  message: 'This is a demo: no one is watching these requests yet, so no rescuer is coming. If you\'re in danger, call 911 now.\n\nYou can follow its status in the Help tab.',
                );
              }
            } catch (e) {
              setSheet(() {
                busy = false;
                // The paper's alternative flow: sending failed -> call.
                error = '$e'.contains('too_many_requests')
                    ? 'This number already sent 3 requests in 10 minutes. Call 911 or a hotline now.'
                    : 'Couldn\'t send it. Call 911 or a hotline now.';
              });
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBadge(
                    AgosIcons.boat,
                    kDanger,
                    size: 48,
                    squircle: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Request rescue',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Nov 19 2026: requests are saved, but nobody watches them
              // yet. Keep this until real responders use the Admin page.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kDanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kDanger.withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo only: no rescuer will come',
                      style: TextStyle(
                        color: c.readable(kDanger),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AgosAlert is a school project. Requests are saved, but no one is watching them yet. If you\'re in danger, call 911 now.',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TintedButton(
                      label: 'Call 911',
                      icon: CupertinoIcons.phone_fill,
                      onPressed: () => confirmCall(
                        context,
                        name: 'Emergency',
                        number: '911',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const FieldLabel('Who should the admins call?'),
              AppTextField(
                hint: 'Full name',
                icon: CupertinoIcons.person,
                controller: name,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              AppTextField(
                hint: 'Phone number',
                icon: CupertinoIcons.phone,
                controller: phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              const FieldLabel('Where is help needed?'),
              BarangayDropdown(
                value: barangay,
                onChanged: (v) => setSheet(() => barangay = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spot == null
                          ? 'Exact location not shared'
                          : 'Your location will be sent',
                      style: TextStyle(color: c.textSecondary, fontSize: 13),
                    ),
                  ),
                  TintedButton(
                    label: spot == null
                        ? (locating ? 'Finding you...' : 'Share my location')
                        : 'Shared',
                    icon: spot == null
                        ? CupertinoIcons.location_fill
                        : CupertinoIcons.checkmark_alt,
                    onPressed: spot != null || locating ? null : locate,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const FieldLabel('How many people?'),
              Row(
                children: [
                  _stepButton(
                    c,
                    CupertinoIcons.minus,
                    people > 1 ? () => setSheet(() => people--) : null,
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '$people',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _stepButton(
                    c,
                    CupertinoIcons.plus,
                    people < 99 ? () => setSheet(() => people++) : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const FieldLabel('Anyone who needs extra help?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final MapEntry(:key, :value) in kRescueNeeds.entries)
                    SelectChip(
                      label: value,
                      selected: needs.contains(key),
                      color: kDanger,
                      onTap: () => setSheet(
                        () => needs.contains(key)
                            ? needs.remove(key)
                            : needs.add(key),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const FieldLabel('Notes (optional)'),
              AppTextField(
                hint: 'e.g. We are on the 2nd floor, water is rising',
                controller: note,
                maxLines: 2,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: TextStyle(
                    color: c.readable(kDanger),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Send rescue request',
                icon: CupertinoIcons.paperplane_fill,
                color: kDanger,
                loading: busy,
                onPressed: send,
              ),
              const SizedBox(height: 8),
              Text(
                'The name, number, place and needs go to AgosAlert\'s admins. See the Privacy Policy.',
                style: TextStyle(color: c.textSecondary, fontSize: 11),
              ),
            ],
          );
        },
      );
    },
  );
}

/// The status of the rescue request this device sent last (FR-G9), at
/// the top of Help. Nothing when there's none.
class MyRescueCard extends StatelessWidget {
  const MyRescueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: myRescue,
      builder: (context, r, _) {
        if (r == null) return const SizedBox.shrink();
        final c = AppColors(context);
        final color = switch (r.status) {
          'resolved' => kSafe,
          'flagged_false' => kGray,
          _ => kDanger,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconBadge(AgosIcons.boat, color, size: 40, squircle: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rescue request #${r.requestId}: ${r.statusLabel}',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.active
                            ? 'Demo: no one is watching yet. In danger? Call 911.'
                            : 'Updated ${timeAgo(DateTime.now().difference(r.updatedAt)).toLowerCase()}',
                        style: TextStyle(color: c.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (!r.active)
                  TintedButton(label: 'Dismiss', onPressed: forgetMyRescue),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _stepButton(AppColors c, IconData icon, VoidCallback? onTap) {
  return PressableScale(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: onTap == null ? c.surfaceAlt : c.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: onTap == null ? c.textSecondary : c.accent,
        size: 22,
      ),
    ),
  );
}

/// The big red press-and-hold SOS button (holding avoids accidental taps),
/// with its caption. Screen readers get a plain button instead: tapping
/// it still asks before calling.
class _SosButton extends StatefulWidget {
  final String number;
  // The full hold: dials right away (holding is the confirmation).
  final VoidCallback onHeld;
  // A screen reader's plain tap: asks first.
  final VoidCallback onActivated;
  // phones: a smaller button with its caption to the right
  final bool compact;
  const _SosButton({
    required this.number,
    required this.onHeld,
    required this.onActivated,
    this.compact = false,
  });

  @override
  State<_SosButton> createState() => _SosButtonState();
}

// TickerProviderStateMixin (not "Single..."): this widget has TWO
// animation controllers, and the Single version only allows one.
class _SosButtonState extends State<_SosButton> with TickerProviderStateMixin {
  // How far the hold has got: 0.0 = not pressed, 1.0 = held for the full
  // 1.4 seconds. Reaching the end resets the ring and fires onHeld.
  late final AnimationController _hold =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _hold.reset();
          widget.onHeld();
        }
      });
  // The soft ripples around the button, looping.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _hold.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    // "Reduce motion" turned on: no ripples.
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_hold, _pulse]),
      builder: (context, _) {
        final holding = _hold.value > 0;
        final k = widget.compact;
        final box = k ? 108.0 : 176.0, btn = k ? 80.0 : 116.0;
        final ring = k ? 96.0 : 140.0, grow = k ? 28.0 : 60.0;
        final button = Semantics(
          button: true,
          label: 'SOS, call ${widget.number}',
          onTap: widget.onActivated,
          excludeSemantics: true,
          // Press = the ring fills (forward). Let go early, or slide
          // off = it drains back (reverse) and nothing happens.
          child: GestureDetector(
            onTapDown: (_) => _hold.forward(),
            onTapUp: (_) => _hold.reverse(),
            onTapCancel: () => _hold.reverse(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SizedBox(
                width: box,
                height: box,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Two ripples half a loop apart, growing from the
                    // button's edge outwards while fading.
                    if (!still && !holding)
                      for (final offset in [0.0, 0.5])
                        Builder(
                          builder: (context) {
                            final t = (_pulse.value + offset) % 1;
                            return Container(
                              width: btn + grow * t,
                              height: btn + grow * t,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kDanger.withValues(
                                  alpha: 0.12 * (1 - t),
                                ),
                              ),
                            );
                          },
                        ),
                    // The ring that fills while holding.
                    SizedBox(
                      width: ring,
                      height: ring,
                      child: CircularProgressIndicator(
                        value: _hold.value,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        color: kDanger,
                        backgroundColor: holding
                            ? kDanger.withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
                    ),
                    // The button sinks in (up to 6%) the longer it's
                    // held, like pressing a real button.
                    Transform.scale(
                      scale: 1 - _hold.value * 0.06,
                      child: Container(
                        width: btn,
                        height: btn,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Lit from the top, like the rest of the app.
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFEE5A5A), Color(0xFFD23C3C)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD23C3C)
                                  .withValues(alpha: c.isDark ? 0.35 : 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            fontFamily: kDisplayFont,
                            color: Colors.white,
                            fontSize: k ? 22 : 28,
                            letterSpacing: 1, // all caps: open it up
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final title = Text(
          holding ? 'Keep holding…' : 'Hold to call ${widget.number}',
          style: TextStyle(
            fontFamily: kDisplayFont,
            color: c.textPrimary,
            fontSize: 20,
            letterSpacing: displayTracking(20),
            fontWeight: FontWeight.w700,
          ),
        );
        final caption = Text(
          'For danger to life. We ask before calling.',
          textAlign: k ? TextAlign.start : TextAlign.center,
          style: TextStyle(color: c.textSecondary, fontSize: 13),
        );
        if (k) {
          return Row(
            children: [
              button,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 3), caption],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            button,
            const SizedBox(height: 10),
            title,
            const SizedBox(height: 4),
            caption,
          ],
        );
      },
    );
  }
}
