import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth.dart';

/// ============================================================
/// RESCUE REQUESTS, through Supabase
/// ============================================================
///
/// Tables + rules: supabase/07_rescue_requests.sql (paper, Tables 17-18).
/// Anyone sends one through create_rescue_request() (guests too, with a
/// name and phone). This device remembers the id + phone of what it sent,
/// so it can show the status (FR-G9) through rescue_request_status().
///
/// Nobody monitors them yet (Nov 19 2026): the form says so loudly.

/// The paper's special needs: database value -> what the form shows.
const kRescueNeeds = {
  'elderly': 'Elderly',
  'pwd': 'PWD',
  'infant_child': 'Infant / child',
  'pregnant': 'Pregnant',
  'medical_care': 'Needs medical care',
};

/// The paper's statuses: database value -> what people read.
const kRescueStatuses = {
  'received': 'Received',
  'verifying': 'Verifying',
  'help_on_the_way': 'Help on the way',
  'resolved': 'Resolved',
  'flagged_false': 'Marked as false',
};

/// "0917 123 4567" / "+63 917-123-4567" -> digits with an optional +,
/// the shape the database accepts (7-14 digits).
String cleanPhone(String raw) {
  final s = raw.replaceAll(RegExp(r'[\s\-().]'), '');
  return s;
}

bool isValidPhone(String raw) =>
    RegExp(r'^\+?[0-9]{7,14}$').hasMatch(cleanPhone(raw));

/// The latest request sent from this device, as far as it knows.
class TrackedRescue {
  final int requestId;
  final String status;
  final DateTime updatedAt;
  const TrackedRescue(this.requestId, this.status, this.updatedAt);

  String get statusLabel => kRescueStatuses[status] ?? status;

  /// Still waiting for something (not resolved or marked false).
  bool get active => status != 'resolved' && status != 'flagged_false';
}

/// The request this device sent last (null = none). Tests set it directly.
final ValueNotifier<TrackedRescue?> myRescue = ValueNotifier(null);

SupabaseClient get _db => Supabase.instance.client;

const _prefsKey = 'rescue_request'; // "id|phone" of the last one sent
Timer? _poll;

/// Sends a request and starts following its status. Returns its id.
Future<int> sendRescueRequest({
  required String contactName,
  required String contactPhone,
  required String barangay,
  LatLng? point,
  required int peopleCount,
  required Set<String> specialNeeds,
  required String note,
}) async {
  final phone = cleanPhone(contactPhone);
  final id = await _db.rpc(
    'create_rescue_request',
    params: {
      'p_contact_name': contactName.trim(),
      'p_contact_phone': phone,
      'p_barangay': barangay,
      'p_latitude': point == null
          ? null
          : double.parse(point.latitude.toStringAsFixed(6)),
      'p_longitude': point == null
          ? null
          : double.parse(point.longitude.toStringAsFixed(6)),
      'p_people_count': peopleCount,
      'p_special_needs': specialNeeds.isEmpty ? null : specialNeeds.toList(),
      'p_note': note,
    },
  ) as int;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, '$id|$phone');
  myRescue.value = TrackedRescue(id, 'received', DateTime.now());
  _startPolling();
  return id;
}

/// Reads the status of the request this device sent last. Called once in
/// main(), and every 30 s while the request is still active.
Future<void> loadMyRescue() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey)?.split('|');
    if (saved == null || saved.length != 2) return;
    final id = int.parse(saved[0]);
    final rows = await _db.rpc(
      'rescue_request_status',
      params: {'p_request_id': id, 'p_contact_phone': saved[1]},
    ) as List;
    if (rows.isEmpty) {
      // Deleted (30-day clean-up): forget it.
      await prefs.remove(_prefsKey);
      myRescue.value = null;
      return;
    }
    final row = rows.first as Map<String, dynamic>;
    myRescue.value = TrackedRescue(
      id,
      row['status'] as String,
      DateTime.parse(row['updated_at'] as String).toLocal(),
    );
    if (myRescue.value!.active) _startPolling();
  } catch (_) {
    // Offline: keep what's on screen.
  }
}

/// Hides a finished request's card ("Dismiss").
Future<void> forgetMyRescue() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_prefsKey);
  myRescue.value = null;
}

// shortcut: polls every 30 s instead of Realtime, because guests can't
// subscribe to a table they can't read. Fine for one small query; move
// to Realtime for logged-in users if it ever matters.
void _startPolling() {
  _poll ??= Timer.periodic(const Duration(seconds: 30), (_) async {
    await loadMyRescue();
    if (myRescue.value?.active != true) {
      _poll?.cancel();
      _poll = null;
    }
  });
}

/// The form's starting values for a logged-in user (FR-R5: "details
/// already filled in").
String get defaultContactName => me?.fullName ?? '';
String get defaultContactPhone => me?.phoneNumber ?? '';
