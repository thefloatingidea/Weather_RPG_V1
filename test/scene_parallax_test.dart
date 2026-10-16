import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/weather_scene.dart';
import 'package:weather_rpg/world_catalog.dart';

const int W = 720, H = 340;

WeatherSceneGame _scene({
  required double windKmh,
  required double windDirectionDeg,
  bool reduceMotion = false,
  bool reduceFlashing = false,
}) {
  final delhi = worldLocations.firstWhere((l) => l.id == 'delhi');
  final game = WeatherSceneGame(
    config: WeatherSceneConfig(
      weatherCode: 0,
      isDay: true,
      temperatureC: 24,
      windKmh: windKmh,
      windDirectionDeg: windDirectionDeg,
      location: delhi,
      cloudCover: 0,
      visibilityM: 12000,
      month: 4,
      latitude: delhi.latitude,
      longitude: delhi.longitude,
      city: delhi.name,
      localHour: 13,
      reduceMotion: reduceMotion,
      reduceFlashing: reduceFlashing,
    ),
  );
  game.onGameResize(Vector2(W.toDouble(), H.toDouble()));
  game.update(1 / 60);
  return game;
}

Future<Uint8List> _capture(WeatherSceneGame game) async {
  final recorder = ui.PictureRecorder();
  game.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(W, H);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

/// The horizontal displacement that best aligns two frames, found by
/// cross-correlating a horizontal band of the mid-ground.
///
/// The band sits above the character's feet and below the horizon, which is
/// where the parallax layer's content is.
Future<int> _bestHorizontalShift(Uint8List a, Uint8List b) async {
  var bestShift = 0;
  var bestScore = -1;
  const yStart = 200, yEnd = 320, maxShift = 40;
  for (var shift = -maxShift; shift <= maxShift; shift++) {
    var score = 0;
    for (var y = yStart; y < yEnd; y += 2) {
      for (var x = maxShift; x < W - maxShift; x += 2) {
        final ia = (y * W + x) * 4;
        final ib = (y * W + x + shift) * 4;
        if (a[ia] == b[ib] && a[ia + 1] == b[ib + 1] && a[ia + 2] == b[ib + 2]) {
          score++;
        }
      }
    }
    if (score > bestScore) {
      bestScore = score;
      bestShift = shift;
    }
  }
  return bestShift;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('wind parallax offset', () {
    test('a still scene has no layer offset', () {
      expect(
          _scene(windKmh: 0, windDirectionDeg: 180)
              .debugParallaxMidOffset(W.toDouble()),
          0);
    });

    test('the offset grows with wind speed', () {
      double offset(double wind) => _scene(windKmh: wind, windDirectionDeg: 180)
          .debugParallaxMidOffset(W.toDouble())
          .abs();

      expect(offset(35), greaterThan(0));
      expect(offset(70), greaterThan(offset(35)));
      expect(offset(160), greaterThan(offset(70)));
    });

    test('the offset saturates instead of growing without bound', () {
      // A scene blown past the clamp must not slide off the canvas.
      final extreme = _scene(windKmh: 400, windDirectionDeg: 180)
          .debugParallaxMidOffset(W.toDouble());
      final atMax = _scene(windKmh: 160, windDirectionDeg: 180)
          .debugParallaxMidOffset(W.toDouble());

      expect(extreme, atMax);
      expect(extreme.abs(), lessThan(W * .05));
    });

    test('opposite bearings offset in opposite directions', () {
      final eastward = _scene(windKmh: 70, windDirectionDeg: 180)
          .debugParallaxMidOffset(W.toDouble());
      final westward = _scene(windKmh: 70, windDirectionDeg: 0)
          .debugParallaxMidOffset(W.toDouble());

      expect(eastward, greaterThan(0));
      expect(westward, lessThan(0));
      expect(eastward, closeTo(-westward, 1e-9));
    });

    test('a cross-scene wind still pushes sideways', () {
      // Bearing 90/270 means the wind blows across the view, so the cosine is
      // zero; the layer must still lean rather than freeze.
      for (final bearing in [90.0, 270.0]) {
        final offset = _scene(windKmh: 70, windDirectionDeg: bearing)
            .debugParallaxMidOffset(W.toDouble());
        expect(offset.abs(), greaterThan(0),
            reason: 'bearing $bearing produced no offset');
      }
    });

    test('reduced motion damps the offset', () {
      final full = _scene(windKmh: 140, windDirectionDeg: 180)
          .debugParallaxMidOffset(W.toDouble())
          .abs();
      final damped = _scene(
        windKmh: 140,
        windDirectionDeg: 180,
        reduceMotion: true,
        reduceFlashing: true,
      ).debugParallaxMidOffset(W.toDouble()).abs();

      expect(damped, greaterThan(0));
      expect(damped, lessThan(full));
    });
  });

  group('wind parallax rendering', () {
    test('the mid layer visibly shifts against a still scene', () async {
      final still = await _capture(_scene(windKmh: 0, windDirectionDeg: 180));
      final gale = await _capture(_scene(windKmh: 140, windDirectionDeg: 180));

      final shift = await _bestHorizontalShift(still, gale);
      expect(shift.abs(), greaterThan(2),
          reason: 'the gale moved the mid layer by only $shift px');
    });

    test('opposite winds shift the layer opposite ways', () async {
      final still = await _capture(_scene(windKmh: 0, windDirectionDeg: 180));
      final eastward =
          await _capture(_scene(windKmh: 140, windDirectionDeg: 180));
      final westward = await _capture(_scene(windKmh: 140, windDirectionDeg: 0));

      final east = await _bestHorizontalShift(still, eastward);
      final west = await _bestHorizontalShift(still, westward);

      expect(east.sign, isNot(west.sign),
          reason: 'both bearings shifted the same way (east $east, west $west)');
    });
  });
}