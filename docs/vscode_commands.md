# Commands to run in VS Code

Open the terminal in VS Code with **Ctrl + `** (backtick). It starts in the project
root automatically. If it doesn't, or if you opened a fresh terminal:

```powershell
cd C:\Users\abhis\Documents\PROJECTS\Weather_RPG_CitySearch_Route_Fix
```

All commands below assume that folder.

---

## 0. One-time check

```powershell
flutter doctor
flutter devices
```

`flutter doctor` should show a green Android toolchain. `flutter devices` lists what you
can target — a `SM-...` device for a USB-connected phone, or `emulator-5554` for a
running emulator.

---

## 1. Set your API key once per terminal session

`--dart-define` is not persisted anywhere, so it must be passed on **every** `run` and
`build`. Setting it as a variable avoids retyping the key:

```powershell
$env:WEATHER_API_KEY = "paste_your_weatherapi_key_here"
```

Verify it took (prints a masked confirmation, not the key):

```powershell
if ($env:WEATHER_API_KEY) { "key loaded, length $($env:WEATHER_API_KEY.Length)" } else { "NOT SET" }
```

This resets whenever you open a new terminal, so re-run it in each new session.

---

## 2. Install dependencies

Do this once after cloning, and again any time `pubspec.yaml` changes.

```powershell
flutter pub get
```

---

## 3. Run the app

```powershell
flutter run --dart-define=WEATHER_API_KEY=$env:WEATHER_API_KEY
```

With a longer forecast than the free 3-day plan:

```powershell
flutter run --dart-define=WEATHER_API_KEY=$env:WEATHER_API_KEY --dart-define=WEATHER_FORECAST_DAYS=7
```

Target a specific device when more than one is attached:

```powershell
flutter devices
flutter run -d emulator-5554 --dart-define=WEATHER_API_KEY=$env:WEATHER_API_KEY
```

### While `flutter run` is active

These are single keystrokes in the terminal, not commands:

| Key | Action |
| --- | --- |
| `r` | hot reload — picks up your Dart edits, keeps app state |
| `R` | hot restart — full restart, clears state |
| `p` | toggle the performance overlay (frame times) |
| `q` | quit |

Use `r` for almost everything. Use `R` if a change touches `main()`, a `const`
initialiser, or global state.

---

## 4. Build a release APK

```powershell
flutter build apk --release --dart-define=WEATHER_API_KEY=$env:WEATHER_API_KEY
```

Optional longer forecast:

```powershell
flutter build apk --release --dart-define=WEATHER_API_KEY=$env:WEATHER_API_KEY --dart-define=WEATHER_FORECAST_DAYS=7
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

Install it straight onto a connected phone:

```powershell
flutter install --release
```

Or with adb directly:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

---

## 5. Tests

All tests (no API key needed — the network calls are stubbed):

```powershell
flutter test
```

Just one file:

```powershell
flutter test test\weather_scene_palette_test.dart
```

Re-generate the scene frames I used for the environment review:

```powershell
flutter test test\_probe_render.dart
```

Then open any of these from the VS Code file explorer:

```
build\probe_mumbai_rain_day.png
build\probe_delhi_clear_day.png
build\probe_london_night_clear.png
build\probe_jaisalmer_heat.png
build\probe_srinagar_snow.png
build\probe_cyclone_env.png
build\ref_vs_procedural.png
```

Open one to a side panel with:

```powershell
code build\ref_vs_procedural.png
```

---

## 6. Code quality

```powershell
flutter analyze
```

Currently reports 46 infos — 40 `withOpacity` deprecations and 6 brace-style warnings.
None are errors; see §3.5 of the review doc.

Auto-fix the mechanical ones:

```powershell
dart fix --dry-run
dart fix --apply
```

Format everything:

```powershell
dart format lib test
```

---

## 7. When something is stale or broken

```powershell
flutter clean
flutter pub get
flutter run --dart-define=WEATHER_API_KEY=$env:WEATHER_API_KEY
```

`flutter clean` removes `build\` and `.dart_tool\`, so it also deletes the probe PNGs
from §5 — regenerate them afterwards if you still want them.

If device detection is flaky:

```powershell
adb kill-server
adb start-server
flutter devices
```

---

## 8. Profiling (for the performance work in §3.3)

Profile mode, not debug — debug mode frame times are meaningless:

```powershell
flutter run --profile --dart-define=WEATHER_API_KEY=$env:WEATHER_API_KEY
```

Press `p` in the terminal for the frame-time overlay, then watch the raster thread.
The review's per-frame operation counts bound the *recording* cost; the overlay tells
you the actual GPU cost, which is where the gradient and fog overlays will show up.

---

## Quick reference

```powershell
cd C:\Users\abhis\Documents\PROJECTS\Weather_RPG_CitySearch_Route_Fix
$env:WEATHER_API_KEY = "paste_your_weatherapi_key_here"
flutter pub get
flutter run --dart-define=WEATHER_API_KEY=$env:WEATHER_API_KEY
```
