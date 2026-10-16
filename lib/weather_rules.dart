/// Shared interpretation of normalized weather codes and measurements.
/// Thresholds describe artwork intensity; they are not hazard advisories.
const strongHeatThresholdC = 35.0;
const extremeHeatThresholdC = 40.0;
const windyThresholdKmh = 35.0;
const strongWindThresholdKmh = 45.0;
const galeWindThresholdKmh = 70.0;

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

  static const rainCodes = <int>{
    51,
    53,
    55,
    56,
    57,
    61,
    63,
    65,
    66,
    67,
    80,
    81,
    82,
  };
  static const snowCodes = <int>{71, 73, 75, 77, 85, 86};
  static const thunderCodes = <int>{95, 96, 99};
  static const dustCodes = <int>{30, 31, 32, 33, 34, 35};
  static const fogCodes = <int>{45, 48};

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

  if (aridRegion && isDay && conditions.temperatureC >= extremeHeatThresholdC) {
    return SceneEnvironment.desertHeat;
  }

  return SceneEnvironment.live;
}

/// Short label for the HUD, describing the scene actually being shown.
String sceneEnvironmentLabel(SceneEnvironment environment) =>
    switch (environment) {
      SceneEnvironment.cyclone => 'CYCLONE APPROACH',
      SceneEnvironment.flood => 'FLOODWATER',
      SceneEnvironment.desertHeat => 'DESERT HEAT',
      SceneEnvironment.sandstorm => 'SANDSTORM',
      SceneEnvironment.live => '',
    };
