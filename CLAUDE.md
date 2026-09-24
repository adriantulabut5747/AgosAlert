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
- `lib/services/weather.dart`: live Mabalacat weather from Open-Meteo (free,
  no key) and the rain-based flood outlook.
- `lib/data/demo_data.dart`: all made-up data (rivers, flood zones, alerts,
  evacuation centers). Shown with a SAMPLE badge in the UI. A real data
  source is coming later as a file from Adrian. Barangay coordinates are
  real (OpenStreetMap).
- Optional photos: `assets/images/evac_*.jpg` (names in demo_data.dart).
  Missing files fall back to a gradient.
- `test/widget_test.dart` checks the login screen and that every screen
  renders at phone size without overflow. Use `pump()`, not
  `pumpAndSettle()`: several animations repeat forever.

## Running

- Local (home PC): `flutter run -d chrome`, `r` in the terminal to hot reload.
- Codespace (school, browser only): `flutter run -d web-server --web-port 8080`,
  then the Ports tab → port 8080.
- Check before committing: `flutter analyze` and `flutter test`.

## Deploying

Every push to `main` builds and publishes to
https://adriantulabut5747.github.io/AgosAlert/ via
`.github/workflows/deploy-pages.yml`. So a broken push to `main` breaks the
live site his groupmates screenshot — use a branch for risky changes.

## Known issues

- The Map tab uses `flutter_map` with CARTO tiles (dark/light match the
  theme). The old `staticmap.openstreetmap.de` image is gone.
- In the dark theme, the dark-navy "alert" in the logos is hard to read.
  Adrian chose to keep it as-is.

## Working with Adrian

- His **c key is broken** and he types **k** instead ("kode" = code,
  "kould" = could). Read past it.
- He's new to Flutter and git — explain the why, not just the what.
- Ask before implementing when a request has more than one reading.
- Be blunt: if an idea is weak or has a real downside, say so plainly.
- Keep replies short.
