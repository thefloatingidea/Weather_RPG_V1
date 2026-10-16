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
String _seedWeatherCache() => jsonEncode({
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
          'time': [for (var i = 0; i < 24; i++) '2026-01-01 ${i.toString().padLeft(2, '0')}:00'],
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await SharedPreferencesAsync().setString(
      'weatherapi_cache_v1',
      _seedWeatherCache(),
    );
    await tester.pumpWidget(const WeatherRpgApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Bounded settling: the app runs a continuously repeating backdrop
  /// animation, so pumpAndSettle would never return.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> openPlaces(WidgetTester tester) async {
    final placesTab = find.text('Places');
    expect(placesTab, findsWidgets, reason: 'Places tab is missing');
    await tester.tap(placesTab.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the places screen lists the default saved place',
      (tester) async {
    await pumpApp(tester);
    await openPlaces(tester);

    expect(find.text('YOUR PLACES'), findsOneWidget);
    expect(find.text('MUMBAI'), findsOneWidget);
    expect(find.text('ADD A LOCATION'), findsOneWidget);
    expect(find.text('USE MY LOCATION'), findsOneWidget);
  });

  testWidgets('a saved place can be removed', (tester) async {
    await pumpApp(tester);
    await openPlaces(tester);

    expect(find.text('MUMBAI'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pump();

    expect(find.text('MUMBAI'), findsNothing);
    expect(
      find.text('No saved places yet. Add one above to keep it here.'),
      findsOneWidget,
    );
  });

  testWidgets('a saved place can be given a nickname', (tester) async {
    await pumpApp(tester);
    await openPlaces(tester);

    await tester.tap(find.byTooltip('Nickname').first);
    await settle(tester);
    expect(find.text('Nickname for Mumbai'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Home');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    await settle(tester);

    // The nickname heads the row and the city drops to the sub-line.
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Mumbai'), findsOneWidget);
    expect(find.text('MUMBAI'), findsNothing);
  });

  testWidgets('a nickname can be cleared back to the city name',
      (tester) async {
    await pumpApp(tester);
    await openPlaces(tester);

    await tester.tap(find.byTooltip('Nickname').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Home');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    await settle(tester);
    expect(find.text('HOME'), findsOneWidget);

    await tester.tap(find.byTooltip('Nickname').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await settle(tester);

    expect(find.text('HOME'), findsNothing);
    expect(find.text('MUMBAI'), findsOneWidget);
  });

  testWidgets('a custom nickname survives a restart', (tester) async {
    await pumpApp(tester);
    await openPlaces(tester);

    await tester.tap(find.byTooltip('Nickname').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'HQ');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    await settle(tester);
    expect(find.text('HQ'), findsOneWidget);

    // Rebuild the app from the persisted preferences.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const WeatherRpgApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await openPlaces(tester);

    expect(find.text('HQ'), findsOneWidget);
    expect(find.text('Mumbai'), findsOneWidget);
  });
}
