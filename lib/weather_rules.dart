import 'package:flutter/foundation.dart';

/// Shared interpretation of normalized weather codes and measurements.
///
/// Thresholds describe artwork intensity; they are not hazard advisories.
const strongHeatThresholdC = 35.0;
const extremeHeatThresholdC = 40.0;
const windyThresholdKmh = 35.0;
const strongWindThresholdKmh = 45.0;
const galeWindThresholdKmh = 70.0;

/// Normalized weather categories for gameplay and rendering decisions.
enum WeatherCategory { clear, cloudy, rain, snow, thunder, fog, unknown }

/// Maps a raw WeatherAPI.com condition code to a [WeatherCategory].
///
/// Unknown codes are logged in debug mode and mapped to
/// [WeatherCategory.unknown] — never to [WeatherCategory.clear], which would
/// misreport a blizzard as sunshine.
WeatherCategory categoryForCode(int code) {
  if (_codeToCategory.containsKey(code)) {
    return _codeToCategory[code]!;
  }
  if (kDebugMode) {
    debugPrint('WeatherRules: unmapped WeatherAPI condition code $code');
  }
  return WeatherCategory.unknown;
}

const Map<int, WeatherCategory> _codeToCategory = {
  1000: WeatherCategory.clear,
  1003: WeatherCategory.cloudy,
  1006: WeatherCategory.cloudy,
  1009: WeatherCategory.cloudy,
  1030: WeatherCategory.fog,
  1063: WeatherCategory.rain,
  1066: WeatherCategory.snow,
  1069: WeatherCategory.snow,
  1072: WeatherCategory.rain,
  1087: WeatherCategory.thunder,
  1114: WeatherCategory.snow,
  1117: WeatherCategory.snow,
  1135: WeatherCategory.fog,
  1147: WeatherCategory.fog,
  1150: WeatherCategory.rain,
  1153: WeatherCategory.rain,
  1168: WeatherCategory.rain,
  1171: WeatherCategory.rain,
  1180: WeatherCategory.rain,
  1183: WeatherCategory.rain,
  1186: WeatherCategory.rain,
  1189: WeatherCategory.rain,
  1192: WeatherCategory.rain,
  1195: WeatherCategory.rain,
  1198: WeatherCategory.rain,
  1201: WeatherCategory.rain,
  1204: WeatherCategory.snow,
  1207: WeatherCategory.snow,
  1210: WeatherCategory.snow,
  1213: WeatherCategory.snow,
  1216: WeatherCategory.snow,
  1219: WeatherCategory.snow,
  1222: WeatherCategory.snow,
  1225: WeatherCategory.snow,
  1237: WeatherCategory.snow,
  1240: WeatherCategory.rain,
  1243: WeatherCategory.rain,
  1246: WeatherCategory.rain,
  1249: WeatherCategory.snow,
  1252: WeatherCategory.snow,
  1255: WeatherCategory.snow,
  1258: WeatherCategory.snow,
  1261: WeatherCategory.snow,
  1264: WeatherCategory.snow,
  1273: WeatherCategory.thunder,
  1276: WeatherCategory.thunder,
  1279: WeatherCategory.snow,
  1282: WeatherCategory.snow,
};

class WeatherConditions {
  const WeatherConditions({
    required this.code,
    required this.temperatureC,
    required this.precipitationMm,
    required this.windKmh,
    required this.cloudCover,
    required this.visibilityM,
  });

  final int code;
  final double temperatureC;
  final double precipitationMm;
  final double windKmh;
  final double? cloudCover;
  final double? visibilityM;

  static const rainCodes = {
    51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82,
  };
  static const snowCodes = {71, 73, 75, 77, 85, 86};
  static const thunderCodes = {95, 96, 99};
  static const dustCodes = {30, 31, 32, 33, 34, 35};
  static const fogCodes = {45, 48};

  WeatherCategory get category => categoryForCode(code);

  bool get raining => rainCodes.contains(code);
  bool get drizzle => const {51, 53, 55, 56, 57}.contains(code);
  bool get snowing => snowCodes.contains(code);
  bool get thunderstorm => thunderCodes.contains(code);
  bool get dusty => dustCodes.contains(code);
  bool get foggy =>
      fogCodes.contains(code) ||
      (!raining &&
          !snowing &&
          !thunderstorm &&
          !dusty &&
          visibilityM != null &&
          visibilityM! <= 1000);
  bool get windy => windKmh >= windyThresholdKmh;
  bool get strongHeat => temperatureC >= strongHeatThresholdC;
  bool get extremeHeat => temperatureC >= extremeHeatThresholdC;
  double get cloudPercent =>
      (cloudCover ?? _cloudFallback).clamp(0.0, 100.0).toDouble();
  bool get overcast => code == 3 || cloudPercent >= 82;
  bool get partlyCloudy => code == 2 || cloudPercent >= 35 && cloudPercent < 82;

  double get rainIntensity {
    if (!raining) return 0;
    final amount = precipitationMm <= 0 ? .25 : precipitationMm / 5;
    final codeIntensity = switch (code) {
      51 || 56 || 61 || 66 || 80 => .24,
      53 || 57 || 63 || 67 || 81 => .52,
      _ => .82,
    };
    return amount.clamp(codeIntensity, 1.0).toDouble();
  }

  double get _cloudFallback => switch (code) {
        0 || 1 => 12,
        2 => 58,
        3 => 95,
        45 || 48 => 85,
        _ => 64,
      };
}

/// Which hand-built scene the live weather should be rendered as.
///
/// [live] is the normal layered scene. The other four select dedicated
/// set-piece environments that would otherwise never be reachable, because a
/// single weather reading rarely lands on them by chance.
///
/// Thresholds describe artwork intensity only; they are not hazard advisories
/// and must not be presented to users as warnings.
enum SceneEnvironment { live, cyclone, flood, desertHeat, sandstorm }

/// Wind at which a tropical storm scene is warranted, in km/h.
const cycloneWindKmh = 118.0;

/// Rainfall for the day at which the flood scene is warranted, in mm.
const floodDailyRainMm = 60.0;

/// Rainfall in one reading that alone warrants the flood scene, in mm.
const floodInstantRainMm = 20.0;

/// Resolves the scene for a live reading, or [SceneEnvironment.live] when no
/// set-piece matches.
///
/// Precedence runs most severe first: a cyclone is also a flood and a gale, so
/// it must win before the lower-energy scenes get a chance to claim it.
SceneEnvironment resolveSceneEnvironment({
  required WeatherConditions conditions,
  required bool aridRegion,
  required bool isDay,
  double? dailyPrecipitationMm,
  double? latitude,
}) {
  final latitudeValue = latitude ?? 0;

  if (conditions.windKmh >= cycloneWindKmh &&
      conditions.windKmh >= windyThresholdKmh &&
      (conditions.thunderstorm || conditions.raining)) {
    // Cyclones do not form within about 5 degrees of the equator.
    if (latitudeValue.abs() >= 5) return SceneEnvironment.cyclone;
  }

  final dailyRain = dailyPrecipitationMm ?? 0;
  if (conditions.raining &&
      (dailyRain >= floodDailyRainMm ||
          conditions.precipitationMm >= floodInstantRainMm)) {
    return SceneEnvironment.flood;
  }

  if (aridRegion &&
      (conditions.dusty ||
          (conditions.windKmh >= galeWindThresholdKmh &&
              conditions.precipitationMm <= 0 &&
              !conditions.raining))) {
    return SceneEnvironment.sandstorm;
  }

  if (aridRegion &&
      isDay &&
      conditions.temperatureC >= extremeHeatThresholdC) {
    return SceneEnvironment.desertHeat;
  }

  return SceneEnvironment.live;
}

/// Short label for the HUD, describing the scene actually being shown.
String sceneEnvironmentLabel(SceneEnvironment environment) => switch (environment) {
      SceneEnvironment.cyclone => 'CYCLONE APPROACH',
      SceneEnvironment.flood => 'FLOODWATER',
      SceneEnvironment.desertHeat => 'DESERT HEAT',
      SceneEnvironment.sandstorm => 'SANDSTORM',
      SceneEnvironment.live => '',
    };