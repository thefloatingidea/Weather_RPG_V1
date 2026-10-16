// Temporary diagnostic: drives WeatherSceneGame directly and writes PNG frames
// so the rendered environment can be inspected outside the app.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/goblin_sprites.dart';
import 'package:weather_rpg/weather_scene.dart';
import 'package:weather_rpg/weather_rules.dart';
import 'package:weather_rpg/world_catalog.dart';

WorldLocation _loc(String id) =>
    worldLocations.firstWhere((l) => l.id == id);

/// Decodes the sprite frames straight from disk: `flutter test` does not build
/// the asset bundle, so the scene's own loader cannot be used here.
Future<GoblinSprites> _loadSpritesFromDisk() async {
  final frames = <String, ui.Image>{};
  for (final name in GoblinSprites.filenames) {
    final file = File('assets/images/$name');
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    frames[name] = frame.image;
  }
  return GoblinSprites.fromImages(frames);
}

Future<void> _capture(
  String name, {
  required WeatherSceneConfig config,
  required GoblinSprites sprites,
  double seconds = 6,
  int steps = 120,
}) async {
  final game = WeatherSceneGame(config: config);
  game.debugSetSprites(sprites);
  game.onGameResize(Vector2(900, 420));
  final dt = seconds / steps;
  for (var i = 0; i < steps; i++) {
    game.update(dt);
  }
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  game.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(900, 420);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('build/probe_$name.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote ${file.path}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('probe renders', () async {
    final sprites = await _loadSpritesFromDisk();
    await _capture(
      'mumbai_rain_day',
      sprites: sprites,
      config: WeatherSceneConfig(
        weatherCode: 63,
        isDay: true,
        temperatureC: 27,
        windKmh: 22,
        precipitationMm: 3.2,
        location: _loc('mumbai'),
        cloudCover: 88,
        visibilityM: 6000,
        windDirectionDeg: 240,
        month: 7,
        latitude: 19.076,
        localHour: 14,
        city: 'Mumbai',
        region: 'Maharashtra, India',
      ),
    );
    await _capture(
      'delhi_clear_day',
      sprites: sprites,
      config: WeatherSceneConfig(
        weatherCode: 1,
        isDay: true,
        temperatureC: 29,
        windKmh: 8,
        location: _loc('delhi'),
        cloudCover: 12,
        windDirectionDeg: 90,
        month: 11,
        latitude: 28.61,
        localHour: 11,
        city: 'Delhi',
        region: 'India',
      ),
    );
    await _capture(
      'london_night_clear',
      sprites: sprites,
      config: WeatherSceneConfig(
        weatherCode: 0,
        isDay: false,
        temperatureC: 9,
        windKmh: 14,
        location: _loc('london'),
        cloudCover: 10,
        windDirectionDeg: 200,
        month: 12,
        latitude: 51.5,
        localHour: 22,
        city: 'London',
        region: 'United Kingdom',
      ),
    );
    await _capture(
      'jaisalmer_heat',
      sprites: sprites,
      config: WeatherSceneConfig(
        weatherCode: 0,
        isDay: true,
        temperatureC: 41,
        windKmh: 12,
        location: _loc('jaisalmer'),
        cloudCover: 4,
        windDirectionDeg: 45,
        month: 5,
        latitude: 26.9,
        localHour: 13,
        city: 'Jaisalmer',
        region: 'Rajasthan, India',
      ),
    );
    await _capture(
      'srinagar_snow',
      sprites: sprites,
      config: WeatherSceneConfig(
        weatherCode: 73,
        isDay: true,
        temperatureC: -3,
        windKmh: 18,
        precipitationMm: 1.2,
        location: _loc('srinagar'),
        cloudCover: 92,
        visibilityM: 2500,
        windDirectionDeg: 300,
        month: 1,
        latitude: 34.08,
        localHour: 15,
        city: 'Srinagar',
        region: 'India',
      ),
    );
    await _capture(
      'cyclone_env',
      sprites: sprites,
      config: WeatherSceneConfig(
        weatherCode: 99,
        isDay: false,
        temperatureC: 26,
        windKmh: 120,
        precipitationMm: 12,
        location: _loc('chennai'),
        cloudCover: 100,
        month: 11,
        latitude: 13.08,
        localHour: 3,
        city: 'Chennai',
        region: 'India',
        environment: SceneEnvironment.cyclone,
      ),
    );
  });
}
