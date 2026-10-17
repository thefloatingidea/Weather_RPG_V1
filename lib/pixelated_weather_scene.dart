import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'weather_scene.dart';

/// A wrapper game that renders the [WeatherSceneGame] at a lower resolution
/// and then upscales it using nearest‑neighbor filtering to achieve a 16‑bit
/// pixel‑art look. The wrapper respects the existing [WeatherSceneConfig]
/// and forwards all input events to the inner game.
class PixelatedWeatherSceneGame extends FlameGame {
  final WeatherSceneConfig config;
  late final WeatherSceneGame _inner;

  // Downscale factor – 3 makes each pixel cover a 3×3 block.
  static const int _scaleFactor = 3;

  PixelatedWeatherSceneGame({required this.config}) {
    _inner = WeatherSceneGame(config: config);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _inner.onLoad();
    // Add the inner game as a component so that Flame forwards events.
    add(_inner);
  }

  @override
  void render(Canvas canvas) {
    // Record the inner game at a reduced size.
    final double width = size.x / _scaleFactor;
    final double height = size.y / _scaleFactor;
    final recorder = ui.PictureRecorder();
    final offscreenCanvas = Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, width, height),
    );
    // Scale down before rendering.
    offscreenCanvas.scale(1 / _scaleFactor);
    _inner.render(offscreenCanvas);
    final picture = recorder.endRecording();

    // Draw the picture back to the main canvas, scaling up with nearest‑neighbor.
    // Using drawImageRect with FilterQuality.none forces nearest‑neighbor.
    picture.toImage(width.ceil(), height.ceil()).then((ui.Image img) {
      final src = ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      final dst = ui.Rect.fromLTWH(0, 0, size.x, size.y);
      final paint = Paint()..filterQuality = FilterQuality.none;
      canvas.drawImageRect(img, src, dst, paint);
      img.dispose();
    });
  }

  // Forward input events to the inner game.
  @override
  bool handleTapDown(int pointerId, TapDownInfo info) =>
      _inner.handleTapDown(pointerId, info);
  @override
  bool handleTapUp(int pointerId, TapUpInfo info) =>
      _inner.handleTapUp(pointerId, info);
  @override
  bool handleLongPressStart(int pointerId, LongPressStartInfo info) =>
      _inner.handleLongPressStart(pointerId, info);
  @override
  bool handleLongPressEnd(int pointerId, LongPressEndInfo info) =>
      _inner.handleLongPressEnd(pointerId, info);
}
