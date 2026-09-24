import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../theme.dart';

/// OpenStreetMap tiles: free, no API key. (CARTO used to be free too, but
/// now stamps "API KEY REQUIRED" on every tile.)
///
/// OpenStreetMap only has a light style, so in dark mode we recolor it:
/// invert the colors, then turn the hue back so water stays blue.
class AppTileLayer extends StatelessWidget {
  const AppTileLayer({super.key});

  static const credits = '© OpenStreetMap contributors';

  @override
  Widget build(BuildContext context) {
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      // OpenStreetMap asks apps to identify themselves.
      userAgentPackageName: 'com.agosalert.app',
      maxNativeZoom: 19,
    );
    if (!AppColors(context).isDark) return tiles;
    return ColorFiltered(colorFilter: _darkMap, child: tiles);
  }

  // Invert + rotate hue 180° (so blues stay blue), slightly dimmed to
  // match the app's navy background.
  static const _darkMap = ColorFilter.matrix(<double>[
    0.52, -1.29, -0.13, 0, 225, //
    -0.38, -0.39, -0.13, 0, 225, //
    -0.38, -1.29, 0.77, 0, 235, //
    0, 0, 0, 1, 0, //
  ]);
}
