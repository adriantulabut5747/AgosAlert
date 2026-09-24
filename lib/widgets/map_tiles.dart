import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

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

  static const _base =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas';

  @override
  Widget build(BuildContext context) {
    final style = AppColors(context).isDark ? 'Dark' : 'Light';
    return Stack(
      children: [
        _layer('$_base/World_${style}_Gray_Base/MapServer/tile/{z}/{y}/{x}'),
        _layer(
          '$_base/World_${style}_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
        ),
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
