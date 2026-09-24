import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';

import '../data/demo_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'assistance_tab.dart';

/// ============================================================
/// REPORT INCIDENT — type, severity, photo, location, notes
/// (front end only: nothing is sent yet)
/// ============================================================
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  static const _types = [
    (Icons.flood_rounded, 'Flooding'),
    (Icons.block_rounded, 'Blocked road'),
    (Icons.landslide_rounded, 'Landslide'),
    (Icons.electrical_services_rounded, 'Fallen power line'),
    (Icons.groups_rounded, 'Stranded people'),
    (Icons.more_horiz_rounded, 'Other'),
  ];

  String? _type;
  RiskLevel _severity = RiskLevel.moderate;
  String _barangay = 'Poblacion';
  Uint8List? _photo;
  bool _submitting = false;
  final _map = MapController();

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _photo = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t open the photo picker.')),
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    await showSuccessDialog(
      context,
      title: 'Report submitted (demo)',
      message:
          'Thanks for reporting $_type in Brgy. $_barangay. In the full app, the CDRRMO would review it.\n\nNothing was actually sent yet.',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    final point = kBarangayPoints[_barangay] ?? kMabalacatCenter;
    return SubpageScaffold(
      title: 'Report incident',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Help your neighbors by reporting what you see.',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const FieldLabel('What happened?'),
              GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  for (final (icon, label) in _types) _typeTile(c, icon, label),
                ],
              ),
              const SizedBox(height: 22),
              const FieldLabel('How serious is it?'),
              Row(
                children: [
                  for (final level in RiskLevel.values) ...[
                    if (level != RiskLevel.normal) const SizedBox(width: 8),
                    Expanded(
                      child: PressableScale(
                        onTap: () => setState(() => _severity = level),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _severity == level
                                ? level.color
                                : level.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                level.icon,
                                size: 20,
                                color: _severity == level
                                    ? Colors.white
                                    : level.color,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level == RiskLevel.normal
                                    ? 'Minor'
                                    : level.label,
                                style: TextStyle(
                                  color: _severity == level
                                      ? Colors.white
                                      : level.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              const FieldLabel('Photo (optional)'),
              _photoBox(c),
              const SizedBox(height: 22),
              const FieldLabel('Where?'),
              BarangayDropdown(
                value: _barangay,
                onChanged: (v) {
                  setState(() => _barangay = v);
                  _map.move(kBarangayPoints[v] ?? kMabalacatCenter, 14.5);
                },
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 150,
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 14.5,
                      backgroundColor: c.surfaceAlt,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: c.isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                            : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.agosalert.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: Icon(
                              Icons.location_on_rounded,
                              color: _severity.color,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const FieldLabel('Details (optional)'),
              const AppTextField(
                hint: 'e.g. Water is waist-deep near the chapel',
                maxLines: 3,
              ),
              const SizedBox(height: 26),
              GradientButton(
                label: _type == null ? 'Choose what happened' : 'Submit report',
                icon: Icons.send_rounded,
                loading: _submitting,
                onPressed: _type == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTile(AppColors c, IconData icon, String label) {
    final selected = _type == label;
    return PressableScale(
      onTap: () => setState(() => _type = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.15) : c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? c.accent : c.textSecondary, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? c.textPrimary : c.textSecondary,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoBox(AppColors c) {
    if (_photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Image.memory(
              _photo!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: PressableScale(
                onTap: () => setState(() => _photo = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget option(IconData icon, String label, ImageSource source) => Expanded(
      child: PressableScale(
        onTap: () => _pickPhoto(source),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: c.accent, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        option(Icons.photo_camera_rounded, 'Take photo', ImageSource.camera),
        const SizedBox(width: 10),
        option(Icons.photo_library_rounded, 'Upload', ImageSource.gallery),
      ],
    );
  }
}
