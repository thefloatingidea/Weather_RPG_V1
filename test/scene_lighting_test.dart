import 'dart:ui' as ui;

import 'package:flame/game.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/weather_scene.dart';
import 'package:weather_rpg/world_catalog.dart';

/// Builds a scene for a single local hour without advancing any animation.
WeatherSceneGame sceneAt(
  int hour, {
  bool isDay = true,
  int weatherCode = 0,
}) {
  final delhi = worldLocations.firstWhere((l) => l.id == 'delhi');
  final game = WeatherSceneGame(
    config: WeatherSceneConfig(
      weatherCode: weatherCode,
      isDay: isDay,
      temperatureC: 24,
      windKmh: 8,
      location: delhi,
      cloudCover: 10,
      visibilityM: 12000,
      windDirectionDeg: 180,
      month: 4,
      latitude: delhi.latitude,
      longitude: delhi.longitude,
      city: delhi.name,
      localHour: hour,
    ),
  );
  game.onGameResize(Vector2(480, 240));
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('time-of-day lighting', () {
    test('midday is fully lit with no warm cast', () {
      final game = sceneAt(12);
      expect(game.debugNightAmount, 0.0);
      expect(game.debugGoldenAmount, 0.0);
    });

    test('deep night is fully dark', () {
      for (final hour in [1, 3, 23]) {
        final game = sceneAt(hour, isDay: false);
        expect(game.debugNightAmount, 1.0, reason: 'hour $hour');
      }
    });

    test('darkness ramps rather than stepping across dusk', () {
      final values = [for (final h in [17, 18, 19, 20, 21]) sceneAt(h, isDay: false).debugNightAmount];

      expect(values.first, 0.0, reason: 'late afternoon should be lit');
      expect(values.last, 1.0, reason: 'night should be fully dark');
      // Monotonic increase, and no single step jumps the whole range.
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThanOrEqualTo(values[i - 1]),
            reason: 'darkness went backwards at index $i');
        expect(values[i] - values[i - 1], lessThanOrEqualTo(.5),
            reason: 'darkness jumped sharply at index $i');
      }
    });

    test('darkness ramps across dawn too', () {
      final values = [for (final h in [3, 5, 6, 7, 9]) sceneAt(h).debugNightAmount];

      expect(values.first, 1.0);
      expect(values.last, 0.0);
      for (var i = 1; i < values.length; i++) {
        expect(values[i], lessThanOrEqualTo(values[i - 1]));
      }
    });

    test('the warm cast peaks near the horizon, not at noon', () {
      // Dawn and sunset are the moments nearest the horizon.
      final dawn = sceneAt(7).debugGoldenAmount;
      final noon = sceneAt(12).debugGoldenAmount;
      final sunset = sceneAt(17).debugGoldenAmount;

      expect(dawn, greaterThan(0));
      expect(sunset, greaterThan(0));
      expect(noon, lessThan(dawn));
      expect(noon, lessThan(.05), reason: 'midday should not be golden');
    });

    test('the sun tracks an arc from east to west across the day', () {
      // Below the horizon before sunrise and after sunset.
      expect(sceneAt(5).debugSunProgress, isNull);
      expect(sceneAt(19, isDay: false).debugSunProgress, isNull);
      expect(sceneAt(3, isDay: false).debugSunProgress, isNull);

      // Climbing in the morning, descending in the afternoon.
      final morning = <double>[
        for (final h in [7, 9, 11]) sceneAt(h).debugSunProgress!,
      ];
      final afternoon = <double>[
        for (final h in [13, 15, 17]) sceneAt(h).debugSunProgress!,
      ];
      for (var i = 1; i < morning.length; i++) {
        expect(morning[i], greaterThan(morning[i - 1]),
            reason: 'the sun did not climb between morning samples');
      }
      for (var i = 1; i < afternoon.length; i++) {
        expect(afternoon[i], greaterThan(afternoon[i - 1]),
            reason: 'the sun did not keep moving west through the afternoon');
      }
      // Noon sits in the middle of the arc.
      expect(sceneAt(12).debugSunProgress, closeTo(.5, .03));
    });

    test('the sky darkens toward dusk rather than staying at full daylight',
        () {
      final noon = sceneAt(12).debugLitSkyColor;
      final dusk = sceneAt(20, isDay: false).debugLitSkyColor;

      expect(noon, isNot(dusk));
      // The dusk sky must be dimmer than the midday sky.
      expect(dusk.computeLuminance(), lessThan(noon.computeLuminance()));
    });

    test('a scene with no local hour still renders a sane sky', () {
      final delhi = worldLocations.firstWhere((l) => l.id == 'delhi');
      final game = WeatherSceneGame(
        config: WeatherSceneConfig(
          weatherCode: 0,
          isDay: true,
          temperatureC: 20,
          windKmh: 5,
          location: delhi,
          month: 4,
          latitude: delhi.latitude,
          longitude: delhi.longitude,
        ),
      );
      game.onGameResize(Vector2(480, 240));

      expect(game.debugLitSkyColor.a, greaterThan(0));
      expect(game.debugNightAmount, 0.0);
    });

    test('the sky band is brighter by day than at night', () async {
      // Mean luminance across the band, not the brightest pixel: the crescent
      // moon is a near-white pixel that would otherwise out-score a daytime sky.
      Future<double> meanSkyLuminance(WeatherSceneGame game) async {
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final image = await recorder.endRecording().toImage(480, 240);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final bytes = data!.buffer.asUint8List();
        var total = 0;
        var count = 0;
        for (var y = 0; y < 90; y++) {
          for (var x = 0; x < 480; x++) {
            final i = (y * 480 + x) * 4;
            total += bytes[i] + bytes[i + 1] + bytes[i + 2];
            count++;
          }
        }
        return total / count;
      }

      final day = await meanSkyLuminance(sceneAt(12));
      final night = await meanSkyLuminance(sceneAt(2, isDay: false));

      expect(day, greaterThan(night * 1.5),
          reason: 'the midday sky (mean $day) should be far brighter than the '
              'night sky (mean $night)');
    });
  });
}
