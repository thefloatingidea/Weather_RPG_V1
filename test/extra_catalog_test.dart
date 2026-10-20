import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/world_catalog.dart';
import 'package:weather_rpg/world_catalog_extra.dart';

void main() {
  test('extra places have unique ids and sane coordinates', () {
    final ids = worldLocations.map((l) => l.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final l in extraWorldLocations) {
      expect(l.latitude.abs() <= 90 && l.longitude.abs() <= 180, isTrue,
          reason: l.id);
      expect(l.landmark, WorldLandmark.none, reason: l.id);
      expect(l.climateOverride, isNotNull, reason: l.id);
    }
  });

  test('extra places resolve by name and country', () {
    for (final p in const [
      ('Udaipur', 'Rajasthan, India', 24.58, 73.71, 'udaipur'),
      ('Pondicherry', 'Puducherry, India', 11.94, 79.81, 'puducherry'),
      ('Riyadh', 'Saudi Arabia', 24.71, 46.68, 'riyadh'),
      ('Marrakesh', 'Morocco', 31.63, -7.98, 'marrakech'),
    ]) {
      final l = resolveWorldLocation(
          city: p.$1, region: p.$2, latitude: p.$3, longitude: p.$4);
      expect(l.id, p.$5, reason: p.$1);
    }
  });

  test('a same-named city on another continent is not captured', () {
    final l = resolveWorldLocation(
        city: 'Santiago',
        region: 'Galicia, Spain',
        latitude: 42.88,
        longitude: -8.54);
    expect(l.id, isNot('santiago'));
  });
}
