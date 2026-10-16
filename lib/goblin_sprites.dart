import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/game.dart' show Vector2;
import 'package:flame/sprite.dart';

/// Loads and holds the goblin character sprite frames.
///
/// The frames ship as individual PNGs under `assets/images/goblin_frames/`
/// rather than as one atlas, so they are warmed into a shared [Images] cache
/// once at startup and then rebuilt for each scene from that cache.
///
/// Frame geometry, verified against the shipped files:
///   size          96 x 112
///   idle frames   8  (idle_00 .. idle_07)
///   walk frames   8  (walk_00 .. walk_07)
///   art bounds    x 4..91, y 9..109, so the feet sit at row 109
class GoblinSprites {
  const GoblinSprites({
    required this.idle,
    required this.walk,
    this.frameWidth = frameWidthPx,
    this.frameHeight = frameHeightPx,
    this.feetY = feetRow,
  });

  /// Directory under the default `assets/images/` prefix.
  static const String folder = 'goblin_frames';

  static const int frameWidthPx = 96;
  static const int frameHeightPx = 112;

  /// Lowest opaque pixel row in the source art, measured from the top.
  static const double feetRow = 109;

  static const int idleFrameCount = 8;
  static const int walkFrameCount = 8;

  static String _pad(int value) => value.toString().padLeft(2, '0');

  static final List<String> _filenames = [
    for (var i = 0; i < idleFrameCount; i++) '$folder/idle_${_pad(i)}.png',
    for (var i = 0; i < walkFrameCount; i++) '$folder/walk_${_pad(i)}.png',
  ];

  final List<Sprite> idle;
  final List<Sprite> walk;
  final int frameWidth;
  final int frameHeight;

  /// Source-art row of the feet, used to seat the sprite on the scene floor.
  final double feetY;

  bool get isEmpty => idle.isEmpty && walk.isEmpty;

  /// Warms the shared image cache. Safe to call more than once: [Images] caches
  /// by name, so a repeat call is cheap and does not re-decode.
  static Future<void> warmCache({Images? images}) async {
    await (images ?? Images()).loadAll(_filenames);
  }

  /// Builds the frame lists from already-warmed images.
  ///
  /// Throws if [warmCache] has not completed, so a missing warm-up fails loudly
  /// instead of silently dropping the character.
  static GoblinSprites fromCache({Images? images}) {
    final cache = images ?? Images();
    return fromImages({
      for (final name in _filenames) name: cache.fromCache(name),
    });
  }

  /// Builds the frame lists from decoded images keyed by
  /// `goblin_frames/<kind>_<nn>.png`.
  ///
  /// This is the seam used by tests, which drive the frames from disk because
  /// `flutter test` does not build the asset bundle.
  static GoblinSprites fromImages(Map<String, ui.Image> frames) {
    List<Sprite> build(int count, String kind) => [
          for (var i = 0; i < count; i++)
            if (frames['$folder/${kind}_${_pad(i)}.png'] != null)
              Sprite(
                frames['$folder/${kind}_${_pad(i)}.png']!,
                srcPosition: Vector2.zero(),
                srcSize: Vector2(
                  frameWidthPx.toDouble(),
                  frameHeightPx.toDouble(),
                ),
              ),
        ];
    return GoblinSprites(
      idle: build(idleFrameCount, 'idle'),
      walk: build(walkFrameCount, 'walk'),
    );
  }

  /// The frame filenames, in idle-then-walk order.
  static List<String> get filenames => List.unmodifiable(_filenames);

  /// Idle frame for [elapsed] seconds of animation time.
  Sprite idleFrameAt(double elapsed, {double fps = 8}) =>
      _frameAt(idle, elapsed, fps);

  /// Walk frame for [elapsed] seconds of animation time.
  Sprite walkFrameAt(double elapsed, {double fps = 11}) =>
      _frameAt(walk, elapsed, fps);

  Sprite _frameAt(List<Sprite> frames, double elapsed, double fps) {
    if (frames.isEmpty) {
      throw StateError('Goblin sprite frames were not loaded.');
    }
    final raw = (elapsed * fps).floor() % frames.length;
    return frames[raw < 0 ? raw + frames.length : raw];
  }
}
