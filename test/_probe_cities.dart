// Diagnostic: renders one frame per catalogue location so landmark composition
// and the character lane can be reviewed across every city.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/goblin_sprites.dart';
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

  test('render one frame per city', () async {
    final sprites = await _loadSprites();
    final outDir = Directory('build/cities');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    for (final location in worldLocations) {
      final game = WeatherSceneGame(
        config: WeatherSceneConfig(
          weatherCode: 1,
          isDay: true,
          temperatureC: 24,
          windKmh: 9,
          location: location,
          cloudCover: 22,
          visibilityM: 10000,
          windDirectionDeg: 180,
          month: 4,
          latitude: location.latitude,
          longitude: location.longitude,
          city: location.name,
          localHour: 13,
        ),
      );
      game.debugSetSprites(sprites);
      game.onGameResize(Vector2(W.toDouble(), H.toDouble()));
      for (var i = 0; i < 90; i++) {
        game.update(1 / 60);
      }
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final image = await recorder.endRecording().toImage(W, H);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${outDir.path}/${location.id}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
    // ignore: avoid_print
    print('wrote ${worldLocations.length} city frames to ${outDir.path}');
  });
}
