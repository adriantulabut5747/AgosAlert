import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/links.dart';
import 'evacuation_centers_screen.dart';
import 'deferred_screens.dart';

/// ============================================================
/// ASSISTANCE TAB — SOS, quick help, hotlines, go-bag checklist
/// ============================================================
class AssistanceTab extends StatefulWidget {
  const AssistanceTab({super.key});

  @override
  State<AssistanceTab> createState() => _AssistanceTabState();
}

class _AssistanceTabState extends State<AssistanceTab> {
  final Set<int> _packed = {};

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const PageHeader('Emergency help', subtitle: 'Help is one tap away'),
        const SizedBox(height: 18),
        FadeSlideIn(child: _SosCard(onActivated: () => _sosSheet(context))),
        const SizedBox(height: 26),
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: _quickHelp(context, c),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(
          delay: const Duration(milliseconds: 180),
          child: _hotlines(context, c),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(delay: const Duration(milliseconds: 240), child: _goBag(c)),
        const SizedBox(height: 18),
        Text(
          'Numbers sourced from Mabalacat City government channels. Verify locally before relying on them in an actual emergency.',
          style: TextStyle(color: c.textSecondary, fontSize: 11, height: 1.45),
        ),
      ],
    );
  }

  Widget _quickHelp(BuildContext context, AppColors c) {
    final items = [
      (
        Icons.sailing_rounded,
        'Request rescue',
        'Send your location',
        kDanger,
        () => _rescueSheet(context),
      ),
      (
        Icons.night_shelter_rounded,
        'Evacuation',
        'Find open centers',
        kSafe,
        () =>
            Navigator.of(context)
                .push(slideRoute(const EvacuationCentersScreen())),
      ),
      (
        Icons.campaign_rounded,
        'Report incident',
        'Flooding, blocked roads',
        const Color(0xFFF97316),
        () => openReportIncident(context),
      ),
      (
        Icons.person_search_rounded,
        'Missing person',
        'Report someone missing',
        const Color(0xFF8B5CF6),
        () => _missingSheet(context),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Quick help'),
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            for (final (icon, title, sub, color, onTap) in items)
              AppCard(
                onTap: onTap,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconBadge(icon, color, size: 42, squircle: true),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _hotlines(BuildContext context, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Hotline directory'),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < kHotlines.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 68, color: c.border),
                _hotlineRow(context, c, kHotlines[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _hotlineRow(BuildContext context, AppColors c, Hotline h) {
    return InkWell(
      onTap: () =>
          confirmCall(context, name: h.name, number: h.number, color: h.color),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconBadge(h.icon, h.color, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    h.number,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: kSafe.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded, color: kSafe, size: 19),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goBag(AppColors c) {
    final done = _packed.length;
    final total = kGoBagItems.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Go-bag checklist'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: done / total),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: v,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: c.surfaceAlt,
                            color: done == total ? kSafe : c.accent,
                          ),
                          Center(
                            child: Text(
                              '${(v * 100).round()}%',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          done == total ? 'You\'re ready!' : 'Pack your go-bag',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '$done of $total items packed',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < total; i++)
                CheckboxListTile(
                  value: _packed.contains(i),
                  onChanged: (v) =>
                      setState(() => v! ? _packed.add(i) : _packed.remove(i)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: kSafe,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(color: c.textSecondary, width: 1.5),
                  title: Text(
                    kGoBagItems[i].$1,
                    style: TextStyle(
                      color: _packed.contains(i)
                          ? c.textSecondary
                          : c.textPrimary,
                      decoration: _packed.contains(i)
                          ? TextDecoration.lineThrough
                          : null,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: kGoBagItems[i].$2.isEmpty
                      ? null
                      : Text(
                          kGoBagItems[i].$2,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ----- Sheets -----

  void _sosSheet(BuildContext context) {
    showAppSheet(
      context,
      builder: (sheet) {
        final c = AppColors(sheet);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency SOS',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Who do you need to reach?',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            for (final h in kHotlines.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    confirmCall(
                      context,
                      name: h.name,
                      number: h.number,
                      color: h.color,
                    );
                  },
                  child: Row(
                    children: [
                      IconBadge(h.icon, h.color, size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          h.name,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        h.number,
                        style: TextStyle(
                          color: h.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            GradientButton(
              label: 'Request rescue instead',
              icon: Icons.sailing_rounded,
              onPressed: () {
                Navigator.of(sheet).pop();
                _rescueSheet(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _rescueSheet(BuildContext context) {
    String barangay = 'Dau';
    int people = 1;
    final needs = <String>{};
    showAppSheet(
      context,
      builder: (sheet) {
        return StatefulBuilder(
          builder: (sheet, setSheet) {
            final c = AppColors(sheet);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconBadge(
                      Icons.sailing_rounded,
                      kDanger,
                      size: 48,
                      squircle: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request rescue',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Rescuers will come to your barangay',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const FieldLabel('Your barangay'),
                BarangayDropdown(
                  value: barangay,
                  onChanged: (v) => setSheet(() => barangay = v),
                ),
                const SizedBox(height: 16),
                const FieldLabel('How many people?'),
                Row(
                  children: [
                    _stepButton(
                      c,
                      Icons.remove_rounded,
                      people > 1 ? () => setSheet(() => people--) : null,
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '$people',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _stepButton(
                      c,
                      Icons.add_rounded,
                      people < 50 ? () => setSheet(() => people++) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const FieldLabel('Anyone who needs extra help?'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in [
                      'Elderly',
                      'PWD',
                      'Infant / child',
                      'Pregnant',
                      'Needs medical care',
                    ])
                      SelectChip(
                        label: n,
                        selected: needs.contains(n),
                        color: kDanger,
                        onTap: () => setSheet(
                          () => needs.contains(n)
                              ? needs.remove(n)
                              : needs.add(n),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const FieldLabel('Notes (optional)'),
                const AppTextField(
                  hint: 'e.g. We are on the 2nd floor, water is rising',
                  maxLines: 2,
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: 'Send rescue request',
                  icon: Icons.send_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                  ),
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    showSuccessDialog(
                      context,
                      title: 'Request sent (demo)',
                      message:
                          'In the full app, the Mabalacat CDRRMO would receive your request for $people ${people == 1 ? 'person' : 'people'} in Brgy. $barangay.\n\nNothing was actually sent. In a real emergency, call 911.',
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _missingSheet(BuildContext context) {
    String barangay = 'Poblacion';
    showAppSheet(
      context,
      builder: (sheet) {
        return StatefulBuilder(
          builder: (sheet, setSheet) {
            final c = AppColors(sheet);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report a missing person',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share details to help responders find them',
                  style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Full name'),
                const AppTextField(
                  hint: 'Juan Dela Cruz',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                const FieldLabel('Age'),
                const AppTextField(
                  hint: 'e.g. 12',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                const FieldLabel('Last seen in'),
                BarangayDropdown(
                  value: barangay,
                  onChanged: (v) => setSheet(() => barangay = v),
                ),
                const SizedBox(height: 14),
                const FieldLabel('Description'),
                const AppTextField(
                  hint: 'Clothes, height, where they were going…',
                  maxLines: 3,
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: 'Submit report',
                  icon: Icons.send_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  ),
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    showSuccessDialog(
                      context,
                      title: 'Report submitted (demo)',
                      message:
                          'In the full app, this would go to responders in Brgy. $barangay. Nothing was actually sent — contact the PNP directly.',
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _stepButton(AppColors c, IconData icon, VoidCallback? onTap) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null
              ? c.surfaceAlt
              : c.accent.withValues(alpha: 0.15),
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
}

/// Barangay picker used by the rescue, missing person and report forms.
class BarangayDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const BarangayDropdown({
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: c.surface,
          borderRadius: BorderRadius.circular(16),
          menuMaxHeight: 320,
          icon: Icon(Icons.expand_more_rounded, color: c.textSecondary),
          style: TextStyle(
            color: c.textPrimary,
            fontFamily: kFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: [
            for (final b in kBarangays)
              DropdownMenuItem(value: b, child: Text('Brgy. $b')),
          ],
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}

/// Big red press-and-hold SOS button (holding avoids accidental taps).
class _SosCard extends StatefulWidget {
  final VoidCallback onActivated;
  const _SosCard({required this.onActivated});

  @override
  State<_SosCard> createState() => _SosCardState();
}

class _SosCardState extends State<_SosCard> with TickerProviderStateMixin {
  late final AnimationController _hold =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _hold.reset();
          widget.onActivated();
        }
      });
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _hold.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kDanger.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In danger?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Press and hold the SOS button to call for help or request a rescue.',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTapDown: (_) => _hold.forward(),
            onTapUp: (_) => _hold.reverse(),
            onTapCancel: () => _hold.reverse(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SizedBox(
                width: 116,
                height: 116,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_hold, _pulse]),
                  builder: (context, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final offset in [0.0, 0.5])
                        Builder(
                          builder: (context) {
                            final t = (_pulse.value + offset) % 1;
                            return Container(
                              width: 76 + 40 * t,
                              height: 76 + 40 * t,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(
                                  alpha: 0.18 * (1 - t),
                                ),
                              ),
                            );
                          },
                        ),
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: CircularProgressIndicator(
                          value: _hold.value,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          color: Colors.white,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      Transform.scale(
                        scale: 1 - _hold.value * 0.08,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
    );
  }
}
