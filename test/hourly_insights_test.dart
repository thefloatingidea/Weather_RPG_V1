import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/hourly_insights.dart';
import 'package:weather_rpg/weather_models.dart';

Map<String, dynamic> _hour(String time, int i) => {
      'time': time,
      'temp_c': 30.0 + i,
      'feelslike_c': 33.0 + i,
      'wind_kph': 10.0 + i,
      'humidity': 60 + i,
      'uv': 5.0,
      'chance_of_rain': 10 * i,
      'condition': {'code': 1000},
    };

Map<String, dynamic> _sample({bool withAir = true}) => {
      'location': {'localtime': '2026-10-18 17:30'},
      'current': {
        'temp_c': 33.0,
        'feelslike_c': 36.0,
        'humidity': 60,
        'is_day': 1,
        'precip_mm': 0.0,
        'wind_kph': 12.0,
        'wind_degree': 200,
        'cloud': 10,
        'vis_km': 6.0,
        'uv': 7.0,
        'condition': {'code': 1000},
        if (withAir)
          'air_quality': {
            'co': 400.0,
            'no2': 20.5,
            'o3': 55.0,
            'so2': 8.0,
            'pm2_5': 42.0,
            'pm10': 80.0,
            'us-epa-index': 3,
            'gb-defra-index': 4,
          },
      },
      'forecast': {
        'forecastday': [
          {
            'date': '2026-10-18',
            'day': {
              'maxtemp_c': 34.0,
              'mintemp_c': 26.0,
              'daily_chance_of_rain': 10,
              'totalprecip_mm': 0.0,
              'condition': {'code': 1000},
            },
            'astro': {
              'sunrise': '06:25 AM',
              'sunset': '06:05 PM',
              'moonrise': 'No moonrise',
              'moonset': '02:10 PM',
              'moon_phase': 'Waxing Gibbous',
              'moon_illumination': '73',
            },
            'hour': [
              _hour('2026-10-18 00:00', 0),
              _hour('2026-10-18 01:00', 1),
            ],
          },
        ],
      },
    };

void main() {
  group('WeatherBundle.fromWeatherApiJson', () {
    test('exposes extra hourly series', () {
      final bundle = WeatherBundle.fromWeatherApiJson(_sample());
      expect(bundle.hourly['apparent_temperature'], [33.0, 34.0]);
      expect(bundle.hourly['wind_speed_10m'], [10.0, 11.0]);
      expect(bundle.hourly['relative_humidity_2m'], [60.0, 61.0]);
      expect(bundle.hourly['uv_index'], [5.0, 5.0]);
    });

    test('exposes astro data', () {
      final bundle = WeatherBundle.fromWeatherApiJson(_sample());
      expect(bundle.daily['moon_phase'], ['Waxing Gibbous']);
      expect(bundle.daily['moon_illumination'], [73]);
      expect(bundle.daily['moonrise'], ['No moonrise']);
    });

    test('keeps air quality when present', () {
      final air = WeatherBundle.fromWeatherApiJson(_sample()).current['air_quality']
          as Map;
      expect(air['us_epa_index'], 3);
      expect(air['pm2_5'], 42.0);
    });

    test('omits air quality when the block is absent', () {
      final bundle = WeatherBundle.fromWeatherApiJson(_sample(withAir: false));
      expect(bundle.current.containsKey('air_quality'), isFalse);
    });

    test('survives a JSON round trip', () {
      final bundle = WeatherBundle.fromWeatherApiJson(_sample());
      final copy = WeatherBundle.fromJson(
          Map<String, dynamic>.from(bundle.toJson()));
      expect((copy.current['air_quality'] as Map)['us_epa_index'], 3);
    });
  });

  group('sun position', () {
    test('parses 12-hour clock strings', () {
      expect(parseClockMinutes('06:25 AM'), 6 * 60 + 25);
      expect(parseClockMinutes('12:05 AM'), 5);
      expect(parseClockMinutes('12:30 PM'), 12 * 60 + 30);
      expect(parseClockMinutes('06:05 PM'), 18 * 60 + 5);
      expect(parseClockMinutes('No moonrise'), isNull);
      expect(parseClockMinutes(null), isNull);
    });

    test('progress is mid-arc at solar noon', () {
      final sun = SunPosition.tryCreate(
        sunrise: '06:00 AM',
        sunset: '06:00 PM',
        localTime: '2026-10-18 12:00',
      )!;
      expect(sun.isUp, isTrue);
      expect(sun.progress, closeTo(0.5, 1e-9));
      expect(sun.status, '6h 00m of daylight left');
    });

    test('no progress at night', () {
      final sun = SunPosition.tryCreate(
        sunrise: '06:00 AM',
        sunset: '06:00 PM',
        localTime: '2026-10-18 22:00',
      )!;
      expect(sun.progress, isNull);
      expect(sun.status, 'The sun has set');
    });

    test('before sunrise reports time to sunrise', () {
      final sun = SunPosition.tryCreate(
        sunrise: '06:00 AM',
        sunset: '06:00 PM',
        localTime: '2026-10-18 04:30',
      )!;
      expect(sun.status, 'Sunrise in 1h 30m');
    });

    test('returns null on unparseable input', () {
      expect(
        SunPosition.tryCreate(
            sunrise: 'x', sunset: '06:00 PM', localTime: '2026-10-18 12:00'),
        isNull,
      );
    });
  });

  group('moon and aqi', () {
    test('moon emoji and illumination parsing', () {
      expect(moonEmoji('Full Moon'), '🌕');
      expect(moonEmoji('Waning Crescent'), '🌘');
      expect(moonEmoji('???'), '🌙');
      expect(parseIllumination('73'), 73);
      expect(parseIllumination(41), 41);
      expect(parseIllumination('n/a'), isNull);
    });

    test('aqi bands', () {
      expect(aqiBandFor(1)!.label, 'Good');
      expect(aqiBandFor(6)!.label, 'Hazardous');
      expect(aqiBandFor(0), isNull);
      expect(aqiBandFor(7), isNull);
      expect(aqiBandFor(null), isNull);
    });

    test('parseAirQuality requires the epa index', () {
      expect(parseAirQuality(null), isNull);
      expect(parseAirQuality(<String, dynamic>{}), isNull);
      expect(parseAirQuality({'pm2_5': 3.0}), isNull);
    });

    test('uv categories', () {
      expect(uvCategory(2.9), 'Low');
      expect(uvCategory(5), 'Moderate');
      expect(uvCategory(7), 'High');
      expect(uvCategory(9), 'Very high');
      expect(uvCategory(11), 'Extreme');
    });
  });
}
