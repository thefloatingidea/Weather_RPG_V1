// Diagnostic: renders one city at a sequence of local hours so the sun arc and
// the dusk/dawn lighting can be reviewed as a strip.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/goblin_sprites.dart';
import 'package:weather_rpg/weather_scene.dart';
import 'package:weather_rpg/world_catalog.dart';

const int W = 480, H = 240;
const hours = [5, 7, 9, 12, 15, 17, 18, 19, 20, 22];

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

  test('render a day of lighting', () async {
    final sprites = await _loadSprites();
    final delhi = worldLocations.firstWhere((l) => l.id == 'delhi');
    final outDir = Directory('build/lighting');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    for (final hour in hours) {
      final game = WeatherSceneGame(
        config: WeatherSceneConfig(
          weatherCode: 0,
          // Matches how the app derives `is_day`: 6..18 are daylight hours. The
          // sun arc itself is driven by `localHour`.
          isDay: hour >= 6 && hour < 18,
          temperatureC: 24,
          windKmh: 8,
          location: delhi,
          cloudCover: 8,
          visibilityM: 12000,
          windDirectionDeg: 180,
          month: 4,
          latitude: delhi.latitude,
          longitude: delhi.longitude,
          city: delhi.name,
          localHour: hour,
        ),
      );
      game.debugSetSprites(sprites);
      game.onGameResize(Vector2(W.toDouble(), H.toDouble()));
      for (var i = 0; i < 120; i++) {
        game.update(1 / 60);
      }
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      final image = await recorder.endRecording().toImage(W, H);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${outDir.path}/${hour.toString().padLeft(2, '0')}.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    }
    // ignore: avoid_print
    print('wrote ${hours.length} hourly frames');
  });
}
