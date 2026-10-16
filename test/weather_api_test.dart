import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_rpg/weather_api.dart';
import 'package:weather_rpg/weather_models.dart';

void main() {
  group('WeatherAPI.com normalization', () {
    test('infers day from local sunrise and sunset if is_day is absent', () {
      final night = WeatherBundle.fromWeatherApiJson({
        'location': {'localtime': '2026-10-15 20:30'},
        'current': {
          'condition': {'code': 1000}
        },
        'forecast': {
          'forecastday': [
            {
              'date': '2026-10-15',
              'day': {
                'condition': {'code': 1000}
              },
              'astro': {'sunrise': '06:10 AM', 'sunset': '05:45 PM'},
              'hour': [],
            },
          ],
        },
      });

      expect(night.current['is_day'], 0);
    });

    test('converts current, hourly, and daily forecast fields', () {
      final weather = WeatherBundle.fromWeatherApiJson({
        'location': {'localtime': '2026-10-15 09:00'},
        'current': {
          'temp_c': 24.5,
          'humidity': 62,
          'feelslike_c': 25.2,
          'is_day': 1,
          'precip_mm': 1.4,
          'wind_kph': 18.0,
          'wind_degree': 210,
          'cloud': 54,
          'vis_km': 9.0,
          'condition': {'code': 1183},
        },
        'forecast': {
          'forecastday': [
            {
              'date': '2026-10-15',
              'day': {
                'maxtemp_c': 28.0,
                'mintemp_c': 21.0,
                'daily_chance_of_rain': 75,
                'totalprecip_mm': 4.0,
                'condition': {'code': 1183},
              },
              'astro': {'sunrise': '06:12 AM', 'sunset': '06:04 PM'},
              'hour': [
                {
                  'time': '2026-10-15 09:00',
                  'temp_c': 24.5,
                  'chance_of_rain': 75,
                  'condition': {'code': 1183},
                },
              ],
            },
          ],
        },
      });

      expect(weather.current['time'], '2026-10-15 09:00');
      expect(weather.current['weather_code'], 61);
      expect(weather.current['visibility'], 9000);
      expect(weather.hourly['precipitation_probability'], [75]);
      expect(weather.daily['weather_code'], [61]);
      expect(weather.daily['temperature_2m_max'], [28.0]);
      expect(weather.daily['precipitation_probability_max'], [75]);
      expect(WeatherBundle.fromJson(weather.toJson()).daily['time'],
          ['2026-10-15']);
    });

    test('maps dust, freezing fog, snow showers, and thunderstorms', () {
      expect(weatherApiConditionCode(1024), 30);
      expect(weatherApiConditionCode(1147), 48);
      expect(weatherApiConditionCode(1258), 75);
      expect(weatherApiConditionCode(1276), 96);
    });
  });

  test('forecast request uses WeatherAPI key, location, and 3-day default',
      () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'location': {'localtime': '2026-10-15 09:00'},
          'current': {
            'condition': {'code': 1000}
          },
          'forecast': {'forecastday': []},
        }),
        200,
      );
    });
    final api = WeatherApiClient(apiKey: 'test-key', client: client);

    await api.fetchForecast(latitude: 19.07, longitude: 72.87);

    expect(requestedUri?.host, 'api.weatherapi.com');
    expect(requestedUri?.path, '/v1/forecast.json');
    expect(requestedUri?.queryParameters['key'], 'test-key');
    expect(requestedUri?.queryParameters['q'], '19.07,72.87');
    expect(requestedUri?.queryParameters['days'], '3');
    client.close();
  });
}
