import 'package:flutter/cupertino.dart'
    show CupertinoActivityIndicator, CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../data/demo_data.dart' show kBarangayPoints, timeAgo;
import '../services/admin.dart';
import '../services/alerts.dart';
import '../services/auth.dart';
import '../services/centers.dart';
import '../services/reports.dart' show incidentIcon;
import '../services/rescue.dart' show kRescueNeeds, kRescueStatuses;
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/links.dart';

/// ============================================================
/// ADMIN: for users with role = 'admin' only (FR-A1..A8)
/// ============================================================
///
/// Opened from the avatar menu (only shown to admins). Five sections:
/// rescue requests, flood reports, alerts, evacuation centers, users.
/// The database checks every change (services/admin.dart): hiding the
/// page is only for looks.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  static const _tabs = ['Rescue', 'Reports', 'Alerts', 'Centers', 'Users'];

  @override
  void initState() {
    super.initState();
    startRescueWatch(); // live: new requests show at once
  }

  @override
  void dispose() {
    stopRescueWatch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SubpageScaffold(
      title: 'Admin',
      body: Column(
        children: [
          // Wraps onto two lines on phones, so every section is visible.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  SelectChip(
                    label: _tabs[i],
                    selected: _tab == i,
                    onTap: () => setState(() => _tab = i),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => const _RescueSection(),
              1 => const _ReportsSection(),
              2 => const _AlertsSection(),
              3 => const _CentersSection(),
              _ => const _UsersSection(),
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- helpers

const _pad = EdgeInsets.fromLTRB(20, 0, 20, 32);

/// Runs a change; a failure shows as a bar at the bottom instead of
/// vanishing silently.
Future<void> _run(BuildContext context, Future<void> Function() change) async {
  try {
    await change();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Didn\'t work: ${_why(e)}')));
    }
  }
}

String _why(Object e) {
  final s = '$e';
  if (s.contains('not_yourself')) return 'you can\'t suspend yourself.';
  if (s.contains('admins_only') || s.contains('row-level security')) {
    return 'only active admins can do that.';
  }
  // The database's own words, so a real problem can be found.
  if (e is PostgrestException) return '${e.message} (${e.code})';
  if (e is AuthException) return e.message;
  return 'check your connection and try again.';
}

/// "Are you sure?" sheet. True = go ahead.
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final ok = await showAppSheet<bool>(
    context,
    builder: (sheet) {
      final c = AppColors(sheet);
      return Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: action,
            color: kDanger,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: 6),
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      );
    },
  );
  return ok == true;
}

Widget _empty(AppColors c, String text) => Padding(
  padding: const EdgeInsets.only(top: 40),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: c.textSecondary, fontSize: 15),
  ),
);

Widget _title(AppColors c, String text) => Text(
  text,
  style: TextStyle(
    color: c.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  ),
);

Widget _line(AppColors c, String text) => Padding(
  padding: const EdgeInsets.only(top: 2),
  child: Text(
    text,
    style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
  ),
);

String _ago(DateTime t) => timeAgo(DateTime.now().difference(t));

// ------------------------------------------------------- rescue requests

class _RescueSection extends StatelessWidget {
  const _RescueSection();

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return ListenableBuilder(
      listenable: Listenable.merge([rescueRequests, flaggedNumbers]),
      builder: (context, _) {
        final list = rescueRequests.value;
        return ListView(
          padding: _pad,
          children: [
            Text(
              'Nobody is on duty yet: the request form tells people so. Guests\' requests: call the number to confirm (Verifying), then Help on the way, then Resolved.',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (list.isEmpty) _empty(c, 'No rescue requests yet.'),
            for (final r in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _requestCard(context, c, r),
              ),
          ],
        );
      },
    );
  }

  Widget _requestCard(BuildContext context, AppColors c, RescueRequest r) {
    final flagged = flaggedNumbers.value.contains(r.contactPhone);
    final color = switch (r.status) {
      'received' => kDanger,
      'verifying' || 'help_on_the_way' => kCaution,
      'resolved' => kSafe,
      _ => kGray,
    };
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _title(
                  c,
                  '#${r.requestId} · Brgy. ${r.barangay} · ${r.peopleCount} ${r.peopleCount == 1 ? 'person' : 'people'}',
                ),
              ),
              StatusPill(kRescueStatuses[r.status] ?? r.status, color),
            ],
          ),
          _line(
            c,
            '${r.contactName} · ${r.contactPhone}${r.fromGuest ? ' · guest' : ''} · ${_ago(r.createdAt)}',
          ),
          // FR-A5: requests from flagged numbers are highlighted.
          if (flagged)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: StatusPill('Flagged number: possible prank', kDanger),
            ),
          if (r.specialNeeds.isNotEmpty)
            _line(
              c,
              'Needs: ${r.specialNeeds.map((n) => kRescueNeeds[n] ?? n).join(', ')}',
            ),
          if (r.note != null) _line(c, '"${r.note}"'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TintedButton(
                label: 'Call',
                icon: CupertinoIcons.phone_fill,
                onPressed: () => confirmCall(
                  context,
                  name: r.contactName,
                  number: r.contactPhone,
                ),
              ),
              if (r.point != null)
                TintedButton(
                  label: 'Directions',
                  icon: CupertinoIcons.arrow_up_right_diamond_fill,
                  onPressed: () => openDirections(context, r.point!),
                ),
              TintedButton(
                label: 'Status',
                icon: CupertinoIcons.arrow_2_circlepath,
                onPressed: () => _pickStatus(context, r),
              ),
              if (r.status != 'flagged_false')
                TintedButton(
                  label: 'Flag false',
                  icon: CupertinoIcons.flag_fill,
                  onPressed: () => _flag(context, r),
                )
              else if (flagged)
                TintedButton(
                  label: 'Unflag number',
                  onPressed: () =>
                      _run(context, () => unflagNumber(r.contactPhone)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickStatus(BuildContext context, RescueRequest r) {
    showAppSheet(
      context,
      builder: (sheet) {
        final c = AppColors(sheet);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Request #${r.requestId}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (final MapEntry(:key, :value) in kRescueStatuses.entries)
              if (key != 'flagged_false') // that one goes through "Flag false"
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectChip(
                    label: value,
                    selected: r.status == key,
                    onTap: () {
                      Navigator.of(sheet).pop();
                      _run(context, () => setRescueStatus(r.requestId, key));
                    },
                  ),
                ),
          ],
        );
      },
    );
  }

  void _flag(BuildContext context, RescueRequest r) {
    final reason = TextEditingController(text: 'Potential Spam/Prank Call');
    showAppSheet(
      context,
      builder: (sheet) {
        final c = AppColors(sheet);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Flag ${r.contactPhone}?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Only when you\'ve confirmed the request is false. Its status becomes "Marked as false", and new requests from this number get highlighted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(hint: 'Reason', controller: reason),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Flag as false',
              color: kDanger,
              onPressed: () {
                Navigator.of(sheet).pop();
                _run(context, () => flagRescueRequest(r, reason.text));
              },
            ),
            const SizedBox(height: 6),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------- flood reports

class _ReportsSection extends StatefulWidget {
  const _ReportsSection();

  @override
  State<_ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends State<_ReportsSection> {
  List<AdminReport>? _list;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await loadAllReports();
      if (!mounted) return;
      setState(() {
        _list = list;
        _failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _change(Future<void> Function() f) async {
    await _run(context, f);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final list = _list;
    return ListView(
      padding: _pad,
      children: [
        if (_failed) _empty(c, 'Couldn\'t load the reports.'),
        if (list == null && !_failed)
          const Center(child: CupertinoActivityIndicator()),
        if (list != null && list.isEmpty) _empty(c, 'No reports right now.'),
        for (final r in list ?? const <AdminReport>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _reportCard(c, r),
          ),
      ],
    );
  }

  Widget _reportCard(AppColors c, AdminReport r) {
    final color = switch (r.status) {
      'verified' => kSafe,
      'removed' => kGray,
      _ => kCaution,
    };
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.photoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      r.photoUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const SizedBox(width: 64, height: 64),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconBadge(
                    incidentIcon(r.incidentType),
                    kBlue,
                    size: 40,
                    squircle: true,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(
                      c,
                      '${r.incidentType[0].toUpperCase()}${r.incidentType.substring(1)} · Brgy. ${r.barangay}',
                    ),
                    _line(
                      c,
                      '${r.posterName} · ${_ago(r.createdAt)}${r.depthCm == null ? '' : ' · ${r.depthCm} cm'}',
                    ),
                    if (r.note != null) _line(c, '"${r.note}"'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                r.status[0].toUpperCase() + r.status.substring(1),
                color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (r.status != 'verified')
                TintedButton(
                  label: 'Verify',
                  icon: CupertinoIcons.checkmark_seal_fill,
                  onPressed: () =>
                      _change(() => setReportStatus(r.reportId, 'verified')),
                ),
              if (r.status != 'removed')
                TintedButton(
                  label: 'Hide',
                  icon: CupertinoIcons.eye_slash_fill,
                  onPressed: () =>
                      _change(() => setReportStatus(r.reportId, 'removed')),
                )
              else
                TintedButton(
                  label: 'Show again',
                  icon: CupertinoIcons.eye_fill,
                  onPressed: () =>
                      _change(() => setReportStatus(r.reportId, 'unverified')),
                ),
              TintedButton(
                label: 'Delete',
                icon: CupertinoIcons.trash_fill,
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    title: 'Delete this report?',
                    message: 'The report, its photo and its votes are deleted for good. "Hide" keeps it for you to look at.',
                    action: 'Delete',
                  );
                  if (ok) await _change(() => deleteReportForGood(r));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- alerts

class _AlertsSection extends StatelessWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return ValueListenableBuilder(
      valueListenable: alerts,
      builder: (context, list, _) => ListView(
        padding: _pad,
        children: [
          PrimaryButton(
            label: 'Post an alert',
            icon: CupertinoIcons.plus,
            color: kBlue,
            onPressed: () => _alertForm(context, null),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty) _empty(c, 'No alerts posted.'),
          for (final a in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _title(c, a.title)),
                        StatusPill(switch (a.severity) {
                          RiskLevel.high => 'High',
                          RiskLevel.moderate => 'Moderate',
                          RiskLevel.normal => 'Normal',
                        }, a.severity.color),
                      ],
                    ),
                    _line(
                      c,
                      '${a.category.label} · ${a.area} · ${_ago(a.createdAt)}',
                    ),
                    _line(c, a.summary),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        TintedButton(
                          label: 'Edit',
                          icon: CupertinoIcons.pencil,
                          onPressed: () => _alertForm(context, a),
                        ),
                        TintedButton(
                          label: 'Delete',
                          icon: CupertinoIcons.trash_fill,
                          onPressed: () async {
                            final ok = await _confirm(
                              context,
                              title: 'Delete this alert?',
                              message: 'It disappears from everyone\'s bell.',
                              action: 'Delete',
                            );
                            if (ok && context.mounted) {
                              await _run(context, () => deleteAlert(a.alertId));
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Post a new alert ([a] null) or edit one. Columns: supabase/04_alerts.sql.
void _alertForm(BuildContext context, AppAlert? a) {
  final title = TextEditingController(text: a?.title);
  final summary = TextEditingController(text: a?.summary);
  final details = TextEditingController(text: a?.details);
  final area = TextEditingController(text: a?.area ?? 'Mabalacat City');
  final steps = TextEditingController(text: a?.actions.join('\n'));
  var category = a?.category ?? AlertCategory.flood;
  var severity = switch (a?.severity) {
    RiskLevel.high => 'high',
    RiskLevel.moderate => 'moderate',
    _ => 'normal',
  };
  var busy = false;
  String? error;
  showAppSheet(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final c = AppColors(sheet);
        Future<void> save() async {
          if ([
            title,
            summary,
            details,
            area,
          ].any((t) => t.text.trim().isEmpty)) {
            return setSheet(
              () => error = 'Title, summary, details and area are all needed.',
            );
          }
          setSheet(() {
            busy = true;
            error = null;
          });
          try {
            await saveAlert(a?.alertId, {
              'title': title.text.trim(),
              'summary': summary.text.trim(),
              'details': details.text.trim(),
              'category': category.name,
              'severity': severity,
              'area': area.text.trim(),
              'actions': [
                for (final s in steps.text.split('\n'))
                  if (s.trim().isNotEmpty) s.trim(),
              ],
            });
            if (sheet.mounted) Navigator.of(sheet).pop();
          } catch (e) {
            setSheet(() {
              busy = false;
              error = 'Didn\'t save: ${_why(e)}';
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              a == null ? 'Post an alert' : 'Edit alert',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Everyone sees it under the bell, signed "$kAdminSource".',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            AppTextField(
              hint: 'Title, e.g. Flood warning for Dau',
              controller: title,
            ),
            const SizedBox(height: 10),
            AppTextField(hint: 'One-line summary', controller: summary),
            const SizedBox(height: 10),
            AppTextField(
              hint: 'Full details',
              controller: details,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            AppTextField(hint: 'Area, e.g. Brgy. Dau', controller: area),
            const SizedBox(height: 10),
            AppTextField(
              hint: 'What to do: one step per line (optional)',
              controller: steps,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            const FieldLabel('Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in AlertCategory.values)
                  SelectChip(
                    label: cat.label,
                    icon: cat.icon,
                    selected: category == cat,
                    onTap: () => setSheet(() => category = cat),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const FieldLabel('Severity'),
            Wrap(
              spacing: 8,
              children: [
                for (final (v, label, color) in [
                  ('normal', 'Normal', RiskLevel.normal.color),
                  ('moderate', 'Moderate', RiskLevel.moderate.color),
                  ('high', 'High', RiskLevel.high.color),
                ])
                  SelectChip(
                    label: label,
                    color: color,
                    selected: severity == v,
                    onTap: () => setSheet(() => severity = v),
                  ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: TextStyle(color: c.readable(kDanger), fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: a == null ? 'Post' : 'Save',
              color: kBlue,
              loading: busy,
              onPressed: save,
            ),
            const SizedBox(height: 6),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        );
      },
    ),
  );
}

// ------------------------------------------------------------- centers

class _CentersSection extends StatelessWidget {
  const _CentersSection();

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    return ValueListenableBuilder(
      valueListenable: evacCenters,
      builder: (context, list, _) => ListView(
        padding: _pad,
        children: [
          PrimaryButton(
            label: 'Add a center',
            icon: CupertinoIcons.plus,
            color: kBlue,
            onPressed: () => _centerForm(context, null),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty) _empty(c, 'No evacuation centers yet.'),
          for (final e in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _title(c, e.name)),
                        if (e.isSample) const SampleBadge(),
                      ],
                    ),
                    _line(c, 'Brgy. ${e.barangay}'),
                    const SizedBox(height: 10),
                    // One tap changes the status for everyone (FR-A8).
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (v, label) in [
                          ('open', 'Open'),
                          ('standby', 'Standby'),
                          ('closed', 'Closed'),
                        ])
                          SelectChip(
                            label: label,
                            color: v == 'open' ? kShelter : null,
                            selected: e.status == v,
                            onTap: () => _run(
                              context,
                              () => saveCenter(e.centerId, {'status': v}),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        TintedButton(
                          label: 'Edit',
                          icon: CupertinoIcons.pencil,
                          onPressed: () => _centerForm(context, e),
                        ),
                        TintedButton(
                          label: 'Delete',
                          icon: CupertinoIcons.trash_fill,
                          onPressed: () async {
                            final ok = await _confirm(
                              context,
                              title: 'Delete ${e.name}?',
                              message: 'It disappears from the map and Help.',
                              action: 'Delete',
                            );
                            if (ok && context.mounted) {
                              await _run(
                                context,
                                () => deleteCenter(e.centerId),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Add a center ([e] null) or edit one. The spot starts at the
/// barangay's center; type the exact latitude / longitude from Google
/// Maps (right-click the place > the numbers at the top).
void _centerForm(BuildContext context, EvacuationCenter? e) {
  final name = TextEditingController(text: e?.name);
  final lat = TextEditingController(text: e?.point.latitude.toString());
  final lng = TextEditingController(text: e?.point.longitude.toString());
  String? barangay = e?.barangay;
  var status = e?.status ?? 'standby';
  var sample = e?.isSample ?? false;
  var busy = false;
  String? error;
  showAppSheet(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final c = AppColors(sheet);
        Future<void> save() async {
          final la = double.tryParse(lat.text.trim());
          final lo = double.tryParse(lng.text.trim());
          if (name.text.trim().isEmpty || barangay == null) {
            return setSheet(() => error = 'Name and barangay are needed.');
          }
          if (la == null ||
              lo == null ||
              la < 15.13 ||
              la > 15.30 ||
              lo < 120.49 ||
              lo > 120.67) {
            return setSheet(
              () => error =
                  'The location must be inside Mabalacat '
                  '(latitude 15.13-15.30, longitude 120.49-120.67).',
            );
          }
          setSheet(() {
            busy = true;
            error = null;
          });
          try {
            await saveCenter(e?.centerId, {
              'name': name.text.trim(),
              'barangay': barangay,
              'latitude': double.parse(la.toStringAsFixed(6)),
              'longitude': double.parse(lo.toStringAsFixed(6)),
              'status': status,
              'is_sample': sample,
            });
            if (sheet.mounted) Navigator.of(sheet).pop();
          } catch (err) {
            setSheet(() {
              busy = false;
              error = 'Didn\'t save: ${_why(err)}';
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              e == null ? 'Add a center' : 'Edit center',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              hint: 'Name, e.g. Dau Elementary School',
              controller: name,
            ),
            const SizedBox(height: 10),
            BarangayDropdown(
              value: barangay,
              onChanged: (b) => setSheet(() {
                barangay = b;
                // A starting spot: the barangay's center, if none typed yet.
                final p = kBarangayPoints[b];
                if (p != null && lat.text.isEmpty && lng.text.isEmpty) {
                  lat.text = p.latitude.toStringAsFixed(6);
                  lng.text = p.longitude.toStringAsFixed(6);
                }
              }),
            ),
            const SizedBox(height: 10),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: AppTextField(
                    hint: 'Latitude',
                    controller: lat,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                Expanded(
                  child: AppTextField(
                    hint: 'Longitude',
                    controller: lng,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Exact spot: in Google Maps, right-click the building and copy the two numbers.',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const FieldLabel('Status'),
            Wrap(
              spacing: 8,
              children: [
                for (final (v, label) in [
                  ('open', 'Open'),
                  ('standby', 'Standby'),
                  ('closed', 'Closed'),
                ])
                  SelectChip(
                    label: label,
                    selected: status == v,
                    onTap: () => setSheet(() => status = v),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SelectChip(
              label: sample ? 'SAMPLE: made-up demo center' : 'Real center',
              selected: sample,
              onTap: () => setSheet(() => sample = !sample),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: TextStyle(color: c.readable(kDanger), fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Save',
              color: kBlue,
              loading: busy,
              onPressed: save,
            ),
            const SizedBox(height: 6),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        );
      },
    ),
  );
}

// ----------------------------------------------------------------- users

class _UsersSection extends StatefulWidget {
  const _UsersSection();

  @override
  State<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<_UsersSection> {
  List<AdminUserRow>? _list;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await loadUsers();
      if (!mounted) return;
      setState(() {
        _list = list;
        _failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final list = _list;
    return ListView(
      padding: _pad,
      children: [
        Text(
          'Making someone an admin is done in Supabase\'s Table Editor (users > role), on purpose.',
          style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 14),
        if (_failed) _empty(c, 'Couldn\'t load the users.'),
        if (list == null && !_failed)
          const Center(child: CupertinoActivityIndicator()),
        for (final u in list ?? const <AdminUserRow>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title(c, u.fullName),
                        _line(c, '${u.email} · Brgy. ${u.barangay}'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (u.role == 'admin') StatusPill('Admin', kBlue),
                            if (u.suspended) StatusPill('Suspended', kDanger),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (u.userId != me?.userId)
                    TintedButton(
                      label: u.suspended ? 'Reactivate' : 'Suspend',
                      onPressed: () async {
                        final ok =
                            u.suspended ||
                            await _confirm(
                              context,
                              title: 'Suspend ${u.fullName}?',
                              message: 'They\'re logged out the next time the app checks, and can\'t post or vote until you reactivate them.',
                              action: 'Suspend',
                            );
                        if (!ok || !context.mounted) return;
                        await _run(
                          context,
                          () => setAccountStatus(
                            u.userId,
                            u.suspended ? 'active' : 'suspended',
                          ),
                        );
                        await _load();
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
