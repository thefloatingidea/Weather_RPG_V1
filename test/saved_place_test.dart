import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/world_catalog.dart';

void main() {
  group('saved place round trip', () {
    test('survives JSON encode and decode', () {
      const place = SavedPlace(
        city: 'Mumbai',
        region: 'Maharashtra, India',
        latitude: 19.076,
        longitude: 72.8777,
      );
      final restored = SavedPlace.parse(place.toJsonString());

      expect(restored, isNotNull);
      expect(restored!.city, place.city);
      expect(restored.region, place.region);
      expect(restored.latitude, closeTo(place.latitude, 1e-9));
      expect(restored.longitude, closeTo(place.longitude, 1e-9));
      expect(restored.samePlace(place), isTrue);
    });

    test('keeps a nickname through the round trip', () {
      const place = SavedPlace(
        city: 'Mumbai',
        region: 'Maharashtra, India',
        latitude: 19.076,
        longitude: 72.8777,
        label: 'Home',
      );
      final restored = SavedPlace.parse(place.toJsonString())!;

      expect(restored.label, 'Home');
      expect(restored.displayName, 'Home');
      expect(restored.subtitle, 'Mumbai');
    });
  });

  group('legacy City|Region migration', () {
    test('parses a plain region entry', () {
      final place = SavedPlace.parse('Mumbai|Maharashtra, India')!;

      expect(place.city, 'Mumbai');
      expect(place.region, 'Maharashtra, India');
      expect(place.latitude, 0);
      expect(place.longitude, 0);
      expect(place.displayName, 'Mumbai');
      expect(place.subtitle, 'Maharashtra, India');
    });

    test('an entry with no region parses', () {
      final place = SavedPlace.parse('Paris')!;

      expect(place.city, 'Paris');
      expect(place.region, isEmpty);
      expect(place.subtitle, isEmpty);
    });

    test('promotes legacy device coordinates without losing the display text',
        () {
      // This is the shape the old code wrote for "Use my location".
      final place = SavedPlace.parse('My Location|19.076, 72.878')!;

      expect(place.city, 'My Location');
      expect(place.latitude, closeTo(19.076, 1e-9));
      expect(place.longitude, closeTo(72.878, 1e-9));
      // The old display is preserved rather than silently dropped.
      expect(place.region, '19.076, 72.878');
    });

    test('rejects malformed and empty entries', () {
      expect(SavedPlace.parse(''), isNull);
      expect(SavedPlace.parse('   '), isNull);
      expect(SavedPlace.parse('{not json'), isNull);
    });

    test('accepts a JSON object string even without the encoder', () {
      final place = SavedPlace.parse(
          jsonEncode({'city': 'Delhi', 'region': 'India', 'latitude': 28.6, 'longitude': 77.2}))!;

      expect(place.city, 'Delhi');
      expect(place.latitude, closeTo(28.6, 1e-9));
    });
  });

  group('place identity and nicknames', () {
    test('identity ignores the nickname and rounding noise', () {
      const plain = SavedPlace(
        city: 'Mumbai',
        region: 'Maharashtra, India',
        latitude: 19.0760,
        longitude: 72.8777,
      );
      const named = SavedPlace(
        city: 'Mumbai',
        region: 'Maharashtra, India',
        latitude: 19.07601,
        longitude: 72.87772,
        label: 'Home',
      );

      expect(named.samePlace(plain), isTrue);
      expect(named.id, plain.id);
    });

    test('different cities are different places', () {
      const a = SavedPlace(
          city: 'Mumbai', region: '', latitude: 19.076, longitude: 72.8777);
      const b = SavedPlace(
          city: 'Delhi', region: '', latitude: 28.61, longitude: 77.20);

      expect(a.samePlace(b), isFalse);
    });

    test('clearing a nickname restores the city name', () {
      const named = SavedPlace(
        city: 'Mumbai',
        region: 'Maharashtra, India',
        latitude: 19.076,
        longitude: 72.8777,
        label: 'Home',
      );
      final cleared = named.copyWith(clearLabel: true);

      expect(cleared.label, isNull);
      expect(cleared.displayName, 'Mumbai');
      expect(cleared.subtitle, 'Maharashtra, India');
    });

    test('a whitespace nickname is treated as no nickname', () {
      const place = SavedPlace(
        city: 'Mumbai',
        region: 'Maharashtra, India',
        latitude: 19.076,
        longitude: 72.8777,
        label: '   ',
      );

      expect(place.hasLabel, isFalse);
      expect(place.displayName, 'Mumbai');
    });
  });
}
