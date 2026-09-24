# AgosAlert

Flutter flood-monitoring app for Mabalacat City, Pampanga. A school group
project: Adrian writes all the code, his groupmates only do the paperwork.

## Layout

- The whole app is in `lib/main.dart` (~1,950 lines): theme, login screen,
  and the five tabs (Home, Map, Alerts, Assistance, More) plus the Report
  Incident screen.
- All data is hard-coded demo data (alerts, river levels, evacuation
  centers). A real data source is coming later as a file from Adrian.
- `test/widget_test.dart` checks that the login screen loads. Use `pump()`,
  not `pumpAndSettle()` — the logo glow animation repeats forever.

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

- The Map tab loads its image from `staticmap.openstreetmap.de`, which no
  longer exists, so it always shows the offline fallback. Adrian said to
  leave it for now.

## Working with Adrian

- His **c key is broken** and he types **k** instead ("kode" = code,
  "kould" = could). Read past it.
- He's new to Flutter and git — explain the why, not just the what.
- Ask before implementing when a request has more than one reading.
- Be blunt: if an idea is weak or has a real downside, say so plainly.
- Keep replies short.
