# Weather RPG — Flutter starter

A beginner-friendly Flutter Android starter for the Weather RPG concept.

## Included in this first build
- Dark retro RPG UI with pixel-inspired borders and colors
- Procedurally drawn, animated Monsoonal Forest scene
- A blocky goblin explorer drawn in the scene
- Animated pixel rain and periodic lightning flash
- Live current weather, feels-like temperature, humidity, wind, precipitation
- Hourly forecast with rain probability and chart
- Three-day forecast with highs/lows and rain probability (configurable for plans with longer forecasts)
- Weather and city search using WeatherAPI.com
- Saved city list for cities searched during the current session
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
- The pixel forest and goblin are drawn procedurally for this prototype. They are not yet the final extracted sprite assets from the approved reference atlas.
- Theme and saved cities are in-memory in this starter; persistence can be added in a later milestone.
