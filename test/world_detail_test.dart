import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/climate_boxes.dart';
import 'package:weather_rpg/world_catalog.dart';
import 'package:weather_rpg/world_detail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed and random numbers are stable and in range', () {
    expect(detailSeed('agra'), detailSeed('agra'));
    expect(detailSeed('agra'), isNot(detailSeed('paris')));
    for (var i = 0; i < 300; i++) {
      final r = detailRandom(123, i, 0);
      expect(r >= 0 && r < 1, isTrue);
      expect(detailRandom(123, i, 0), r);
    }
  });

  test('every biome paints in every ground state without throwing', () {
    for (final biome in WorldBiome.values) {
      for (final arid in [false, true]) {
        for (final winter in [false, true]) {
          for (final storm in [false, true]) {
            final recorder = ui.PictureRecorder();
            final canvas = ui.Canvas(recorder);
            paintBiomeGroundDetail(
              canvas,
              WorldDetailContext(
                w: 720,
                h: 340,
                seed: 42,
                biome: biome,
                arid: arid,
                winter: winter,
                storm: storm,
                elapsed: 3.2,
              ),
            );
            recorder.endRecording();
          }
        }
      }
    }
  });

  test('lantern moths paint', () {
    final recorder = ui.PictureRecorder();
    paintLanternMoths(ui.Canvas(recorder), const ui.Offset(100, 100), 4, 2.5, 7);
    recorder.endRecording();
  });

  test('every climate zone paints without throwing', () {
    for (final zone in ClimateZone.values) {
      final recorder = ui.PictureRecorder();
      paintBiomeGroundDetail(
        ui.Canvas(recorder),
        WorldDetailContext(
          w: 720,
          h: 340,
          seed: 7,
          biome: WorldBiome.temperate,
          arid: false,
          winter: false,
          storm: false,
          elapsed: 1.0,
          zone: zone,
        ),
      );
      recorder.endRecording();
    }
  });

  group('climate boxes', () {
    const cases = <(String, double, double, ClimateZone?)>[
      ('Riyadh', 24.7, 46.7, ClimateZone.subtropicalDesert),
      ('Phoenix', 33.4, -112.1, ClimateZone.subtropicalDesert),
      ('Alice Springs', -23.7, 133.9, ClimateZone.subtropicalDesert),
      ('Kandahar', 31.6, 65.7, ClimateZone.subtropicalDesert),
      ('Windhoek', -22.56, 17.08, ClimateZone.subtropicalDesert),
      ('Antofagasta', -23.65, -70.4, ClimateZone.subtropicalDesert),
      ('Lhasa', 29.65, 91.1, ClimateZone.alpine),
      ('Kabul', 34.5, 69.2, ClimateZone.alpine),
      ('Denver', 39.74, -104.99, ClimateZone.alpine),
      ('Quito', -0.2, -78.5, ClimateZone.alpine),
      ('La Paz', -16.5, -68.1, ClimateZone.alpine),
      ('Manaus', -3.1, -60.0, ClimateZone.tropicalRainforest),
      ('Kinshasa', -4.3, 15.3, ClimateZone.tropicalRainforest),
      ('Dhaka', 23.8, 90.4, ClimateZone.tropicalRainforest),
      ('Guangzhou', 23.1, 113.3, ClimateZone.tropicalRainforest),
      ('Taipei', 25.0, 121.5, ClimateZone.tropicalRainforest),
      ('Miami', 25.8, -80.2, ClimateZone.tropicalRainforest),
      ('Houston', 29.8, -95.4, ClimateZone.temperateDeciduous),
      ('Shanghai', 31.2, 121.5, ClimateZone.temperateDeciduous),
      ('Anchorage', 61.2, -149.9, ClimateZone.boreal),
      ('Nuuk', 64.2, -51.7, ClimateZone.polar),
      ('Delhi', 28.6, 77.2, null),
      ('Karachi', 24.9, 67.0, null),
      ('Lima', -12.05, -77.04, null),
      ('Nairobi', -1.3, 36.8, null),
      ('Reykjavik', 64.1, -21.9, null),
    ];
    for (final c in cases) {
      test('${c.$1} -> ${c.$4}', () {
        expect(climateZoneByBox(c.$2, c.$3), c.$4);
      });
    }
  });

  group('places outside the catalog', () {
    test('humid Asian and American places are not desert', () {
      for (final p in const [
        ('Chittagong', 'Chittagong, Bangladesh', 22.3, 91.8),
        ('Kunming', 'Yunnan, China', 25.0, 102.7),
        ('Fort Lauderdale', 'Florida, United States of America', 26.1, -80.1),
      ]) {
        final l = resolveWorldLocation(
            city: p.$1, region: p.$2, latitude: p.$3, longitude: p.$4);
        expect(l.isArid, isFalse, reason: p.$1);
        expect(l.climate, ClimateZone.tropicalRainforest, reason: p.$1);
        expect(l.biome, WorldBiome.tropical, reason: p.$1);
      }
    });

    test('real deserts are desert', () {
      for (final p in const [
        ('Alice Springs', 'Northern Territory, Australia', -23.7, 133.9),
        ('Kandahar', 'Afghanistan', 31.6, 65.7),
      ]) {
        final l = resolveWorldLocation(
            city: p.$1, region: p.$2, latitude: p.$3, longitude: p.$4);
        expect(l.biome, WorldBiome.desert, reason: p.$1);
        expect(l.climate, ClimateZone.subtropicalDesert, reason: p.$1);
      }
    });

    test('fallback places carry the climate chosen while resolving', () {
      final l = resolveWorldLocation(
          city: 'Wuhan', region: 'Hubei, China', latitude: 30.6, longitude: 114.3);
      expect(l.climate, ClimateZone.temperateDeciduous);
    });
  });
}
