import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../data/demo_data.dart';

/// Esri map tile addresses, shared by the map (widgets/map_tiles.dart)
/// and the prefetcher below. Kept free of the flutter_map package so it can
/// be part of the first download.
const _base = 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas';

/// Tile address template, e.g. for the dark map's labels layer.
///
/// A web map isn't one big picture: it's a grid of small 256x256 images
/// ("tiles"). {z} is the zoom level, {x}/{y} the tile's column/row in the
/// grid. The map fills these in for every tile it needs on screen.
String esriTileTemplate({required bool dark, required bool labels}) {
  final style = dark ? 'Dark' : 'Light';
  final layer = labels ? 'Reference' : 'Base';
  return '$_base/World_${style}_Gray_$layer/MapServer/tile/{z}/{y}/{x}';
}

Future<void> prefetchStartingMapTiles({required bool dark}) async {
  const zoom = 13; // the Map tab opens at 13.3, which uses zoom-13 tiles

  final n = math.pow(2, zoom);
  final lat = kMabalacatCenter.latitude * math.pi / 180;
  final x = ((kMabalacatCenter.longitude + 180) / 360 * n).floor();
  final y =
      ((1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * n)
          .floor();

  // Download a 3x3 block of tiles around that center tile (dx and dy go
  // -1, 0, +1), for both layers (map + labels): 2 x 9 = 18 downloads.
  // They all start at once, and Future.wait waits for all of them.
  // The response is thrown away: the point is only that the browser now
  // has them in its cache, so the map loads them instantly later.
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
