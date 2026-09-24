import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../data/demo_data.dart';

/// Esri map tile addresses, shared by the map (widgets/map_tiles.dart)
/// and the prefetcher below. Kept free of the flutter_map package so it can
/// be part of the first download.
const _base = 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas';

/// Tile address template, e.g. for the dark map's labels layer.
String esriTileTemplate({required bool dark, required bool labels}) {
  final style = dark ? 'Dark' : 'Light';
  final layer = labels ? 'Reference' : 'Base';
  return '$_base/World_${style}_Gray_$layer/MapServer/tile/{z}/{y}/{x}';
}

/// Downloads the tiles the Map tab shows first (around the city center),
/// so the browser has them cached (Esri allows 24 h) when the tab opens.
/// About 18 small images. Errors are ignored: it's only a head start.
Future<void> prefetchStartingMapTiles({required bool dark}) async {
  const zoom = 13; // the Map tab opens at 13.3, which uses zoom-13 tiles
  final n = math.pow(2, zoom);
  final lat = kMabalacatCenter.latitude * math.pi / 180;
  final x = ((kMabalacatCenter.longitude + 180) / 360 * n).floor();
  final y =
      ((1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * n)
          .floor();

  final requests = <Future<void>>[];
  for (final labels in [false, true]) {
    final template = esriTileTemplate(dark: dark, labels: labels);
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final url = template
            .replaceAll('{z}', '$zoom')
            .replaceAll('{x}', '${x + dx}')
            .replaceAll('{y}', '${y + dy}');
        requests.add(
          http.get(Uri.parse(url)).then((_) {}, onError: (Object _) {}),
        );
      }
    }
  }
  await Future.wait(requests);
}
