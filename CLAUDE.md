# AgosAlert

Flutter flood-monitoring app for Mabalacat City, Pampanga. A school group
project: Adrian writes all the code, his groupmates only do the paperwork.

## Layout

- `lib/main.dart` only starts the app. `lib/theme.dart` has the colors,
  font (Plus Jakarta Sans, bundled in `assets/fonts/`), and `RiskLevel`.
- `lib/screens/`: one file per screen: login, home shell (top bar + bottom
  nav), the five tabs (home, map, alerts, assistance, more), plus
  evacuation centers, report incident, settings, and about/help.
- `lib/widgets/common.dart`: shared building blocks (AppCard,
  GradientButton, FadeSlideIn, AnimatedWaves, showAppSheet...). Reuse
  these instead of restyling from scratch. `lib/widgets/links.dart`:
  tap-to-call (always asks first) and Google Maps directions.
- Custom icons, drawn from SVG path strings (via `path_drawing`):
  `lib/widgets/nav_icons.dart` = the nav tabs, one color, Facebook-style
  (gray outline, solid blue when selected, no highlight pill: Adrian
  rejected both the pill and two-tone nav icons). `lib/widgets/duo_icons.dart`
  = the Assistance tab's two-tone navy + cyan icons (Get help tiles,
  hotlines), which Adrian likes as they are.
- `lib/services/weather.dart`: live Mabalacat weather from Open-Meteo (free,
  no key) and the rain-based flood outlook.
- `lib/data/demo_data.dart`: all made-up data (flood zones, alerts,
  evacuation centers). Shown with a SAMPLE badge in the UI. A real data
  source is coming later as a file from Adrian. Barangay coordinates are
  real (OpenStreetMap).
- Optional photos: `assets/images/evac_*.jpg` (names in demo_data.dart)
  and `assets/images/flood_<barangay>.jpg` for map pins (lowercase,
  spaces → `_`, e.g. `flood_dau.jpg`). Missing files fall back to a
  placeholder. The current flood photos are from Apalit, Pampanga
  (Wikimedia Commons, CC BY-SA 4.0): keep the credit (`kFloodPhotoCredit`
  in demo_data.dart, and the About screen) while they're used.
- Phone / tablet / desktop layouts: `lib/widgets/responsive.dart`
  (breakpoints 600 and 1024, `pagePadding`, `TwoColumns`). Phones keep
  the bottom nav; tablets and desktops get a top nav (icons only on
  tablets) with a profile menu instead of the More tab, and
  `showAppSheet` opens a centered popup instead of a bottom sheet.
  Desktop has its own layouts for Home (two columns), Map (side panel),
  Alerts (list + details), Assistance, and Login (photo panel).
- Evacuation centers show open/standby and distance only: no occupancy
  or capacity (nobody can count people inside a center).
- Home banner photo: `photo_rainy_night.jpg` in the dark theme,
  `photo_rainy_day.jpg` in the light theme. Adrian's own photos, so their
  `LocalPhoto` credit is empty (no label on the photo, not on About).
- Hotlines (`kHotlines`): the city's official list (CDRRMO, BFP, PNP x2,
  MCTEG) plus 911 and City Hall; the landing page lists the same seven.
- "Mabalaquenian(s)" = residents of Mabalacat. Adrian likes the word; it's
  used on purpose in a few spots (Home greeting, hotline sign-off, alerts
  empty state, safety tips, landing greeting/footer, register popup).
- Style ("calm water"): no glows or gradient-filled tiles; the thin
  `WaterLines` pattern is the signature. Local identity: real local
  photos (`LocalPhoto` in demo_data.dart, credits shown on the photo and
  listed on About) and Kapampangan greetings (Home banner, landing page).
- **No login screen in the app.** Logging in happens on the landing page
  (`landing/`, plain HTML/CSS/JS), whose popup opens the app as
  `app/?as=user|guest&theme=light|dark` (optional `&tab=map` etc.).
  `lib/services/session.dart` reads that; on the published site, /app/
  without `as=` redirects to the landing page. Log in / Log out in the
  app go back to the landing page (`lib/screens/account.dart`).
- Roles: Admin, Registered User, Guest. For now only guest vs logged-in
  exists: `isGuest` (demo_data.dart, set from `?as=`). When a guest taps
  something they can't do, call `showLoginRequired` (account.dart).
  Votes on flood pins live in `myVotes` (memory only).
- No real offices as the app's admin: the admins aren't confirmed yet, so
  the app says "Admin" (`kAdminSource`) and calls itself an unofficial demo.
  Real emergency hotlines (CDRRMO, PNP...) stay as they are.
- No river-level card: the only PhilSensors (DOST-ASTI) stations in
  Mabalacat are offline (water level #762 San Felipe Bridge, last reading
  2019; rain gauges #699 and #2908, last 2022). Don't fake live river
  data; only bring it back with a real, working source.
- Flood pins are removed 14 days after their photo was taken
  (`kPinLifetime`); the map only shows `activeFloodZones`.
- Each pin has an uploader (`kUploaders`, sample names). The Home feed
  ("Latest flood reports") shows the pins as posts; `VoteBar` and
  `PostedBy` / `showUserProfile` (lib/widgets/) are shared by the feed
  and the pin popup. "View on map" sets `focusedZone`, which the Map tab
  listens to.
- `lib/widgets/flood_depth.dart`: flood depth levels (ankle → over head),
  cm/ft, the gauge drawing, and the depth → risk cut-offs (≤20 cm normal,
  ≤50 moderate, else high) that the map legend also shows.
- `test/widget_test.dart` checks the app opens on Home and that every screen
  renders at phone size without overflow. Use `pump()`, not
  `pumpAndSettle()`: several animations repeat forever.

## Running

- Local (home PC): `flutter run -d chrome`, `r` in the terminal to hot reload.
- Codespace (school, browser only): `flutter run -d web-server --web-port 8080`,
  then the Ports tab → port 8080.
- Add `--release` to preview at real size (~4 MB instead of ~100 MB for
  debug), but then there's no hot reload.
- The loading screen (logo filling with water, bubbles, waves) is plain
  HTML/CSS in `web/index.html` (Adrian wants no skeleton card there), driven by `web/flutter_bootstrap.js` (hidden on
  Flutter's `flutter-first-frame`). `index.html` also preloads
  `main.dart.js`, the fonts, and the asset manifests. If you add or rename
  a font, update those preload links too.
- Every page except Home is deferred (downloaded on first use,
  with a skeleton meanwhile): Map, Alerts, Assistance, More, Report,
  Settings, Help, About. Always open them through
  `lib/screens/deferred_screens.dart` (never import those screen files
  from Home, the shell, or shared widgets), and keep `flutter_map` /
  `image_picker` imports out of every other file, or they'll end up back
  in the first download.
- In-app loading placeholders live in `lib/widgets/skeleton.dart`.
- Check before committing: `flutter analyze` and `flutter test`.

## Deploying

Every push to `main` publishes, via `.github/workflows/deploy-pages.yml`:
- the landing page (`landing/`) at https://adriantulabut5747.github.io/AgosAlert/
- the Flutter app at https://adriantulabut5747.github.io/AgosAlert/app/
  (built with `--base-href /AgosAlert/app/`)

So a broken push to `main` breaks the live site his groupmates
screenshot — use a branch for risky changes.

## Landing page (`landing/`)

- Hero modeled on a dribbble-style app landing: two tilted CSS phones
  (Home in front, Map behind) with real app screenshots in
  `landing/img/{home,map}-{dark,light}.webp` (390 wide at 2x, taken with
  the status bar left out; the page draws its own), slightly blurred on
  purpose. Retake them when the Home or Map tab changes visibly.
- The weather card and flood outlook chip popping out of the front phone
  are live (Open-Meteo, same request and rules as weather.dart, ported to
  landing.js). So are the numbers in "How it works" cards 1-2. Keep the
  outlook rule in sync with `floodOutlook` in weather.dart.
- Sections below the hero: 01 How it works (4 cards, no phone mockups:
  Adrian asked for none), 02 Hotlines (same numbers as kHotlines, plus a
  "save all" .vcf download), 03 Coverage (SVG map from OpenStreetMap:
  city boundary + all 27 barangays, drawn once with Python, not live),
  04 FAQ. The section 03 photo (`bridge-arayat.webp`) is Adrian's own, so no
  credit; any Wikimedia photo added later needs its credit shown.
- Top bar: round theme button (Adrian tried a sliding day/night switch
  and preferred the round button), Log in, and "Continue as guest"
  (straight to `app/?as=guest`, "Guest" on phones).
- "Coming soon" store badges on purpose: the app isn't on either store,
  and Adrian chose not to fake it. Same for the testimonial/award spots
  of the reference: replaced by a barangay coverage card and the
  unofficial-demo notice.
- Kapampangan greeting by Manila time: abak (5-11), ugtu (11-13),
  gatpanapun (13-18), bengi (18-5).
- Preview locally: serve the folder (`python -m http.server` in
  `landing/`). Login links go to `app/`, which only exists after the
  deploy's copy step (or a local `flutter build web --base-href /app/`
  copied into `landing/app/`, which is gitignored).

## Known issues

- Maps use `flutter_map` with Esri's free Canvas tiles (light/dark gray +
  a labels layer, no key) in `lib/widgets/map_tiles.dart`. Don't use
  CARTO (stamps "API KEY REQUIRED") or tile.openstreetmap.org (blocks
  flutter_map web apps with "Access blocked"). When checking a tile
  source, look at the actual image, not just the HTTP status.
- The Map tab is locked to `kMabalacatBounds` (demo_data.dart) with a
  minimum zoom of 13. A test checks that it can't be dragged outside.
- In the dark theme, the dark-navy "alert" in the logos is hard to read.
  Adrian chose to keep it as-is.

## Working with Adrian

- His **c key is broken** and he types **k** instead ("kode" = code,
  "kould" = could). Read past it.
- He's new to Flutter and git — explain the why, not just the what.
- Ask before implementing when a request has more than one reading.
- Be blunt: if an idea is weak or has a real downside, say so plainly.
- Keep replies short.
