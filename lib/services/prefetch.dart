import 'package:flutter/foundation.dart' show kIsWeb;

import '../screens/deferred_screens.dart';
import 'map_tile_urls.dart';
import 'weather.dart';

/// Starts downloading what the app needs after login (live weather, the
/// Map tab and Report screen code, the first map tiles) while the user is
/// still on the login screen. When they tap Login, it's already there.
///
/// Called once, right after the login screen first appears, so it never
/// slows down the loading screen itself. Website only: an installed app
/// already has its code on the phone (and tests shouldn't hit the network).
void prefetchAppContent({required bool dark}) {
  if (!kIsWeb || _started) return;
  _started = true;
  MabalacatWeather.load();
  preloadDeferredScreens();
  prefetchStartingMapTiles(dark: dark);
}

bool _started = false;
