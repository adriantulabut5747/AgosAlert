import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// ============================================================
/// ALERTS TAB — filterable alert feed with details
/// ============================================================
class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  AlertCategory? _filter; // null = all

  List<AppAlert> get _filtered => _filter == null
      ? kAlerts
      : kAlerts.where((a) => a.category == _filter).toList();

  void _markRead(AppAlert a) => readAlerts.value = {...readAlerts.value, a.id};

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return ValueListenableBuilder<Set<String>>(
      valueListenable: readAlerts,
      builder: (context, read, _) {
        final items = _filtered;
        final today = items.where((a) => a.ago.inHours < 24).toList();
        final earlier = items.where((a) => a.ago.inHours >= 24).toList();
        final critical = kAlerts
            .where((a) => a.severity == RiskLevel.high && !read.contains(a.id))
            .toList();
        final unread = unreadAlertCount;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            PageHeader(
              'Alerts',
              subtitle: unread == 0
                  ? 'You\'re all caught up'
                  : '$unread unread · Mabalacat City',
              trailing: unread == 0
                  ? null
                  : TextButton.icon(
                      onPressed: () =>
                          readAlerts.value = kAlerts.map((a) => a.id).toSet(),
                      icon: Icon(
                        Icons.done_all_rounded,
                        size: 18,
                        color: c.accent,
                      ),
                      label: Text(
                        'Mark all read',
                        style: TextStyle(
                          color: c.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            if (critical.isNotEmpty) ...[
              FadeSlideIn(child: _criticalBanner(context, critical.first)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  SelectChip(
                    label: 'All  ${kAlerts.length}',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final cat in AlertCategory.values) ...[
                    const SizedBox(width: 8),
                    SelectChip(
                      label:
                          '${cat.label}  ${kAlerts.where((a) => a.category == cat).length}',
                      icon: cat.icon,
                      selected: _filter == cat,
                      onTap: () => setState(() => _filter = cat),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty) _empty(c),
            if (today.isNotEmpty) ...[
              const SizedBox(height: 12),
              const FieldLabel('Today'),
              for (var i = 0; i < today.length; i++)
                FadeSlideIn(
                  delay: Duration(milliseconds: 50 * i),
                  child: _alertCard(context, c, today[i], read),
                ),
            ],
            if (earlier.isNotEmpty) ...[
              const SizedBox(height: 12),
              const FieldLabel('Earlier'),
              for (final a in earlier) _alertCard(context, c, a, read),
            ],
          ],
        );
      },
    );
  }

  Widget _criticalBanner(BuildContext context, AppAlert a) {
    return PressableScale(
      onTap: () => _openAlert(context, a),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kDanger.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedWaves(
                  height: 50,
                  colors: [Color(0x14FFFFFF), Color(0x1FFFFFFF)],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HIGH SEVERITY',
                            style: TextStyle(
                              color: Color(0xDDFFFFFF),
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
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

  Widget _alertCard(
    BuildContext context,
    AppColors c,
    AppAlert a,
    Set<String> read,
  ) {
    final unread = !read.contains(a.id);
    final color = a.severity.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => _openAlert(context, a),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity stripe
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(
                        a.category.icon,
                        color,
                        size: 42,
                        squircle: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontWeight: unread
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (unread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: c.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              a.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                StatusPill(a.severity.label, color),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${a.area} · ${timeAgo(a.ago)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          IconBadge(
            Icons.notifications_off_outlined,
            c.textSecondary,
            size: 72,
          ),
          const SizedBox(height: 14),
          Text(
            'No alerts here',
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'ll let you know when something comes up.',
            style: TextStyle(color: c.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  void _openAlert(BuildContext context, AppAlert a) {
    _markRead(a);
    final color = a.severity.color;
    showAppSheet(
      context,
      builder: (sheet) {
        final c = AppColors(sheet);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(a.category.icon, color, size: 52, squircle: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(
                        '${a.severity.label} · ${a.category.label}',
                        color,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _meta(c, Icons.place_outlined, a.area),
                _meta(c, Icons.schedule_rounded, timeAgo(a.ago)),
                _meta(c, Icons.verified_outlined, a.source),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              a.details,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            const FieldLabel('What to do'),
            for (var i = 0; i < a.actions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          a.actions[i],
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'View on map',
              icon: Icons.map_rounded,
              onPressed: () {
                Navigator.of(sheet).pop();
                HomeShell.of(context)?.switchTab(1);
              },
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: Text('Close', style: TextStyle(color: c.textSecondary)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _meta(AppColors c, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: c.textSecondary, fontSize: 12)),
      ],
    );
  }
}
