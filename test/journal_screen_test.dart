import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:weather_rpg/main.dart';

/// A cached forecast for the default location, so the app renders tab content
/// instead of the error screen (the live fetch cannot succeed in a test).
///
/// The arrays are non-empty on purpose: the home screen indexes `daily` and
/// `hourly` by position, so an empty list throws inside `build`.
String seedWeatherCache() => jsonEncode({
      'city': 'Mumbai',
      'region': 'Maharashtra, India',
      'latitude': 19.0760,
      'longitude': 72.8777,
      'savedAt': DateTime(2026, 1, 1, 12).toIso8601String(),
      'weather': {
        'current': {
          'time': '2026-01-01 12:00',
          'weather_code': 1,
          'is_day': 1,
          'temperature_2m': 27.0,
          'apparent_temperature': 29.0,
          'relative_humidity_2m': 60,
          'wind_speed_10m': 12.0,
          'wind_direction_10m': 220.0,
          'precipitation': 0.0,
          'cloud_cover': 20.0,
          'visibility': 10000.0,
        },
        'hourly': {
          'time': [
            for (var i = 0; i < 24; i++)
              '2026-01-01 ${i.toString().padLeft(2, '0')}:00'
          ],
          'temperature_2m': [for (var i = 0; i < 24; i++) 25.0 + i % 5],
          'weather_code': [for (var i = 0; i < 24; i++) 1],
          'precipitation_probability': [for (var i = 0; i < 24; i++) 10 + i % 20],
        },
        'daily': {
          'time': ['2026-01-01', '2026-01-02', '2026-01-03'],
          'weather_code': [1, 2, 3],
          'temperature_2m_max': [31.0, 32.0, 30.0],
          'temperature_2m_min': [21.0, 22.0, 20.0],
          'precipitation_probability_max': [10, 25, 40],
          'rain_sum': [0.0, 1.5, 4.0],
          'sunrise': ['06:30', '06:31', '06:32'],
          'sunset': ['18:15', '18:16', '18:17'],
        },
      },
    });

/// A profile that has collected one landmark, two weather memories and two
/// worlds, plus a repeat visit.
String seedProfile() => jsonEncode({
      'visitedLocations': ['agra', 'paris'],
      'visitCounts': {'agra': 3, 'paris': 1},
      'discoveries': [
        'visit:agra:1',
        'landmark:agra:tajMahal',
        'visit:agra:2',
        'visit:agra:3',
        'visit:paris:1',
        'landmark:paris:eiffelTower',
        'weather:rain',
      ],
      'weatherExperiences': ['rain', 'season:summer'],
      'recentEvents': [
        {
          'id': 'visit:agra:1',
          'title': 'Visited Agra',
          'detail': 'A new place joined the goblin’s map.',
          'at': DateTime(2026, 1, 1, 9).toIso8601String(),
        },
        {
          'id': 'landmark:agra:tajMahal',
          'title': 'Spotted Taj Mahal',
          'detail': 'The goblin took a moment to study the landmark.',
          'at': DateTime(2026, 1, 1, 9, 1).toIso8601String(),
        },
      ],
      'currentLocationId': 'agra',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> pumpApp(WidgetTester tester, {String? profileJson}) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('weatherapi_cache_v1', seedWeatherCache());
    if (profileJson != null) {
      await prefs.setString('character_profile_v1', profileJson);
    }
    await tester.pumpWidget(const WeatherRpgApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openJournal(WidgetTester tester) async {
    final tab = find.text('Journal');
    expect(tab, findsWidgets, reason: 'Journal tab is missing');
    await tester.tap(tab.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// The journal is a scrolling list, so lower cards are not built until they
  /// come into view.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      140,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 240,
    );
    await tester.pump();
  }

  testWidgets('an empty journal explains how to start', (tester) async {
    await pumpApp(tester);
    await openJournal(tester);

    expect(find.text('GOBLIN JOURNAL'), findsOneWidget);
    expect(
      find.textContaining('The journal is empty'),
      findsOneWidget,
    );
    // Landmarks are still listed, all locked.
    expect(find.text('LANDMARKS  ·  0/27'), findsOneWidget);
    expect(find.text('???'), findsWidgets);
    await scrollTo(tester, find.text('Nothing remembered yet.'));
    expect(find.text('Nothing remembered yet.'), findsOneWidget);
  });

  testWidgets('a seeded profile shows its collection', (tester) async {
    await pumpApp(tester, profileJson: seedProfile());
    await openJournal(tester);

    expect(find.text('COLLECTION'), findsOneWidget);
    // Both seeded landmarks were discovered, out of the whole catalogue.
    expect(find.text('LANDMARKS  ·  2/27'), findsOneWidget);
    // Taj Mahal was collected, so it is named rather than hidden.
    expect(find.text('Taj Mahal'), findsOneWidget);
    expect(find.text('Eiffel Tower'), findsOneWidget);
    // Visit totals and the most revisited world.
    expect(find.text('4 total visits'), findsOneWidget);
    expect(find.text('Most revisited: Agra'), findsOneWidget);
    // Weather memories are shown as chips, with locked siblings.
    await scrollTo(tester, find.text('First rain'));
    expect(find.text('First rain'), findsOneWidget);
    expect(find.text('Locked'), findsWidgets);
  });

  testWidgets('recent memories are listed', (tester) async {
    await pumpApp(tester, profileJson: seedProfile());
    await openJournal(tester);

    await scrollTo(tester, find.text('Visited Agra'));
    expect(find.text('Visited Agra'), findsOneWidget);
    expect(find.text('Spotted Taj Mahal'), findsOneWidget);
  });
}
