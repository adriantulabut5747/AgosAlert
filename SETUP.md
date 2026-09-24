# Setup — AgosAlert

Two ways to work on this. Pick whichever fits the machine you're on.

## Option A — Cloud (Codespaces)

Use this on any computer where you can't install software (e.g. school PCs).
Runs entirely in the browser.

1. Go to the repo: https://github.com/adriantulabut5747/AgosAlert
2. Green **Code** button → **Codespaces** tab → **Create codespace on main**
3. Wait ~1-2 min for the first build (Flutter comes pre-installed via
   `.devcontainer/devcontainer.json` — nothing to install yourself).
4. In the terminal that opens:
   ```
   flutter run -d web-server --web-port 8080
   ```
5. A popup gives you a link to the running app.

**Free limit:** 120 core-hours/month per person on the default 2-core machine,
which works out to ~60 hours of actual runtime. It auto-stops after 30 min
idle, but stop it manually when you're done to be safe (github.com/codespaces
→ "..." → Stop).

## Option B — Local

Use this on your own computer if you want faster iteration and don't mind
the one-time install.

1. Clone the Flutter SDK (this downloads the SDK itself, not a package):
   ```
   git clone -b stable https://github.com/flutter/flutter.git C:\src\flutter
   ```
2. Add `C:\src\flutter\bin` to your PATH (Windows: search "Environment
   Variables" → Edit your user PATH → add the folder).
3. Restart your terminal, then verify:
   ```
   flutter doctor
   ```
4. Clone this repo and get dependencies:
   ```
   git clone https://github.com/adriantulabut5747/AgosAlert.git
   cd AgosAlert
   flutter pub get
   ```
5. Run it in Chrome (no Android Studio needed for this):
   ```
   flutter run -d chrome
   ```

Android Studio / an Android SDK is only needed if you want to build an
installable `.apk`. Not required to develop or demo the app.

## Either way

- Edits to `lib/main.dart` hot-reload automatically while `flutter run` is
  active — save the file and the running app updates without restarting.
- Commit and push like a normal git repo. `build/`, `.dart_tool/`, and
  `.idea/` are gitignored — don't manually add files from those folders.
