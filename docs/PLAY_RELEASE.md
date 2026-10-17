# Releasing Weather App to Google Play

## 1. Create the upload key (once)
Run from the project folder (keytool ships with Android Studio's JDK):

    keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

Then copy `android/key.properties.example` to `android/key.properties` and fill in the passwords.
Both files are git-ignored. **Back up the .jks and its passwords in two separate places.**
Keep Play App Signing turned on (the default); this key is only the *upload* key.

## 2. Build the release bundle

    flutter clean
    flutter pub get
    flutter build appbundle --release

Output: `build/app/outputs/bundle/release/app-release.aab`

## 3. Before each upload
- Bump `version:` in `pubspec.yaml` (the number after `+` must increase every upload).
- Test the release build on a real phone: `flutter run --release`.
- Confirm location permission, offline cache and city search work.

## 4. Play Console checklist
- Personal accounts created after 13 Nov 2023: closed test with 12+ testers for 14 continuous days.
- Privacy policy URL, Data safety form, content rating, target audience, store listing assets.
- Credit WeatherAPI.com and any third-party art/fonts in the app and listing.
