import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'alerts.dart' show loadAlerts;
import 'centers.dart' show loadCenters;
import 'reports.dart' show kTrashDays, loadReports;

/// ============================================================
/// ADMIN: what the Admin page reads and changes (FR-A1..A8)
/// ============================================================
///
/// The database decides who may do this (is_admin() in every rule, see
/// supabase/01-08): the app only hides the page from non-admins. Nothing
/// here works for a normal user even if they found the page.

SupabaseClient get _db => Supabase.instance.client;

// ------------------------------------------------------ rescue requests

/// One row of `rescue_requests` (paper, Table 17).
class RescueRequest {
  final int requestId;
  final String? userId; // null = sent by a guest
  final String contactName;
  final String contactPhone;
  final String barangay;
  final LatLng? point;
  final int peopleCount;
  final List<String> specialNeeds;
  final String? note;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  RescueRequest.fromRow(Map<String, dynamic> row)
    : requestId = row['request_id'] as int,
      userId = row['user_id'] as String?,
      contactName = row['contact_name'] as String,
      contactPhone = row['contact_phone'] as String,
      barangay = row['barangay'] as String,
      point = row['latitude'] == null
          ? null
          : LatLng(
              (row['latitude'] as num).toDouble(),
              (row['longitude'] as num).toDouble(),
            ),
      peopleCount = row['people_count'] as int,
      specialNeeds = [...?(row['special_needs'] as List?)?.cast<String>()],
      note = row['note'] as String?,
      status = row['status'] as String,
      createdAt = DateTime.parse(row['created_at'] as String).toLocal(),
      updatedAt = DateTime.parse(row['updated_at'] as String).toLocal();

  bool get fromGuest => userId == null;
}

/// Newest first, live while the Admin page is open.
final ValueNotifier<List<RescueRequest>> rescueRequests = ValueNotifier([]);

/// Phone numbers flagged as "Potential Spam/Prank Call" (FR-A5).
final ValueNotifier<Set<String>> flaggedNumbers = ValueNotifier({});

RealtimeChannel? _rescueChannel;

/// Loads the requests + flags and listens for new ones. Called when the
/// Admin page opens; [stopRescueWatch] when it closes.
void startRescueWatch() {
  try {
    loadRescueRequests().catchError((_) {}); // offline: keep what's shown
    _rescueChannel ??= _db
        .channel('admin_rescue')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rescue_requests',
          callback: (_) => loadRescueRequests().catchError((_) {}),
        )
        .subscribe();
  } catch (_) {
    // No Supabase (widget tests): the page shows what it has.
  }
}

void stopRescueWatch() {
  final ch = _rescueChannel;
  _rescueChannel = null;
  if (ch != null) _db.removeChannel(ch);
}

// shortcut: the newest 200 only. Requests are deleted after 30 days, so
// that's plenty for a demo; page through them if it ever isn't.
Future<void> loadRescueRequests() async {
  final rows = await _db
      .from('rescue_requests')
      .select()
      .order('created_at', ascending: false)
      .limit(200);
  rescueRequests.value = [for (final r in rows) RescueRequest.fromRow(r)];
  final flags = await _db.from('flagged_numbers').select('phone_number');
  flaggedNumbers.value = {for (final f in flags) f['phone_number'] as String};
}

Future<void> setRescueStatus(int requestId, String status) async {
  await _db
      .from('rescue_requests')
      .update({'status': status})
      .eq('request_id', requestId);
  await loadRescueRequests();
}

/// "Flagged false" + the number on the flagged list (paper, Table 12's
/// alternative flow).
Future<void> flagRescueRequest(RescueRequest r, String reason) async {
  await _db.from('flagged_numbers').upsert({
    'phone_number': r.contactPhone,
    'request_id': r.requestId,
    'reason': reason.trim().isEmpty ? 'Potential Spam/Prank Call' : reason,
  });
  await setRescueStatus(r.requestId, 'flagged_false');
}

Future<void> unflagNumber(String phone) async {
  await _db.from('flagged_numbers').delete().eq('phone_number', phone);
  await loadRescueRequests();
}

// --------------------------------------------------------- flood reports

/// One row of `flood_reports` as the admin sees it: every status,
/// with the poster's name.
class AdminReport {
  final int reportId;
  final String incidentType;
  final String severity;
  final int? depthCm;
  final String barangay;
  final String? note;
  final String? photoUrl;
  final String status; // unverified, verified, removed
  final String posterName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? deletedAt; // in the trash since (supabase/09_trash.sql)

  AdminReport.fromRow(Map<String, dynamic> row)
    : reportId = row['report_id'] as int,
      incidentType = row['incident_type'] as String,
      severity = row['severity'] as String,
      depthCm = row['depth_cm'] as int?,
      barangay = row['barangay'] as String,
      note = row['note'] as String?,
      photoUrl = row['photo_url'] as String?,
      status = row['status'] as String,
      posterName =
          (row['users'] as Map<String, dynamic>?)?['full_name'] as String? ??
          'Deleted account',
      createdAt = DateTime.parse(row['created_at'] as String).toLocal(),
      expiresAt = DateTime.parse(row['expires_at'] as String).toLocal(),
      deletedAt = switch (row['deleted_at']) {
        final String t => DateTime.parse(t).toLocal(),
        _ => null,
      };

  bool get expired => !expiresAt.isAfter(DateTime.now());

  /// Deleted, or past its 14 days.
  bool get inTrash => deletedAt != null || expired;

  /// When the purge function erases it (in the trash only).
  DateTime get erasesAt =>
      (deletedAt != null && deletedAt!.isBefore(expiresAt)
              ? deletedAt!
              : expiresAt)
          .add(const Duration(days: kTrashDays));
}

Future<List<AdminReport>> loadAllReports() async {
  final rows = await _db
      .from('flood_reports')
      // Two foreign keys point at users (poster, reviewer): name the poster's.
      .select('*, users!flood_reports_user_id_fkey(full_name)')
      .order('created_at', ascending: false);
  final all = [for (final r in rows) AdminReport.fromRow(r)];
  // Live ones first, then the trash (every row left is one or the other).
  return [...all.where((r) => !r.inTrash), ...all.where((r) => r.inTrash)];
}

/// verified / removed (hidden from everyone) / unverified (back to normal).
Future<void> setReportStatus(int reportId, String status) async {
  await _db
      .from('flood_reports')
      .update({'status': status, 'reviewed_by': _db.auth.currentUser!.id})
      .eq('report_id', reportId);
  await loadReports();
}

// ---------------------------------------------------------------- alerts

/// Posts a new alert ([alertId] null) or saves an edit. [row] holds the
/// `alerts` columns: title, summary, details, category, severity, area,
/// actions. posted_by is set by the database.
Future<void> saveAlert(int? alertId, Map<String, dynamic> row) async {
  if (alertId == null) {
    await _db.from('alerts').insert(row);
  } else {
    await _db.from('alerts').update(row).eq('alert_id', alertId);
  }
  await loadAlerts();
}

Future<void> deleteAlert(int alertId) async {
  await _db.from('alerts').delete().eq('alert_id', alertId);
  await loadAlerts();
}

// ------------------------------------------------------------- centers

/// Adds a center ([centerId] null) or saves an edit. [row] holds the
/// `evacuation_centers` columns.
Future<void> saveCenter(int? centerId, Map<String, dynamic> row) async {
  if (centerId == null) {
    await _db.from('evacuation_centers').insert(row);
  } else {
    await _db.from('evacuation_centers').update(row).eq('center_id', centerId);
  }
  await loadCenters();
}

Future<void> deleteCenter(int centerId) async {
  await _db.from('evacuation_centers').delete().eq('center_id', centerId);
  await loadCenters();
}

// ---------------------------------------------------------------- users

class AdminUserRow {
  final String userId;
  final String fullName;
  final String email;
  final String barangay;
  final String role;
  final String accountStatus;
  final DateTime createdAt;

  AdminUserRow.fromRow(Map<String, dynamic> row)
    : userId = row['user_id'] as String,
      fullName = row['full_name'] as String,
      email = row['email'] as String,
      barangay = row['barangay'] as String,
      role = row['role'] as String,
      accountStatus = row['account_status'] as String,
      createdAt = DateTime.parse(row['created_at'] as String).toLocal();

  bool get suspended => accountStatus == 'suspended';
}

Future<List<AdminUserRow>> loadUsers() async {
  final rows = await _db
      .from('users')
      .select()
      .order('created_at', ascending: false);
  return [for (final r in rows) AdminUserRow.fromRow(r)];
}

/// Suspend / reactivate (supabase/08_admin.sql set_account_status).
Future<void> setAccountStatus(String userId, String status) => _db.rpc(
  'set_account_status',
  params: {'p_user_id': userId, 'p_status': status},
);
