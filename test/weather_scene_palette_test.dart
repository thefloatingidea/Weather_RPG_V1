import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:weather_rpg/weather_scene.dart';

void main() {
  group('weather scene time-of-day palettes', () {
    test('clear night stays dark and clear day stays bright', () {
      final night = weatherSceneSkyColor(
        isDay: false,
        sandstorm: false,
        storm: false,
        rain: false,
        fog: false,
        overcast: false,
        snowy: false,
        hot: true,
        spring: false,
        summer: true,
        cloudCover: 8,
      );
      final day = weatherSceneSkyColor(
        isDay: true,
        sandstorm: false,
        storm: false,
        rain: false,
        fog: false,
        overcast: false,
        snowy: false,
        hot: false,
        spring: true,
        summer: false,
        cloudCover: 8,
      );

      expect(night, const Color(0xFF101B35));
      expect(day, const Color(0xFF86C9D3));
      expect(night.computeLuminance(), lessThan(.03));
    });

    test('night weather layers never replace the dark time palette', () {
      final rainyNight = weatherSceneSkyColor(
        isDay: false,
        sandstorm: false,
        storm: true,
        rain: true,
        fog: false,
        overcast: true,
        snowy: false,
        hot: false,
        spring: false,
        summer: false,
        cloudCover: 100,
      );
      final sandstormNight = weatherSceneSkyColor(
        isDay: false,
        sandstorm: true,
        storm: false,
        rain: false,
        fog: false,
        overcast: false,
        snowy: false,
        hot: true,
        spring: false,
        summer: false,
        cloudCover: 12,
      );

      expect(rainyNight.computeLuminance(), lessThan(.03));
      expect(sandstormNight.computeLuminance(), lessThan(.05));
    });

    test('dry cold ground is not assigned a snow palette', () {
      final dryColdNight = weatherSceneGroundColor(
        isDay: false,
        arid: false,
        snow: false,
        rain: false,
        storm: false,
        autumn: false,
        spring: false,
        summer: false,
        winterSeason: false,
      );
      final snowyNight = weatherSceneGroundColor(
        isDay: false,
        arid: false,
        snow: true,
        rain: false,
        storm: false,
        autumn: false,
        spring: false,
        summer: false,
        winterSeason: false,
      );

      expect(dryColdNight, const Color(0xFF1D3B35));
      expect(snowyNight, const Color(0xFF354957));
      expect(dryColdNight, isNot(snowyNight));
    });
  });
}
