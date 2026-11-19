import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoActivityIndicator, CupertinoIcons, CupertinoSwitch;

import '../data/demo_data.dart' show shortDate;
import '../services/auth.dart';
import '../services/reports.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/agos_icons.dart';
import 'account.dart';

/// ============================================================
/// SETTINGS — appearance, notifications, location
/// ============================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _floodAlerts = true;
  bool _weatherAlerts = true;
  bool _community = true;
  bool _sound = true;
  bool _location = false;
  RiskLevel _minSeverity = RiskLevel.normal;
  String _barangay = 'Poblacion';

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return SubpageScaffold(
      title: 'Settings',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // Real (saved to the users row), unlike the preview toggles below.
              if (!isGuest) ...[
                const FieldLabel('Account'),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _row(
                        c,
                        CupertinoIcons.person_fill,
                        'Name',
                        me!.fullName,
                        () => editDisplayName(
                          context,
                          onSaved: () => setState(() {}),
                        ),
                      ),
                      _divider(c),
                      _row(
                        c,
                        CupertinoIcons.mail_solid,
                        'Email',
                        me!.email,
                        null,
                      ),
                      _divider(c),
                      _row(
                        c,
                        CupertinoIcons.lock_fill,
                        'Password',
                        'Change',
                        () => showChangePassword(context),
                      ),
                      _divider(c),
                      _row(
                        c,
                        CupertinoIcons.trash_fill,
                        'Trash',
                        null,
                        () => showTrash(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const FieldLabel('Appearance'),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) => Row(
                  children: [
                    for (final (m, icon, label) in [
                      (ThemeMode.light, CupertinoIcons.sun_max_fill, 'Light'),
                      (ThemeMode.dark, CupertinoIcons.moon_fill, 'Dark'),
                      (
                        ThemeMode.system,
                        CupertinoIcons.circle_lefthalf_fill,
                        'System',
                      ),
                    ]) ...[
                      if (m != ThemeMode.light) const SizedBox(width: 10),
                      Expanded(child: _themeOption(c, m, icon, label, mode)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const FieldLabel('Notifications'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _switch(
                      c,
                      AgosIcons.flood,
                      'Flood alerts',
                      'Water levels and flood warnings',
                      _floodAlerts,
                      (v) => setState(() => _floodAlerts = v),
                    ),
                    _divider(c),
                    _switch(
                      c,
                      CupertinoIcons.cloud_bolt_rain_fill,
                      'Weather advisories',
                      'Heavy rain and storms',
                      _weatherAlerts,
                      (v) => setState(() => _weatherAlerts = v),
                    ),
                    _divider(c),
                    _switch(
                      c,
                      CupertinoIcons.exclamationmark_bubble_fill,
                      'Community reports',
                      'Incidents reported near you',
                      _community,
                      (v) => setState(() => _community = v),
                    ),
                    _divider(c),
                    _switch(
                      c,
                      CupertinoIcons.speaker_2_fill,
                      'Alert sound',
                      'Play a sound for high alerts',
                      _sound,
                      (v) => setState(() => _sound = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const FieldLabel('Notify me about'),
              Row(
                children: [
                  for (final level in RiskLevel.values) ...[
                    if (level != RiskLevel.normal) const SizedBox(width: 8),
                    Expanded(
                      child: SelectChip(
                        label: switch (level) {
                          RiskLevel.normal => 'Everything',
                          RiskLevel.moderate => 'Moderate+',
                          RiskLevel.high => 'High only',
                        },
                        color: level.color,
                        selected: _minSeverity == level,
                        onTap: () => setState(() => _minSeverity = level),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const FieldLabel('Location'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _switch(
                  c,
                  CupertinoIcons.location_fill,
                  'Share my location',
                  'Helps rescuers find you faster',
                  _location,
                  (v) => setState(() => _location = v),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'My barangay',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              BarangayDropdown(
                value: _barangay,
                onChanged: (v) => setState(() => _barangay = v),
              ),
              const SizedBox(height: 20),
              Text(
                'Notifications, location and the barangay here are a preview '
                'and reset when the app reloads.',
                style: TextStyle(color: c.textSecondary, fontSize: 11),
              ),
              if (!isGuest) ...[
                const SizedBox(height: 24),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _row(
                    c,
                    CupertinoIcons.trash_fill,
                    'Delete account',
                    null,
                    () => confirmDeleteAccount(context),
                    danger: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeOption(
    AppColors c,
    ThemeMode m,
    IconData icon,
    String label,
    ThemeMode current,
  ) {
    final selected = m == current;
    return PressableScale(
      onTap: () => themeNotifier.value = m,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? c.inverse : c.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? Colors.transparent : c.border),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? c.onInverse : c.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? c.onInverse : c.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // An iOS Settings row: icon tile, title, value on the right, and a
  // chevron when it opens something.
  Widget _row(
    AppColors c,
    IconData icon,
    String title,
    String? value,
    VoidCallback? onTap, {
    bool danger = false,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconBadge(
              icon,
              danger ? kDanger : c.accent,
              size: 36,
              squircle: true,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: danger ? kDanger : c.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? '',
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.textSecondary, fontSize: 15),
              ),
            ),
            if (onTap != null && !danger) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: c.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider(AppColors c) =>
      Divider(height: 1, indent: 64, color: c.border);

  Widget _switch(
    AppColors c,
    IconData icon,
    String title,
    String sub,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    // An iOS Settings row: icon tile, title + note, the Apple switch.
    // The whole row toggles it, like on iPhone.
    return PressableScale(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            IconBadge(icon, c.accent, size: 36, squircle: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(color: c.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: kSafe,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings > Trash: the user's reports in the trash (deleted,
/// or past their 14 days), each erased [kTrashDays] after it went in.
void showTrash(BuildContext context) =>
    showAppSheet(context, builder: (_) => const _TrashList());

class _TrashList extends StatefulWidget {
  const _TrashList();

  @override
  State<_TrashList> createState() => _TrashListState();
}

class _TrashListState extends State<_TrashList> {
  List<TrashedReport>? _list;
  String? _error;
  int? _busy; // report_id being restored / deleted

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await loadMyTrash();
      if (!mounted) return;
      setState(() {
        _list = list;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t load your trash.');
    }
  }

  Future<void> _do(int id, Future<void> Function() f) async {
    setState(() => _busy = id);
    try {
      await f();
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'That didn\'t work. Check your connection.');
      }
    }
    if (mounted) setState(() => _busy = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final list = _list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Trash',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Reports you deleted, and ones past their 14 days. Each is erased '
          'with its photo $kTrashDays days after it got here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kDanger, fontSize: 13),
          ),
        if (list == null && _error == null)
          const Center(child: CupertinoActivityIndicator()),
        if (list != null && list.isEmpty)
          Text(
            'Nothing here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 15),
          ),
        for (final r in list ?? const <TrashedReport>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.incidentType[0].toUpperCase()}${r.incidentType.substring(1)} · Brgy. ${r.barangay}',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.expired && r.deletedAt == null ? 'Expired' : 'Deleted'} '
                    '${shortDate(r.trashedAt)} · erased ${shortDate(r.erasesAt)}'
                    '${r.canRestore || r.expired ? '' : ' · removed by an admin'}',
                    style: TextStyle(color: c.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  if (_busy == r.reportId)
                    const CupertinoActivityIndicator()
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (r.canRestore)
                          TintedButton(
                            label: 'Restore',
                            icon: CupertinoIcons.arrow_uturn_left,
                            onPressed: () => _do(
                              r.reportId,
                              () => restoreReport(r.reportId),
                            ),
                          ),
                        TintedButton(
                          label: 'Delete now',
                          icon: CupertinoIcons.trash_fill,
                          onPressed: () => _do(
                            r.reportId,
                            () => deleteReportForGood(r.reportId, r.photoUrl),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
