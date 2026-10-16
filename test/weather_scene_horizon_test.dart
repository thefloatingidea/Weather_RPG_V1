import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/goblin_sprites.dart';
import 'package:weather_rpg/weather_scene.dart';
import 'package:weather_rpg/world_catalog.dart';

/// Renders one frame at a fixed time and returns the decoded pixels.
Future<ui.Image> _renderFrame(
  WorldLocation location,
  GoblinSprites sprites, {
  int weatherCode = 0,
  bool isDay = true,
  double temperatureC = 24,
  int month = 5,
}) async {
  final game = WeatherSceneGame(
    config: WeatherSceneConfig(
      weatherCode: weatherCode,
      isDay: isDay,
      temperatureC: temperatureC,
      windKmh: 10,
      location: location,
      cloudCover: 12,
      visibilityM: 9000,
      windDirectionDeg: 180,
      month: month,
      latitude: location.latitude,
      longitude: location.longitude,
      city: location.name,
      localHour: isDay ? 12 : 22,
    ),
  );
  game.debugSetSprites(sprites);
  game.onGameResize(Vector2(600, 280));
  for (var i = 0; i < 60; i++) {
    game.update(1 / 60);
  }
  final recorder = ui.PictureRecorder();
  game.render(ui.Canvas(recorder));
  return recorder.endRecording().toImage(600, 280);
}

/// The most common horizon colour, sampled from bands that avoid the landmark
/// (centre), the character, and the sky above the ridge line.
Future<int> _horizonColor(ui.Image image, int skyColor) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  const width = 600, height = 280;
  final counts = <int, int>{};
  // Rows 41%..58% of the height brackets every ridge silhouette, which peaks
  // between about 40% (skyline, wooded) and 47% (dunes).
  for (var y = (height * .41).round(); y < (height * .58).round(); y++) {
    for (var x = 0; x < width; x++) {
      // Skip the central band where the landmark and character sit.
      if (x >= width * .28 && x <= width * .72) continue;
      final i = (y * width + x) * 4;
      final rgb = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
      // Ignore sky and the cloud tones drawn over it.
      if (rgb == skyColor) continue;
      counts[rgb] = (counts[rgb] ?? 0) + 1;
    }
  }
  expect(counts, isNotEmpty,
      reason: 'no horizon silhouette pixels found outside the sky');
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

/// The sky colour the scene draws under the test fixtures: a clear spring day
/// with light cloud. Used to exclude sky pixels from the horizon sample.
int _skyColorFor(WorldLocation location) {
  final color = weatherSceneSkyColor(
    isDay: true,
    sandstorm: false,
    storm: false,
    rain: false,
    fog: false,
    overcast: false,
    snowy: false,
    hot: location.isArid,
    spring: false,
    summer: false,
    cloudCover: 12,
  );
  return (color.r * 255).round() << 16 |
      (color.g * 255).round() << 8 |
      (color.b * 255).round();
}

String _hex(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

Future<GoblinSprites> _loadSprites() async {
  final frames = <String, ui.Image>{};
  for (final name in GoblinSprites.filenames) {
    final bytes = await File('assets/images/$name').readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    frames[name] = (await codec.getNextFrame()).image;
  }
  return GoblinSprites.fromImages(frames);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('biome-driven horizon', () {
    late GoblinSprites sprites;

    setUpAll(() async {
      sprites = await _loadSprites();
    });

    WorldLocation loc(String id) =>
        worldLocations.firstWhere((l) => l.id == id);

    test('each biome gets its own horizon colour', () async {
      // Held weather and season constant so only the biome can differ.
      final colors = <String, int>{};
      for (final entry in {
        'desert (Jaisalmer)': 'jaisalmer',
        'urban (Delhi)': 'delhi',
        'mountain (Shimla)': 'shimla',
        'coastal (Mumbai)': 'mumbai',
        'tropical (Singapore)': 'singapore',
      }.entries) {
        final location = loc(entry.value);
        colors[entry.key] = await _horizonColor(
          await _renderFrame(location, sprites),
          _skyColorFor(location),
        );
      }

      // Before the biome-aware horizon every location shared one green ridge
      // palette, so the desert and the city rendered the same colour here.
      final entries = colors.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        for (var j = i + 1; j < entries.length; j++) {
          expect(
            entries[i].value,
            isNot(entries[j].value),
            reason: '${entries[i].key} and ${entries[j].key} share the horizon '
                'colour ${_hex(entries[i].value)}; the horizon is probably not '
                'following the biome.',
          );
        }
      }
    });

    test('the same biome is stable across renders', () async {
      final location = loc('delhi');
      final sky = _skyColorFor(location);
      final first =
          await _horizonColor(await _renderFrame(location, sprites), sky);
      final second =
          await _horizonColor(await _renderFrame(location, sprites), sky);
      expect(first, second);
    });
  });
}
