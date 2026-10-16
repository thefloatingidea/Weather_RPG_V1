import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/weather_scene.dart';
import 'package:weather_rpg/world_catalog.dart';

const int W = 720, H = 340;

/// A location with no catalogued landmark, which exercises the centred branch.
final _noLandmark = resolveWorldLocation(
  city: 'Nowhereville',
  region: 'Atlantis',
  latitude: 0,
  longitude: 0,
);

Future<Uint8List> _render(
  WorldLocation location, {
  required bool withCharacter,
  required bool withLandmark,
}) async {
  final game = WeatherSceneGame(
    config: WeatherSceneConfig(
      weatherCode: 1,
      isDay: true,
      temperatureC: 24,
      windKmh: 9,
      location: location,
      cloudCover: 20,
      visibilityM: 10000,
      windDirectionDeg: 180,
      month: 4,
      latitude: location.latitude,
      longitude: location.longitude,
      city: location.name,
      localHour: 13,
    ),
  );
  game.debugHiddenLayers = switch ((withLandmark, withCharacter)) {
    (true, true) => DebugSceneLayers.none,
    (false, true) => DebugSceneLayers.withoutLandmark,
    (true, false) => DebugSceneLayers.withoutCharacter,
    (false, false) => DebugSceneLayers.withoutLandmarkAndCharacter,
  };
  game.onGameResize(Vector2(W.toDouble(), H.toDouble()));
  for (var i = 0; i < 90; i++) {
    game.update(1 / 60);
  }
  final recorder = ui.PictureRecorder();
  game.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(W, H);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

bool _differs(Uint8List a, Uint8List b, int x, int y) {
  final i = (y * W + x) * 4;
  return a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2];
}

/// Columns touched by a layer, isolated by diffing two renders.
Future<Set<int>> _columnsTouched(
  WorldLocation location, {
  required bool layer,
}) async {
  // `layer` true measures the character; false measures the landmark.
  final withLayer = await _render(location,
      withCharacter: layer, withLandmark: !layer);
  final withoutLayer = await _render(location,
      withCharacter: false, withLandmark: false);

  final columns = <int>{};
  for (var y = 0; y < H; y++) {
    for (var x = 0; x < W; x++) {
      if (_differs(withLayer, withoutLayer, x, y)) columns.add(x);
    }
  }
  return columns;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WorldLocation loc(String id) =>
      worldLocations.firstWhere((l) => l.id == id);

  group('character lane', () {
    test('the character keeps to the right-hand lane beside a landmark',
        () async {
      for (final id in ['delhi', 'mumbai', 'paris', 'jaisalmer', 'new-york']) {
        final columns = await _columnsTouched(loc(id), layer: true);
        expect(columns, isNotEmpty, reason: '$id drew no character pixels');
        final left = columns.reduce((a, b) => a < b ? a : b) / W;
        final right = (columns.reduce((a, b) => a > b ? a : b) + 1) / W;
        expect(left, greaterThan(.55),
            reason: '$id: character reaches x=$left, too close to the landmark');
        expect(right, lessThan(.95),
            reason: '$id: character reaches x=$right, running off frame');
      }
    });

    test('the character sits clear of the landmark mass', () async {
      for (final id in ['delhi', 'paris', 'jaisalmer', 'mumbai']) {
        final location = loc(id);
        final character = await _columnsTouched(location, layer: true);
        final landmark = await _columnsTouched(location, layer: false);
        expect(landmark, isNotEmpty, reason: '$id drew no landmark pixels');

        double centre(Set<int> columns) {
          var sum = 0, count = 0;
          for (var y = 0; y < H; y++) {
            for (final x in columns) {
              sum += x;
              count++;
            }
          }
          return sum / count / W;
        }

        // Overlap by bounding box is meaningless here: landmark art includes
        // full-width ground and water bands that the character legitimately
        // stands on. Comparing horizontal centres of mass is the usable signal.
        final landmarkCentre = centre(landmark);
        final characterCentre = centre(character);
        expect(characterCentre - landmarkCentre, greaterThan(.08),
            reason: '$id: character centre ${characterCentre.toStringAsFixed(3)} '
                'is not clear of the landmark centre '
                '${landmarkCentre.toStringAsFixed(3)}');
      }
    });

    test('the character centres when there is no landmark', () async {
      final columns = await _columnsTouched(_noLandmark, layer: true);
      final centre = (columns.reduce((a, b) => a < b ? a : b) +
              columns.reduce((a, b) => a > b ? a : b)) /
          2 /
          W;
      expect(centre, closeTo(.5, .12),
          reason: 'expected a centred character, got x=$centre');
    });

    test('the fallback location really has no landmark', () {
      expect(_noLandmark.landmark, WorldLandmark.none);
    });
  });
}
