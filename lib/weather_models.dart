import 'package:flutter/material.dart';
export 'widgets/city_search_page.dart';

/// Weather normalized to the app's internal shape from WeatherAPI.com.
class WeatherBundle {
  const WeatherBundle({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final Map<String, dynamic> current;
  final Map<String, dynamic> hourly;
  final Map<String, dynamic> daily;

  Map<String, Object?> toJson() => {
        'current': current,
        'hourly': hourly,
        'daily': daily,
      };

  factory WeatherBundle.fromJson(Map<String, dynamic> json) => WeatherBundle(
        current: Map<String, dynamic>.from(json['current'] as Map),
        hourly: Map<String, dynamic>.from(json['hourly'] as Map),
        daily: Map<String, dynamic>.from(json['daily'] as Map),
      );

  factory WeatherBundle.fromWeatherApiJson(Map<String, dynamic> json) {
    Map<String, dynamic> asMap(Object? value) =>
        Map<String, dynamic>.from(value as Map? ?? const {});
    List<dynamic> asList(Object? value) => value as List<dynamic>? ?? const [];
    double number(Map<String, dynamic> map, String key,
            [double fallback = 0]) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    int conditionCode(Map<String, dynamic> map) {
      final condition = asMap(map['condition']);
      return weatherApiConditionCode((condition['code'] as num?)?.toInt() ?? 0);
    }

    final location = asMap(json['location']);
    final currentSource = asMap(json['current']);
    final forecast = asMap(json['forecast']);
    final forecastDays =
        asList(forecast['forecastday']).map((item) => asMap(item)).toList();
    int localMinutes(String? value) {
      if (value == null) return -1;
      final amPm =
          RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
              .firstMatch(value.trim());
      if (amPm != null) {
        var hour = int.parse(amPm.group(1)!);
        final minute = int.parse(amPm.group(2)!);
        final isPm = amPm.group(3)!.toUpperCase() == 'PM';
        if (hour == 12) hour = 0;
        return (hour + (isPm ? 12 : 0)) * 60 + minute;
      }
      final parsed = DateTime.tryParse(value);
      return parsed == null ? -1 : parsed.hour * 60 + parsed.minute;
    }

    int dayFlag() {
      final providerFlag = currentSource['is_day'] as num?;
      if (providerFlag != null) return providerFlag.toInt();
      final localTime = location['localtime']?.toString();
      final now = localMinutes(localTime);
      final firstDay = forecastDays.isEmpty ? null : forecastDays.first;
      final astro = firstDay == null
          ? const <String, dynamic>{}
          : asMap(firstDay['astro']);
      final sunrise = localMinutes(astro['sunrise']?.toString());
      final sunset = localMinutes(astro['sunset']?.toString());
      if (now >= 0 && sunrise >= 0 && sunset >= 0) {
        return now >= sunrise && now < sunset ? 1 : 0;
      }
      final localHour = DateTime.tryParse(localTime ?? '')?.hour;
      return localHour != null && localHour >= 6 && localHour < 18 ? 1 : 0;
    }

    final current = <String, dynamic>{
      'time': location['localtime'] ?? currentSource['last_updated'],
      'temperature_2m': number(currentSource, 'temp_c', 20),
      'relative_humidity_2m': number(currentSource, 'humidity').round(),
      'apparent_temperature': number(currentSource, 'feelslike_c', 20),
      'is_day': dayFlag(),
      'precipitation': number(currentSource, 'precip_mm'),
      'rain': number(currentSource, 'precip_mm'),
      'weather_code': conditionCode(currentSource),
      'wind_speed_10m': number(currentSource, 'wind_kph'),
      'wind_direction_10m': number(currentSource, 'wind_degree'),
      'cloud_cover': number(currentSource, 'cloud'),
      'visibility': number(currentSource, 'vis_km') * 1000,
    };

    final hours = <Map<String, dynamic>>[
      for (final day in forecastDays)
        for (final hour in asList(day['hour'])) asMap(hour),
    ];
    final days = forecastDays.map((item) {
      final day = asMap(item['day']);
      return (source: item, weather: day);
    }).toList();

    final hourly = <String, dynamic>{
      'time': hours.map((hour) => hour['time']).toList(),
      'temperature_2m': hours.map((hour) => number(hour, 'temp_c')).toList(),
      'precipitation_probability':
          hours.map((hour) => number(hour, 'chance_of_rain').round()).toList(),
      'weather_code': hours.map(conditionCode).toList(),
    };
    final daily = <String, dynamic>{
      'time': days.map((entry) => entry.source['date']).toList(),
      'weather_code':
          days.map((entry) => conditionCode(entry.weather)).toList(),
      'temperature_2m_max':
          days.map((entry) => number(entry.weather, 'maxtemp_c')).toList(),
      'temperature_2m_min':
          days.map((entry) => number(entry.weather, 'mintemp_c')).toList(),
      'precipitation_probability_max': days
          .map((entry) => number(entry.weather, 'daily_chance_of_rain').round())
          .toList(),
      'rain_sum':
          days.map((entry) => number(entry.weather, 'totalprecip_mm')).toList(),
      'sunrise':
          days.map((entry) => asMap(entry.source['astro'])['sunrise']).toList(),
      'sunset':
          days.map((entry) => asMap(entry.source['astro'])['sunset']).toList(),
    };
    return WeatherBundle(current: current, hourly: hourly, daily: daily);
  }
}

/// Converts WeatherAPI.com condition codes to the WMO-like codes used by the
/// existing scene and display rules.
int weatherApiConditionCode(int code) => switch (code) {
      1000 => 0,
      1003 => 2,
      1006 || 1009 => 3,
      1015 || 1018 || 1021 || 1024 || 1027 || 1045 || 1048 => 30,
      1030 || 1033 || 1036 || 1039 || 1042 || 1135 => 45,
      1147 => 48,
      1150 || 1153 => 51,
      1168 => 56,
      1171 => 57,
      1063 || 1180 || 1183 => 61,
      1186 || 1189 => 63,
      1192 || 1195 => 65,
      1198 => 66,
      1201 || 1207 => 67,
      1069 || 1204 || 1249 || 1252 => 66,
      1066 || 1114 || 1117 || 1210 || 1213 => 71,
      1216 || 1219 || 1255 => 73,
      1222 || 1225 || 1258 => 75,
      1237 || 1261 || 1264 => 77,
      1240 => 80,
      1243 => 81,
      1246 => 82,
      1267 || 1270 => 80,
      1087 || 1273 => 95,
      1276 => 96,
      1279 || 1282 => 99,
      _ => 3,
    };

class PlaceResult {
  const PlaceResult({
    required this.city,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String region;
  final double latitude;
  final double longitude;
}

export 'widgets/city_search_page.dart';


String weatherLabel(int code) {
  if ([30, 31, 32, 33, 34, 35].contains(code)) return 'Dust storm';
  if (code == 0) return 'Clear sky';
  if (code == 1) return 'Mostly clear';
  if (code == 2) return 'Partly cloudy';
  if (code == 3) return 'Overcast';
  if (code == 45 || code == 48) return 'Foggy';
  if ([51, 53, 55, 56, 57].contains(code)) return 'Drizzle';
  if ([61, 63, 65, 66, 67].contains(code)) return 'Rain';
  if ([71, 73, 75, 77, 85, 86].contains(code)) return 'Snow';
  if ([80, 81, 82].contains(code)) return 'Rain showers';
  if ([95, 96, 99].contains(code)) return 'Thunderstorm';
  return 'Unknown conditions';
}

String weatherEmoji(int code, bool isDay) {
  if ([30, 31, 32, 33, 34, 35].contains(code)) return '🌪️';
  if (code == 0) return isDay ? '☀️' : '🌙';
  if (code == 1) return isDay ? '🌤️' : '🌙';
  if (code == 2) return '⛅';
  if (code == 3) return '☁️';
  if ([45, 48].contains(code)) return '🌫️';
  if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code)) {
    return '🌧️';
  }
  if ([71, 73, 75, 77, 85, 86].contains(code)) return '❄️';
  if ([95, 96, 99].contains(code)) return '⛈️';
  return '🌡️';
}
