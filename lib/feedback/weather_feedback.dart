import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../weather_rules.dart';

class WeatherFeedback {
  WeatherFeedback()
      : _player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

  final AudioPlayer _player;
  String? _currentTrack;
  bool enabled = true;

  Future<void> apply(WeatherCategory category) async {
    if (!enabled) return;

    final track = switch (category) {
      WeatherCategory.rain => 'audio/rain_loop.mp3',
      WeatherCategory.thunder => 'audio/storm_loop.mp3',
      WeatherCategory.snow => 'audio/wind_loop.mp3',
      _ => null,
    };

    if (track == _currentTrack) return;
    _currentTrack = track;

    await _player.stop();
    if (track != null) {
      try {
        await _player.play(AssetSource(track), volume: 0.35);
      } catch (_) {
        // Fallback safely if audio assets are missing
      }
    }
  }

  Future<void> lightningFlash() => HapticFeedback.mediumImpact();

  Future<void> discovery() => HapticFeedback.lightImpact();

  Future<void> dispose() => _player.dispose();
}