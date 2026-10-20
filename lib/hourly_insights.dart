/// Pure helpers behind the Hourly screen cards (metric chart, sun and moon,
/// air quality). Kept free of Flutter widgets so they can be unit tested.
library;

/// Metrics the hourly chart can switch between.
enum HourlyMetric {
  temp('Temp', '°', 'temperature_2m'),
  feels('Feels like', '°', 'apparent_temperature'),
  rain('Rain', '%', 'precipitation_probability'),
  wind('Wind', ' km/h', 'wind_speed_10m'),
  humidity('Humidity', '%', 'relative_humidity_2m'),
  uv('UV', '', 'uv_index');

  const HourlyMetric(this.label, this.unit, this.key);

  final String label;
  final String unit;

  /// Key inside `WeatherBundle.hourly`.
  final String key;

  /// Fixed 0..max scale for bounded metrics; null means scale to the data.
  double? get fixedMax => switch (this) {
        HourlyMetric.rain || HourlyMetric.humidity => 100,
        _ => null,
      };

  bool get isTemperature =>
      this == HourlyMetric.temp || this == HourlyMetric.feels;
}

/// Parses "06:15 AM" or an ISO-ish time into minutes after midnight.
/// Returns null when the value is missing or not a clock time
/// (for example "No moonrise").
int? parseClockMinutes(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  final amPm = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
      .firstMatch(trimmed);
  if (amPm != null) {
    var hour = int.parse(amPm.group(1)!);
    final minute = int.parse(amPm.group(2)!);
    final isPm = amPm.group(3)!.toUpperCase() == 'PM';
    if (hour == 12) hour = 0;
    return (hour + (isPm ? 12 : 0)) * 60 + minute;
  }
  final parsed = DateTime.tryParse(trimmed);
  return parsed == null ? null : parsed.hour * 60 + parsed.minute;
}

String formatMinutes(int minutes) {
  final m = ((minutes % 1440) + 1440) % 1440;
  final hour24 = m ~/ 60;
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = (m % 60).toString().padLeft(2, '0');
  return '$hour:$minute ${hour24 >= 12 ? 'PM' : 'AM'}';
}

String formatDuration(int minutes) {
  final safe = minutes < 0 ? 0 : minutes;
  return '${safe ~/ 60}h ${(safe % 60).toString().padLeft(2, '0')}m';
}

/// Where the sun is between sunrise and sunset.
class SunPosition {
  const SunPosition({
    required this.sunriseMinutes,
    required this.sunsetMinutes,
    required this.nowMinutes,
  });

  final int sunriseMinutes;
  final int sunsetMinutes;
  final int nowMinutes;

  int get dayLengthMinutes => sunsetMinutes - sunriseMinutes;
  bool get isUp =>
      nowMinutes >= sunriseMinutes && nowMinutes < sunsetMinutes;

  /// 0..1 across the arc while the sun is up, otherwise null.
  double? get progress {
    if (!isUp || dayLengthMinutes <= 0) return null;
    return (nowMinutes - sunriseMinutes) / dayLengthMinutes;
  }

  /// Short status line for the card.
  String get status {
    if (dayLengthMinutes <= 0) return '';
    if (isUp) {
      return '${formatDuration(sunsetMinutes - nowMinutes)} of daylight left';
    }
    if (nowMinutes < sunriseMinutes) {
      return 'Sunrise in ${formatDuration(sunriseMinutes - nowMinutes)}';
    }
    return 'The sun has set';
  }

  static SunPosition? tryCreate({
    required String? sunrise,
    required String? sunset,
    required String? localTime,
  }) {
    final rise = parseClockMinutes(sunrise);
    final setMin = parseClockMinutes(sunset);
    final now = DateTime.tryParse(localTime ?? '');
    if (rise == null || setMin == null || now == null) return null;
    return SunPosition(
      sunriseMinutes: rise,
      sunsetMinutes: setMin,
      nowMinutes: now.hour * 60 + now.minute,
    );
  }
}

String moonEmoji(String? phase) {
  switch ((phase ?? '').trim().toLowerCase()) {
    case 'new moon':
      return '🌑';
    case 'waxing crescent':
      return '🌒';
    case 'first quarter':
      return '🌓';
    case 'waxing gibbous':
      return '🌔';
    case 'full moon':
      return '🌕';
    case 'waning gibbous':
      return '🌖';
    case 'last quarter':
    case 'third quarter':
      return '🌗';
    case 'waning crescent':
      return '🌘';
    default:
      return '🌙';
  }
}

/// WeatherAPI returns moon_illumination as an int or a numeric string.
int? parseIllumination(Object? value) {
  if (value is num) return value.round();
  if (value is String) return num.tryParse(value.trim())?.round();
  return null;
}

/// One band of the US EPA air quality index (WeatherAPI `us-epa-index`, 1-6).
class AqiBand {
  const AqiBand(this.index, this.label, this.advice);

  final int index;
  final String label;
  final String advice;
}

const aqiBands = <AqiBand>[
  AqiBand(1, 'Good', 'Air is clean. Enjoy the outdoors.'),
  AqiBand(2, 'Moderate', 'Fine for most. Very sensitive people may notice it.'),
  AqiBand(3, 'Unhealthy for sensitive groups',
      'Children, elders and asthma sufferers should limit long outdoor effort.'),
  AqiBand(4, 'Unhealthy', 'Cut back on outdoor exercise; a mask helps.'),
  AqiBand(5, 'Very unhealthy', 'Stay indoors where you can; avoid exertion.'),
  AqiBand(6, 'Hazardous', 'Avoid going outside. Keep windows closed.'),
];

AqiBand? aqiBandFor(Object? usEpaIndex) {
  final value = usEpaIndex is num ? usEpaIndex.toInt() : null;
  if (value == null || value < 1 || value > 6) return null;
  return aqiBands[value - 1];
}

/// Extracts a JSON-safe air quality map from WeatherAPI's `air_quality`
/// block, or null when the block is absent (for example when the proxy still
/// requests `aqi=no`).
Map<String, dynamic>? parseAirQuality(Object? raw) {
  if (raw is! Map || raw.isEmpty) return null;
  double? num0(String key) => (raw[key] as num?)?.toDouble();
  final epa = (raw['us-epa-index'] as num?)?.toInt();
  if (epa == null) return null;
  return <String, dynamic>{
    'us_epa_index': epa,
    if (raw['gb-defra-index'] is num)
      'gb_defra_index': (raw['gb-defra-index'] as num).toInt(),
    if (num0('pm2_5') != null) 'pm2_5': num0('pm2_5'),
    if (num0('pm10') != null) 'pm10': num0('pm10'),
    if (num0('o3') != null) 'o3': num0('o3'),
    if (num0('no2') != null) 'no2': num0('no2'),
    if (num0('so2') != null) 'so2': num0('so2'),
    if (num0('co') != null) 'co': num0('co'),
  };
}

/// WHO UV index exposure category.
String uvCategory(double uv) {
  if (uv < 3) return 'Low';
  if (uv < 6) return 'Moderate';
  if (uv < 8) return 'High';
  if (uv < 11) return 'Very high';
  return 'Extreme';
}
