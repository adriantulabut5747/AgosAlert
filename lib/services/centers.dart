import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/demo_data.dart' show kBarangayPoints, myBarangay;

/// ============================================================
/// EVACUATION CENTERS, through Supabase
/// ============================================================
///
/// Table + rules: supabase/06_evacuation_centers.sql (paper, Table 21,
/// minus capacity / evacuees). Everyone reads them; admins edit them on
/// the Admin page. [evacCenters] updates by itself (Realtime).

/// One row of `evacuation_centers`. Field names follow the columns.
class EvacuationCenter {
  final int centerId;
  final String name;
  final String barangay;
  final LatLng point;
  final String status; // 'open', 'standby' or 'closed'
  final String? photoUrl;

  /// A made-up demo row (SAMPLE badge) until the real list arrives.
  final bool isSample;

  const EvacuationCenter({
    required this.centerId,
    required this.name,
    required this.barangay,
    required this.point,
    this.status = 'open',
    this.photoUrl,
    this.isSample = false,
  });

  EvacuationCenter.fromRow(Map<String, dynamic> row)
    : centerId = row['center_id'] as int,
      name = row['name'] as String,
      barangay = row['barangay'] as String,
      point = LatLng(
        (row['latitude'] as num).toDouble(),
        (row['longitude'] as num).toDouble(),
      ),
      status = row['status'] as String,
      photoUrl = row['photo_url'] as String?,
      isSample = row['is_sample'] as bool;

  bool get open => status == 'open';

  String get statusLabel => switch (status) {
    'open' => 'Open',
    'standby' => 'Standby',
    _ => 'Closed',
  };

  /// A picture of the kind of place, from its name.
  IconData get icon {
    final n = name.toLowerCase();
    if (n.contains('school')) return CupertinoIcons.book_fill;
    if (n.contains('sports') || n.contains('gym')) {
      return CupertinoIcons.sportscourt_fill;
    }
    if (n.contains('hall')) return CupertinoIcons.building_2_fill;
    return CupertinoIcons.house_alt_fill;
  }

  /// Straight-line km from the center of the user's barangay, or null
  /// when no barangay is picked (then no distance is shown: no made-up
  /// numbers).
  double? get distanceKm {
    final from = kBarangayPoints[myBarangay.value];
    if (from == null) return null;
    return const Distance().as(LengthUnit.Meter, from, point) / 1000;
  }

  /// "2.1 km", or '' with no barangay picked.
  String get distanceLabel {
    final d = distanceKm;
    return d == null ? '' : '${d.toStringAsFixed(1)} km';
  }
}

/// Open ones first, then nearest to the user's barangay, then by name.
List<EvacuationCenter> sortedCenters(Iterable<EvacuationCenter> list) =>
    [...list]..sort((a, b) {
      if (a.open != b.open) return a.open ? -1 : 1;
      final da = a.distanceKm, db = b.distanceKm;
      if (da != null && db != null && da != db) return da.compareTo(db);
      return a.name.compareTo(b.name);
    });

/// Every center. Tests set it directly.
final ValueNotifier<List<EvacuationCenter>> evacCenters = ValueNotifier([]);

/// True while any shown center is made-up demo data (SAMPLE badge).
bool get centersAreSample => evacCenters.value.any((e) => e.isSample);

SupabaseClient get _db => Supabase.instance.client;

/// Loads the centers and listens for changes. Called once in main().
void startCenters() {
  loadCenters();
  _db
      .channel('evacuation_centers')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'evacuation_centers',
        callback: (_) => loadCenters(),
      )
      .subscribe();
}

Future<void> loadCenters() async {
  try {
    final rows = await _db.from('evacuation_centers').select().order('name');
    evacCenters.value = [for (final r in rows) EvacuationCenter.fromRow(r)];
  } catch (_) {
    // Keep what's on screen (empty at first: "No evacuation center" lines).
  }
}
