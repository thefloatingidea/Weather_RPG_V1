import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/weather_rules.dart';

WeatherConditions conditions({
  int code = 0,
  double temperatureC = 22,
  double precipitationMm = 0,
  double windKmh = 10,
  double? cloudCover = 20,
  double? visibilityM = 10000,
}) =>
    WeatherConditions(
      code: code,
      temperatureC: temperatureC,
      precipitationMm: precipitationMm,
      windKmh: windKmh,
      cloudCover: cloudCover,
      visibilityM: visibilityM,
    );

SceneEnvironment resolve(
  WeatherConditions c, {
  bool arid = false,
  bool isDay = true,
  double? dailyMm,
  double latitude = 19,
}) =>
    resolveSceneEnvironment(
      conditions: c,
      aridRegion: arid,
      isDay: isDay,
      dailyPrecipitationMm: dailyMm,
      latitude: latitude,
    );

void main() {
  group('scene environment resolution', () {
    test('ordinary weather stays on the live scene', () {
      expect(resolve(conditions(code: 0)), SceneEnvironment.live);
      expect(resolve(conditions(code: 2, cloudCover: 60)),
          SceneEnvironment.live);
      expect(resolve(conditions(code: 61, precipitationMm: 2)),
          SceneEnvironment.live);
      expect(resolve(conditions(code: 71, temperatureC: -2)),
          SceneEnvironment.live);
    });

    test('a cyclonic storm selects the cyclone scene', () {
      expect(
        resolve(conditions(code: 99, windKmh: 140, precipitationMm: 12)),
        SceneEnvironment.cyclone,
      );
      // Right on the threshold.
      expect(
        resolve(conditions(code: 95, windKmh: cycloneWindKmh)),
        SceneEnvironment.cyclone,
      );
    });

    test('a cyclone needs both damaging wind and active precipitation', () {
      // Strong wind alone is a gale, not a cyclone.
      expect(
        resolve(conditions(code: 0, windKmh: 130)),
        isNot(SceneEnvironment.cyclone),
      );
    });

    test('cyclones are not drawn near the equator', () {
      expect(
        resolve(
          conditions(code: 99, windKmh: 140, precipitationMm: 12),
          latitude: 1.5,
        ),
        isNot(SceneEnvironment.cyclone),
      );
      // Just outside the exclusion band.
      expect(
        resolve(
          conditions(code: 99, windKmh: 140, precipitationMm: 12),
          latitude: 6,
        ),
        SceneEnvironment.cyclone,
      );
    });

    test('heavy rain selects the flood scene', () {
      // Enough rain across the day.
      expect(
        resolve(conditions(code: 65, precipitationMm: 3), dailyMm: 80),
        SceneEnvironment.flood,
      );
      // Or a single torrential reading.
      expect(
        resolve(conditions(code: 65, precipitationMm: floodInstantRainMm)),
        SceneEnvironment.flood,
      );
    });

    test('flood needs actual rain, not just a wet-looking forecast', () {
      expect(resolve(conditions(code: 3, cloudCover: 100), dailyMm: 120),
          SceneEnvironment.live);
      expect(
        resolve(conditions(code: 61, precipitationMm: 1), dailyMm: 10),
        SceneEnvironment.live,
      );
    });

    test('a cyclone outranks the flood it also causes', () {
      expect(
        resolve(
          conditions(code: 99, windKmh: 150, precipitationMm: 30),
          dailyMm: 120,
        ),
        SceneEnvironment.cyclone,
      );
    });

    test('blowing dust in an arid region selects the sandstorm', () {
      expect(
        resolve(conditions(code: 31, windKmh: 20), arid: true),
        SceneEnvironment.sandstorm,
      );
      // A gale with no rain lifts dust even without a dust code.
      expect(
        resolve(conditions(code: 0, windKmh: galeWindThresholdKmh), arid: true),
        SceneEnvironment.sandstorm,
      );
    });

    test('a dust code outside an arid region is not a sandstorm', () {
      expect(
        resolve(conditions(code: 31, windKmh: 20), arid: false),
        SceneEnvironment.live,
      );
    });

    test('rain suppresses the dust-lifting branch', () {
      expect(
        resolve(
          conditions(code: 61, windKmh: galeWindThresholdKmh,
              precipitationMm: 3),
          arid: true,
        ),
        isNot(SceneEnvironment.sandstorm),
      );
    });

    test('extreme heat in an arid region by day selects the heat scene', () {
      expect(
        resolve(conditions(code: 0, temperatureC: 42), arid: true),
        SceneEnvironment.desertHeat,
      );
    });

    test('desert heat requires an arid region and daytime', () {
      expect(
        resolve(conditions(code: 0, temperatureC: 42), arid: false),
        SceneEnvironment.live,
      );
      expect(
        resolve(conditions(code: 0, temperatureC: 42), arid: true, isDay: false),
        SceneEnvironment.live,
      );
      // Below the extreme threshold stays live; `strongHeat` art covers it.
      expect(
        resolve(conditions(code: 0, temperatureC: strongHeatThresholdC),
            arid: true),
        SceneEnvironment.live,
      );
    });

    test('labels exist for every environment', () {
      for (final environment in SceneEnvironment.values) {
        final label = sceneEnvironmentLabel(environment);
        if (environment == SceneEnvironment.live) {
          expect(label, isEmpty);
        } else {
          expect(label, isNotEmpty);
        }
      }
    });
  });
}
