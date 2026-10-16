import 'package:flame/cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/goblin_sprites.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('goblin sprite assets', () {
    test('every frame is declared in the asset bundle', () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final declared = manifest.listAssets().toSet();

      final expected = <String>{
        for (final name in GoblinSprites.filenames) 'assets/images/$name',
      };

      expect(expected, hasLength(16));
      expect(
        expected.difference(declared),
        isEmpty,
        reason: 'These sprite frames are missing from the bundle. Check the '
            'assets: entry in pubspec.yaml.',
      );
    });

    test('warmCache loads all frames through the real bundle', () async {
      final cache = Images();
      await GoblinSprites.warmCache(images: cache);
      final sprites = GoblinSprites.fromCache(images: cache);

      expect(sprites.isEmpty, isFalse);
      expect(sprites.idle, hasLength(GoblinSprites.idleFrameCount));
      expect(sprites.walk, hasLength(GoblinSprites.walkFrameCount));
      for (final frame in [...sprites.idle, ...sprites.walk]) {
        expect(frame.srcSize.x, GoblinSprites.frameWidthPx.toDouble());
        expect(frame.srcSize.y, GoblinSprites.frameHeightPx.toDouble());
        expect(frame.image.width, GoblinSprites.frameWidthPx);
        expect(frame.image.height, GoblinSprites.frameHeightPx);
      }
    });

    test('frame selection cycles, wraps and stays in range', () async {
      final cache = Images();
      await GoblinSprites.warmCache(images: cache);
      final sprites = GoblinSprites.fromCache(images: cache);

      expect(sprites.idleFrameAt(0), same(sprites.idle[0]));
      expect(sprites.idleFrameAt(1 / 8), same(sprites.idle[1]));
      // A full cycle wraps back to the first frame.
      expect(sprites.idleFrameAt(1.0), same(sprites.idle[0]));
      // Negative time must not produce a range error.
      expect(sprites.idleFrameAt(-1 / 8), same(sprites.idle[7]));
      expect(sprites.walkFrameAt(0), same(sprites.walk[0]));
      // A long elapsed time stays in range rather than overflowing.
      expect(sprites.walkFrameAt(3600.0), isNotNull);
    });

    test('an empty frame set reports itself as empty', () {
      final sprites = GoblinSprites.fromImages(const {});
      expect(sprites.isEmpty, isTrue);
      expect(() => sprites.idleFrameAt(0), throwsStateError);
    });
  });
}
