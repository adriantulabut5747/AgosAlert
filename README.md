# AgosAlert (Flutter app)

Flood alerts for every barangay in Mabalacat City, Pampanga.

**Live site:** https://adriantulabut5747.github.io/AgosAlert/
**Open the app:** https://adriantulabut5747.github.io/AgosAlert/app/ (log in, or continue as a guest)
**Website version (Laravel):** https://github.com/adriantulabut5747/agosalertweb

> Unofficial demo. AgosAlert is a school capstone project by BSIT students. It is not made by, or connected to, the Mabalacat City government. For official warnings, follow PAGASA and the Mabalacat CDRRMO.

## Two builds, one system

AgosAlert is built twice, for two subjects:

| | This repo (`agosalertapp`) | [`agosalertweb`](https://github.com/adriantulabut5747/agosalertweb) |
| --- | --- | --- |
| Built with | Flutter (web + Android) | Laravel + Blade |
| Database and accounts | Supabase | the same Supabase project |

Both use **one database and one set of accounts**, so a report posted in the app shows on the website and the other way round.

## What it does

The app has four tabs:

- **Weather:** live Mabalacat weather, the next 5 days, and a flood outlook estimated from the rain forecast. Tugak, the app's toad, says what to do first.
- **Map:** the whole city in 2D or 3D, with flood reports and evacuation centers.
- **Reports:** flood posts from residents, each with a photo, a pin and the water depth. Logged-in users can post and vote. A report disappears 14 days after its photo was taken.
- **Help:** SOS (911), local hotlines, evacuation centers, an "I'm safe" message, a rescue request form, and a before / during / after checklist.

Also: accounts (log in, sign up, forgot password, change name and password, delete account), alerts under the bell, and an **Admin** page for admins (rescue requests, verify / hide reports, post alerts, evacuation centers, suspend users).

Evacuation centers are still sample data, marked SAMPLE. Rescue requests are saved, but **nobody monitors them yet**: the app says so and tells people to call 911.

## Built with

- [Flutter](https://flutter.dev), [Supabase](https://supabase.com) for accounts, reports, votes, alerts, centers and rescue requests (tables in `supabase/*.sql`)
- [MapLibre GL JS](https://maplibre.org) with map tiles from [Protomaps](https://protomaps.com) / [OpenStreetMap](https://www.openstreetmap.org/copyright)
- Weather and air quality from [Open-Meteo](https://open-meteo.com)
- The landing page (`landing/`) is plain HTML, CSS and JavaScript

## Run it locally

```sh
flutter pub get
flutter run -d chrome
```

Before committing: `flutter analyze` and `flutter test`.

Every push to `main` builds the app and publishes the landing page plus the app to GitHub Pages (`.github/workflows/deploy-pages.yml`).

## Legal

[Privacy Policy](https://adriantulabut5747.github.io/AgosAlert/privacy.html) ·
[Terms of Use](https://adriantulabut5747.github.io/AgosAlert/terms.html) ·
[Copyright and takedown](https://adriantulabut5747.github.io/AgosAlert/takedown.html)

## Credits

- Map data © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors
- Weather: [Open-Meteo.com](https://open-meteo.com)
- Landing page photos: John Dexter Pimentel
