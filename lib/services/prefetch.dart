import 'package:flutter/foundation.dart' show kIsWeb;

import '../screens/deferred_screens.dart';
import 'map_tile_urls.dart';
import 'weather.dart';

/// Starts downloading what the other tabs need (live weather, the Map tab
/// and Report screen code, the first map tiles) while the user is still
/// looking at Home. When they switch tabs, it's already there.
///
/// Called once, right after Home first appears (HomeShell.initState), so
/// it never slows down the loading screen itself. Website only: an installed app
/// already has its code on the phone (and tests shouldn't hit the network).
///
/// None of the three calls is awaited: they all run in the background at
/// the same time, and this function returns immediately.
void prefetchAppContent({required bool dark}) {
  // kIsWeb = true when running in a browser. _started makes sure this
  // only ever runs once (e.g. not again after logging out and back in).
  if (!kIsWeb || _started) return;
  _started = true;
  MabalacatWeather.load();
  preloadDeferredScreens();
  prefetchStartingMapTiles(dark: dark);
}

bool _started = false;
