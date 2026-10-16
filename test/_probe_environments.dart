// Diagnostic: renders the four set-piece environments so they can be reviewed,
// and records which weather readings select each one.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/goblin_sprites.dart';
import 'package:weather_rpg/weather_rules.dart';
import 'package:weather_rpg/weather_scene.dart';
import 'package:weather_rpg/world_catalog.dart';

const int W = 720, H = 340;

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

  test('render every set-piece environment', () async {
    final sprites = await _loadSprites();
    final jaisalmer = worldLocations.firstWhere((l) => l.id == 'jaisalmer');
    final chennai = worldLocations.firstWhere((l) => l.id == 'chennai');
    final kolkata = worldLocations.firstWhere((l) => l.id == 'kolkata');
    final outDir = Directory('build/environments');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    // Each case is the reading that selects the environment, resolved through
    // the real selector so the probe cannot drift from app behaviour.
    final cases = <String, (WeatherConditions, WorldLocation, bool)>{
      'cyclone': (
        const WeatherConditions(
            code: 99,
            temperatureC: 27,
            precipitationMm: 14,
            windKmh: 140,
            cloudCover: 100,
            visibilityM: 1500),
        chennai,
        false,
      ),
      'flood': (
        const WeatherConditions(
            code: 65,
            temperatureC: 25,
            precipitationMm: 22,
            windKmh: 38,
            cloudCover: 100,
            visibilityM: 2500),
        kolkata,
        true,
      ),
      'sandstorm': (
        const WeatherConditions(
            code: 31,
            temperatureC: 38,
            precipitationMm: 0,
            windKmh: 75,
            cloudCover: 25,
            visibilityM: 900),
        jaisalmer,
        true,
      ),
      'desertHeat': (
        const WeatherConditions(
            code: 0,
            temperatureC: 43,
            precipitationMm: 0,
            windKmh: 8,
            cloudCover: 2,
            visibilityM: 12000),
        jaisalmer,
        true,
      ),
    };

    for (final entry in cases.entries) {
      final (conditions, location, isDay) = entry.value;
      final environment = resolveSceneEnvironment(
        conditions: conditions,
        aridRegion: location.isArid,
        isDay: isDay,
        latitude: location.latitude,
      );
      expect(environment.name, entry.key,
          reason: '${entry.key} case resolved to ${environment.name} instead');

      final game = WeatherSceneGame(
        config: WeatherSceneConfig(
          weatherCode: conditions.code,
          isDay: isDay,
          temperatureC: conditions.temperatureC,
          windKmh: conditions.windKmh,
          precipitationMm: conditions.precipitationMm,
          location: location,
          cloudCover: conditions.cloudCover,
          visibilityM: conditions.visibilityM,
          windDirectionDeg: 210,
          month: 6,
          latitude: location.latitude,
          longitude: location.longitude,
          city: location.name,
          localHour: isDay ? 14 : 2,
          environment: environment,
        ),
      );
      game.debugSetSprites(sprites);
      game.onGameResize(Vector2(W.toDouble(), H.toDouble()));
      // 25 s: the flood set-piece needs its full duration for the water to rise
      // to the level that reads as a flood rather than a stream.
      for (var i = 0; i < 1500; i++) {
        game.update(1 / 60);
      }
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final image = await recorder.endRecording().toImage(W, H);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${outDir.path}/${entry.key}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
      // ignore: avoid_print
      print('${entry.key.padRight(12)} <- ${location.id}, '
          '${conditions.windKmh} km/h, ${conditions.temperatureC}C, '
          '${conditions.precipitationMm}mm');
    }
  });
}
