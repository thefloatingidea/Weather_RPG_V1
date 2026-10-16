# Weather RPG — Flutter starter

A beginner-friendly Flutter Android starter for the Weather RPG concept.

## Included in this first build
- Dark retro RPG UI with pixel-inspired borders and colors
- Procedurally drawn, animated Monsoonal Forest scene
- A pixel-art goblin explorer with 8-frame idle and 8-frame walk animations
  (sprite frames in `assets/images/goblin_frames`), plus procedural weather
  reactions layered on top
- Animated pixel rain and periodic lightning flash
- Live current weather, feels-like temperature, humidity, wind, precipitation
- Hourly forecast with rain probability and chart
- Three-day forecast with highs/lows and rain probability (configurable for plans with longer forecasts)
- Weather and city search using WeatherAPI.com
- Saved places you can remove and give nicknames to, with legacy lists migrated
  automatically
- A goblin journal that tracks landmarks, weather memories, seasons and visits as a
  collection, with locked entries for what is still undiscovered
- Extreme-weather set-pieces (cyclone, flood, sandstorm, desert heat) selected from
  the live reading, switchable in Settings
- A time-of-day lighting model: the sun and moon follow an arc driven by the local
  hour, with a warm cast at dawn and dusk
- Theme and saved cities persist on device
- Light, dark and system theme choices
- Celsius/Fahrenheit display option
- WeatherAPI.com attribution
- Pull-to-refresh

## Requirements
- Flutter stable SDK
- Android SDK platform/build tools
- VS Code or Android Studio as editor (Android Studio is needed to install SDK tools if you don't already have them)

Official setup guide:
https://docs.flutter.dev/platform-integration/android/setup

## Setup on Windows
1. Extract this ZIP into a folder such as `D:\WeatherRPG`.
2. Open that folder in VS Code.
3. Open Terminal > New Terminal.
4. Run:
   flutter create .
5. Ensure `android/app/src/main/AndroidManifest.xml` includes the INTERNET permission.
   This ZIP includes a manifest with that permission; if `flutter create .` overwrites it, restore this supplied manifest.
6. Run:
   flutter pub get
   flutter doctor
7. Connect an Android phone with USB debugging enabled, or start an emulator.
8. Pass your WeatherAPI.com key when running the app:
   flutter devices
   flutter run --dart-define=WEATHER_API_KEY=your_key

## Build APK
Run (replace `your_key` with your WeatherAPI.com key):
   flutter build apk --release --dart-define=WEATHER_API_KEY=your_key

The free WeatherAPI.com plan supports a three-day forecast. If your account
supports a longer forecast, set `WEATHER_FORECAST_DAYS` to the number of days
when running or building the app, for example:

   flutter build apk --release --dart-define=WEATHER_API_KEY=your_key --dart-define=WEATHER_FORECAST_DAYS=7

Expected output:
   build/app/outputs/flutter-apk/app-release.apk

## Data and safety notes
- Default location is Mumbai. GPS permission is not requested in this first version; use city search instead.
- Weather data and city search come from WeatherAPI.com. The app credits the provider in its UI. Do not commit your API key. A key passed to a Flutter mobile build is bundled in the app and can be extracted; use a server-side proxy with key restrictions for a public commercial release.
- The storm banner is a condition summary, not an official emergency warning. This version does not integrate government alert feeds.
- The character is animated from the sprite frames in `assets/images/goblin_frames`.
  The environment (sky, terrain, landmarks, weather) is still drawn procedurally in
  Flame. If the sprite frames fail to load, the scene falls back to the procedural
  character rather than dropping it.
- The extreme-weather set-pieces are decorative scenes, not hazard advisories. They
  are chosen from the current reading by `resolveSceneEnvironment` in
  `weather_rules.dart` and can be turned off in Settings.
- Theme, saved places, and the character journal persist on device via
  `shared_preferences`. The weather response is cached so the last forecast is
  visible offline.
