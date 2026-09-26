import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../data/demo_data.dart';
import '../services/weather.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/flood_depth.dart';
import '../widgets/map_tiles.dart';
import '../widgets/responsive.dart';
import '../widgets/user_profile.dart';
import '../widgets/vote_bar.dart';
import '../widgets/links.dart';
import 'deferred_screens.dart';

/// ============================================================
/// MAP TAB — interactive map of Mabalacat City (Esri tiles, see
/// widgets/map_tiles.dart) with flood zones and evacuation centers
/// ============================================================
///
/// How the map is built: FlutterMap draws its `children` as layers, the
/// first one at the bottom:
///   1. AppTileLayer  - the map pictures (streets, place names)
///   2. CircleLayer   - the colored flood-zone circles
///   3. MarkerLayer   - the tappable pins (flood zones + evacuation centers)
///   4. the credits text
/// The header, zoom buttons, and legend are NOT part of the map; they
/// float on top of it in the outer Stack.
///
/// The map can't be dragged outside this box (Mabalacat City and a little
/// margin around it). Lives here, not in demo_data.dart, so the map
/// package stays out of the app's first download.
final LatLngBounds kMabalacatBounds = LatLngBounds(
  const LatLng(15.130, 120.490), // south-west
  const LatLng(15.300, 120.670), // north-east
);

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  // Lets our own code move the map (zoom buttons, recenter, jumping to a
  // tapped pin). The user's own dragging doesn't need it.
  final _map = MapController();
  // The two filter chips at the top. Flipping one with setState rebuilds
  // the map with that layer added or removed.
  bool _showZones = true;
  bool _showCenters = true;

  // Zoom levels: each +1 doubles the detail. 13 shows the whole city,
  // 18 shows single streets and buildings.
  static const _startZoom = 13.3;

  // Zoom in (by = 1) or out (by = -1) around the current center.
  // .clamp(13, 18) keeps the result between 13 and 18, matching minZoom
  // and maxZoom below, so the buttons can't go past the limits.
  // "View on map" on the Home feed sets focusedZone and switches to this
  // tab; we then jump to that pin and open it. Checked once at start too,
  // in case this tab was only just opened (and downloaded) for it.
  @override
  void initState() {
    super.initState();
    focusedZone.addListener(_openFocused);
    // After the first frame, so the map exists before we move it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFocused());
  }

  @override
  void dispose() {
    focusedZone.removeListener(_openFocused);
    super.dispose();
  }

  void _openFocused() {
    final z = focusedZone.value;
    if (z == null || !mounted) return;
    focusedZone.value = null;
    _showZone(context, z);
  }

  void _zoom(double by) {
    final cam = _map.camera;
    _map.move(cam.center, (cam.zoom + by).clamp(13, 18));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    // Desktop: a side panel (title, report, layers, list of pins, legend)
    // next to the map. Phones and tablets: everything floats on the map.
    if (screenSizeOf(context) == ScreenSize.desktop) return _desktop(c);
    return _floatingLayout(c, wide: isWideScreen(context));
  }

  // The map itself, with its layers. Used by both layouts.
  Widget _mapView(AppColors c) {
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: kMabalacatCenter,
        initialZoom: _startZoom,
        minZoom: 13,
        // Keep the whole view inside Mabalacat City.
        cameraConstraint: CameraConstraint.contain(bounds: kMabalacatBounds),
        maxZoom: 18,
        backgroundColor: c.surfaceAlt,
        // Allow every gesture (drag, pinch, double-tap zoom...)
        // except rotating. The flags are bits: `& ~rotate` means
        // "all of them, minus the rotate bit". A rotated map
        // confuses people and there's no compass to reset it.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        const AppTileLayer(),
        // A see-through circle around each flood zone.
        // useRadiusInMeter: the radius is in real meters on the
        // ground (650 m for high risk, 480 m otherwise), so the
        // circle grows/shrinks with the map when zooming, instead
        // of staying the same size on screen.
        if (_showZones)
          CircleLayer(
            circles: [
              for (final z in activeFloodZones)
                CircleMarker(
                  point: z.point,
                  radius: z.risk == RiskLevel.high ? 650 : 480,
                  useRadiusInMeter: true,
                  color: z.risk.color.withValues(alpha: 0.18),
                  borderColor: z.risk.color.withValues(alpha: 0.6),
                  borderStrokeWidth: 1.5,
                ),
            ],
          ),
        // Pins are normal Flutter widgets pinned to a map
        // coordinate (`point`). One MarkerLayer holds both kinds;
        // `if` + `for` inside the list add each group only when
        // its filter chip is on. Flood pins show their depth so
        // the map can be read without tapping anything.
        MarkerLayer(
          markers: [
            if (_showZones)
              for (final z in activeFloodZones)
                Marker(
                  point: z.point,
                  width: _DepthPin.size,
                  height: _DepthPin.size,
                  child: _DepthPin(zone: z, onTap: () => _showZone(context, z)),
                ),
            if (_showCenters)
              for (final e in kEvacCenters)
                Marker(
                  point: e.point,
                  width: 38,
                  height: 38,
                  child: GestureDetector(
                    onTap: () => _showCenter(context, e),
                    child: Container(
                      decoration: BoxDecoration(
                        color: e.open ? kSafe : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55000000), blurRadius: 8),
                        ],
                      ),
                      child: const Icon(
                        Icons.night_shelter_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
          ],
        ),
        // Map credits (the tile license from Esri and
        // OpenStreetMap requires showing them)
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 14, top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppTileLayer.credits,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.textSecondary, fontSize: 9.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _floatingLayout(AppColors c, {required bool wide}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: [
            _mapView(c),
            // Header + layer toggles
            Positioned(
              top: 30,
              left: 12,
              right: 12,
              child: _glass(
                c,
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const LiveDot(color: kDanger),
                        const SizedBox(width: 6),
                        Text(
                          'Flood map',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SampleBadge(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap a pin for details',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SelectChip(
                          label: 'Flood zones',
                          icon: Icons.flood_rounded,
                          selected: _showZones,
                          onTap: () => setState(() => _showZones = !_showZones),
                        ),
                        SelectChip(
                          label: 'Evacuation',
                          icon: Icons.night_shelter_rounded,
                          color: kSafe,
                          selected: _showCenters,
                          onTap: () =>
                              setState(() => _showCenters = !_showCenters),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bottom controls, stacked in one column so they can't overlap
            // on small screens: Report + zoom buttons, then the legend.
            // The empty space between them lets taps through to the map.
            Positioned(
              left: 12,
              right: 12,
              // Phones: above the floating bottom nav. Tablets have none.
              bottom: wide ? 24 : 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _reportButton(c),
                      const Spacer(),
                      Column(
                        children: [
                          _mapButton(
                            c,
                            Icons.add_rounded,
                            'Zoom in',
                            () => _zoom(1),
                          ),
                          const SizedBox(height: 8),
                          _mapButton(
                            c,
                            Icons.remove_rounded,
                            'Zoom out',
                            () => _zoom(-1),
                          ),
                          const SizedBox(height: 8),
                          _mapButton(
                            c,
                            Icons.my_location_rounded,
                            'Recenter',
                            () => _map.move(kMabalacatCenter, _startZoom),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Legend: one depth scale, low to high, left to right.
                  _glass(
                    c,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STREET FLOOD DEPTH',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _legend(c, kSafe, 'Normal', 'up to 20 cm'),
                            const SizedBox(width: 4),
                            _legend(c, kCaution, 'Moderate', '21–50 cm'),
                            const SizedBox(width: 4),
                            _legend(c, kDanger, 'High', 'over 50 cm'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktop(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 360, child: _sidePanel(c)),
          const SizedBox(width: 20),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  _mapView(c),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      spacing: 8,
                      children: [
                        _mapButton(
                          c,
                          Icons.add_rounded,
                          'Zoom in',
                          () => _zoom(1),
                        ),
                        _mapButton(
                          c,
                          Icons.remove_rounded,
                          'Zoom out',
                          () => _zoom(-1),
                        ),
                        _mapButton(
                          c,
                          Icons.my_location_rounded,
                          'Recenter',
                          () => _map.move(kMabalacatCenter, _startZoom),
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
    );
  }

  // Desktop: everything that floats on the phone map, as a quiet column:
  // what to show, the reports (deepest water first), and a way to add one.
  Widget _sidePanel(AppColors c) {
    final zones = activeFloodZones.toList()
      ..sort((a, b) => b.depthCm.compareTo(a.depthCm));
    final orange = c.isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Flood map',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 10),
              const SampleBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Reports from residents · Mabalacat City',
            style: TextStyle(color: c.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          _layerCheck(
            c,
            'Flood reports',
            zones.length,
            _showZones,
            () => setState(() => _showZones = !_showZones),
          ),
          _layerCheck(
            c,
            'Evacuation centers',
            kEvacCenters.length,
            _showCenters,
            () => setState(() => _showCenters = !_showCenters),
          ),
          Divider(height: 24, color: c.border),
          const FieldLabel('Deepest first'),
          Expanded(
            child: ListView.builder(
              itemCount: zones.length,
              itemBuilder: (context, i) => _pinRow(c, zones[i]),
            ),
          ),
          Divider(height: 20, color: c.border),
          // The depth colors (wraps onto two lines if the panel is narrow).
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legendDot(c, kSafe, 'Up to 20 cm'),
              _legendDot(c, kCaution, '21–50 cm'),
              _legendDot(c, kDanger, 'Over 50 cm'),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => openReportIncident(context),
            icon: const Icon(Icons.campaign_rounded, size: 19),
            label: const Text('Report flooding near you'),
            style: OutlinedButton.styleFrom(
              foregroundColor: orange,
              side: BorderSide(color: orange.withValues(alpha: 0.6)),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A checkbox row that turns a map layer on or off.
  Widget _layerCheck(
    AppColors c,
    String label,
    int count,
    bool value,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (_) => onTap(),
            activeColor: kSkyBlue,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(color: c.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _legendDot(AppColors c, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: c.textSecondary, fontSize: 11.5)),
      ],
    );
  }

  // One report in the side panel: the depth (in its risk color) is what
  // matters most, so it leads. Clicking jumps the map there and opens it.
  Widget _pinRow(AppColors c, FloodZone z) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showZone(context, z),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${z.depthCm.round()}',
                      style: TextStyle(
                        color: z.risk.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' cm',
                      style: TextStyle(color: c.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brgy. ${z.barangay}',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${FloodLevel.of(z.depthCm).label} · ${z.updated}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  // Shortcut to Report incident (same screen as in Assistance).
  Widget _reportButton(AppColors c) {
    return Tooltip(
      message: 'Report an incident',
      child: PressableScale(
        onTap: () => openReportIncident(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // A darker orange than the Assistance tile, so the white text
            // is easy to read.
            color: const Color(0xFFC2410C),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Report',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glass(
    AppColors c, {
    required Widget child,
    required EdgeInsets padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _mapButton(
    AppColors c,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
            boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10)],
          ),
          child: Icon(icon, color: c.textPrimary, size: 22),
        ),
      ),
    );
  }

  // One segment of the legend's scale: a colored bar with its label under.
  Widget _legend(AppColors c, Color color, String label, String range) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(range, style: TextStyle(color: c.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  // Tapping a flood-zone pin: zoom the map in on it (zoom 15), then slide
  // up a details sheet. `sheet` is the sheet's own context, used to close
  // it (Navigator.of(sheet).pop()) before opening Google Maps.
  void _showZone(BuildContext context, FloodZone z) {
    final color = z.risk.color;
    _map.move(z.point, 15);
    showAppSheet(
      context,
      maxWidth: 600,
      builder: (sheet) {
        final c = AppColors(sheet);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ZonePhoto(zone: z),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brgy. ${z.barangay}',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mabalacat City · Updated ${z.updated}',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: StatusPill('${z.risk.label} risk', color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Who posted it. Tap the name for their profile card.
            PostedBy(z.uploader),
            const SizedBox(height: 12),
            _PinDates(zone: z),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: c.border),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DepthGauge(depthCm: z.depthCm, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: DepthReadout(depthCm: z.depthCm),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              z.note,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            // Guidance as a quote-style block: a thin colored bar on the
            // left instead of a filled box.
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 3)),
              ),
              child: Text(
                _guidance(z.risk),
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            VoteBar(zone: z),
            const SizedBox(height: 22),
            GradientButton(
              label: 'Directions',
              icon: Icons.directions_rounded,
              onPressed: () {
                Navigator.of(sheet).pop();
                openDirections(context, z.point);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCenter(BuildContext context, EvacuationCenter e) {
    _map.move(e.point, 15);
    showAppSheet(
      context,
      builder: (sheet) {
        final c = AppColors(sheet);
        final color = e.open ? kSafe : const Color(0xFF94A3B8);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(e.icon, color, size: 48, squircle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Evacuation center · Brgy. ${e.barangay}',
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _statBox(
                    c,
                    'Status',
                    e.open ? 'Open' : 'Standby',
                    color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statBox(
                    c,
                    'Occupancy',
                    '${e.occupants}/${e.capacity}',
                    c.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statBox(
                    c,
                    'Distance',
                    '${e.distanceKm} km',
                    c.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Directions',
              icon: Icons.directions_rounded,
              onPressed: () {
                Navigator.of(sheet).pop();
                openDirections(context, e.point);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _statBox(AppColors c, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // A "switch expression": picks the text that matches the risk level.
  // Dart checks that every RiskLevel is covered, so adding a new level
  // later won't compile until it gets a message here too.
  String _guidance(RiskLevel risk) => switch (risk) {
    RiskLevel.high => 'Move to higher ground now and avoid this area until the water goes down.',
    RiskLevel.moderate => 'Stay alert and keep checking for updates. Avoid unnecessary travel here.',
    RiskLevel.normal => 'Conditions are normal. No action needed right now.',
  };
}

/// A flood pin: a classic map pin (colored by risk) whose tip sits exactly
/// on the spot, with the depth ("45 cm") in a small tag above it.
/// High-risk pins send out a ring on the ground that keeps growing and
/// fading (like a radar ping) so they stand out.
///
/// flutter_map puts the CENTER of a marker on its `point`, so the marker
/// is a square with the pin's tip at its center; the pin and tag use the
/// top half (and taps anywhere on them count).
class _DepthPin extends StatefulWidget {
  static const double size = 112;
  final FloodZone zone;
  final VoidCallback onTap;
  const _DepthPin({required this.zone, required this.onTap});

  @override
  State<_DepthPin> createState() => _DepthPinState();
}

class _DepthPinState extends State<_DepthPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  bool get _pulse => widget.zone.risk == RiskLevel.high;

  @override
  void initState() {
    super.initState();
    if (_pulse) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final z = widget.zone;
    final color = z.risk.color;
    final dry = FloodLevel.of(z.depthCm) == FloodLevel.dry;
    const half = _DepthPin.size / 2;
    return Semantics(
      button: true,
      label: 'Brgy. ${z.barangay}, ${formatCm(z.depthCm)}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The ping ring, flattened like a shadow on the ground.
              if (_pulse)
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) => Container(
                    width: 10 + 40 * _ctrl.value,
                    height: (10 + 40 * _ctrl.value) * 0.45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: color.withValues(alpha: 0.45 * (1 - _ctrl.value)),
                    ),
                  ),
                ),
              Positioned(
                bottom: half,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Color(0x40000000), blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        dry ? 'Dry' : formatCm(z.depthCm),
                        style: TextStyle(
                          color: Color.lerp(color, Colors.black, 0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    CustomPaint(
                      size: const Size(28, 36),
                      painter: _PinShape(color),
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

/// The map-pin shape: a round head that narrows to a point at the bottom,
/// with a white dot in the head, a white outline, and a soft shadow.
class _PinShape extends CustomPainter {
  final Color color;
  _PinShape(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final head = Offset(r, r);
    // Start at the tip, curve up the left side, go over the top of the
    // round head, and curve back down the right side to the tip.
    final path = Path()
      ..moveTo(r, h)
      ..cubicTo(r - r * 0.3, h - r * 0.9, 0, r + r * 0.8, 0, r)
      ..arcTo(Rect.fromCircle(center: head, radius: r), math.pi, math.pi, false)
      ..cubicTo(w, r + r * 0.8, r + r * 0.3, h - r * 0.9, r, h)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(head, r * 0.36, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PinShape old) => old.color != color;
}

/// "Sample photo" label and photo credit, on a dark fade so it stays
/// readable on any photo.
class _PhotoCredit extends StatelessWidget {
  const _PhotoCredit();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x99000000)],
          ),
        ),
        child: const Text(
          kFloodPhotoCredit,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// The photo at the top of a flood pin's sheet. Until a real photo
/// exists (see FloodZone.photo), shows a calm placeholder with water
/// drawn at the same depth as the gauge, so it still says something.
class _ZonePhoto extends StatelessWidget {
  final FloodZone zone;
  const _ZonePhoto({required this.zone});

  @override
  Widget build(BuildContext context) {
    final color = zone.risk.color;
    // 0 cm -> no water, 180 cm -> water fills 70% of the placeholder.
    final fill = (zone.depthCm / DepthGauge.maxCm).clamp(0.0, 1.0) * 0.7;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(
          zone.photo,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // Once the photo has loaded (frame != null), lay the credit
          // over its bottom edge. The license (CC BY-SA) requires it.
          frameBuilder: (context, child, frame, _) => frame == null
              ? child
              : Stack(
                  fit: StackFit.expand,
                  children: [child, const _PhotoCredit()],
                ),
          errorBuilder: (_, _, _) => LayoutBuilder(
            builder: (context, box) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kOceanBlue, kMidnightBlue],
                ),
              ),
              child: Stack(
                children: [
                  if (fill > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedWaves(
                        height: math.max(24, box.maxHeight * fill),
                        colors: [
                          color.withValues(alpha: 0.25),
                          color.withValues(alpha: 0.35),
                          color.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  Positioned(
                    left: 14,
                    top: 12,
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'No photo yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}

/// When the pin's photo was taken, and when the pin will be removed
/// (pins only last [kPinLifetime]), so people can tell if it's still
/// happening or the photo is old.
class _PinDates extends StatelessWidget {
  final FloodZone zone;
  const _PinDates({required this.zone});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final taken = zone.photoTakenAt;
    final left = zone.timeLeft;
    final leftText = left.inDays >= 1
        ? '${left.inDays} ${left.inDays == 1 ? 'day' : 'days'}'
        : '${left.inHours} ${left.inHours == 1 ? 'hour' : 'hours'}';
    // Last 2 days: show it in orange, the photo is getting old.
    final ending = left.inDays < 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(
            c,
            Icons.photo_camera_outlined,
            'Photo taken ${formatDate(taken)}, ${formatTime(taken)} '
            '(${timeAgo(zone.photoAge)})',
            c.textPrimary,
          ),
          const SizedBox(height: 6),
          _line(
            c,
            Icons.auto_delete_outlined,
            'Pin will be removed in $leftText',
            ending ? kCaution : c.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _line(AppColors c, IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: color, fontSize: 12.5)),
        ),
      ],
    );
  }
}
