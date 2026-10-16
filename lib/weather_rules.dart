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
