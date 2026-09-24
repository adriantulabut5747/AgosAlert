import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/links.dart';

/// ============================================================
/// MAP TAB — interactive map of Mabalacat City (OpenStreetMap
/// data, CARTO map style) with flood zones and evacuation centers
/// ============================================================
class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final _map = MapController();
  bool _showZones = true;
  bool _showCenters = true;

  static const _startZoom = 13.3;

  void _zoom(double by) {
    final cam = _map.camera;
    _map.move(cam.center, (cam.zoom + by).clamp(11, 18));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    // Dark map in dark mode, light map in light mode.
    final tiles = c.isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: kMabalacatCenter,
                initialZoom: _startZoom,
                minZoom: 11,
                maxZoom: 18,
                backgroundColor: c.surfaceAlt,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  key: ValueKey(tiles),
                  urlTemplate: tiles,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.agosalert.app',
                ),
                if (_showZones)
                  CircleLayer(
                    circles: [
                      for (final z in kFloodZones)
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
                MarkerLayer(
                  markers: [
                    if (_showZones)
                      for (final z in kFloodZones)
                        Marker(
                          point: z.point,
                          width: 52,
                          height: 52,
                          child: GestureDetector(
                            onTap: () => _showZone(context, z),
                            child: _PulsingPin(
                              color: z.risk.color,
                              pulse: z.risk != RiskLevel.normal,
                            ),
                          ),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x55000000),
                                    blurRadius: 8,
                                  ),
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
                // Map credits (required by OpenStreetMap and CARTO)
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 14, top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '© OpenStreetMap contributors © CARTO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textSecondary, fontSize: 9.5),
                    ),
                  ),
                ),
              ],
            ),
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
            // Zoom + recenter buttons
            Positioned(
              right: 12,
              bottom: 170,
              child: Column(
                children: [
                  _mapButton(c, Icons.add_rounded, 'Zoom in', () => _zoom(1)),
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
            ),
            // Legend
            Positioned(
              left: 12,
              right: 12,
              bottom: 96,
              child: _glass(
                c,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _legend(c, kDanger, 'High', '> 1.5 m'),
                    _legend(c, kCaution, 'Moderate', '0.5–1.5 m'),
                    _legend(c, kSafe, 'Normal', '< 0.5 m'),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _legend(AppColors c, Color color, String label, String range) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
      ],
    );
  }

  void _showZone(BuildContext context, FloodZone z) {
    final color = z.risk.color;
    _map.move(z.point, 15);
    showAppSheet(
      context,
      builder: (sheet) {
        final c = AppColors(sheet);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(Icons.location_on_rounded, color, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brgy. ${z.barangay}',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Mabalacat City',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill('${z.risk.label} risk', color, solid: true),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _statBox(c, 'Water level', '${z.waterLevel} m', color),
                ),
                const SizedBox(width: 10),
                Expanded(child: _statBox(c, 'Updated', '12 min ago', c.accent)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              z.note,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _guidance(z.risk),
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
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

  String _guidance(RiskLevel risk) => switch (risk) {
    RiskLevel.high => 'Move to higher ground now and avoid this area until the water goes down.',
    RiskLevel.moderate => 'Stay alert and keep checking for updates. Avoid unnecessary travel here.',
    RiskLevel.normal => 'Conditions are normal. No action needed right now.',
  };
}

class _PulsingPin extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _PulsingPin({required this.color, this.pulse = true});

  @override
  State<_PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<_PulsingPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.pulse)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => Container(
                width: 18 + 34 * _ctrl.value,
                height: 18 + 34 * _ctrl.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(
                    alpha: 0.45 * (1 - _ctrl.value),
                  ),
                ),
              ),
            ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
