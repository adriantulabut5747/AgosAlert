import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../services/map_tile_urls.dart';
import '../theme.dart';

/// Map background from Esri's free "Canvas" basemaps: no API key, and
/// they work from any website. Two layers each: the map itself, then
/// street/place names on top. Light gray in light mode, dark gray in dark
/// mode.
///
/// Why not the others:
/// - CARTO stamps "API KEY REQUIRED" on its free tiles.
/// - OpenStreetMap blocks flutter_map web apps ("Access blocked").
class AppTileLayer extends StatelessWidget {
  const AppTileLayer({super.key});

  static const credits = 'Esri, HERE, Garmin, © OpenStreetMap contributors';

  @override
  Widget build(BuildContext context) {
    final dark = AppColors(context).isDark;
    return Stack(
      children: [
        _layer(esriTileTemplate(dark: dark, labels: false)),
        _layer(esriTileTemplate(dark: dark, labels: true)),
      ],
    );
  }

  TileLayer _layer(String url) => TileLayer(
    key: ValueKey(url),
    urlTemplate: url,
    userAgentPackageName: 'com.agosalert.app',
    // Esri's canvas maps stop at zoom 16; closer zooms enlarge those tiles.
    maxNativeZoom: 16,
    // No on-device tile cache: not needed for the demo, and it keeps
    // tests working (the cache needs a phone-only plugin).
    tileProvider: NetworkTileProvider(
      cachingProvider: const DisabledMapCachingProvider(),
    ),
  );
}
