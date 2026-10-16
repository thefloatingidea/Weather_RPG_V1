import 'dart:convert';

import 'package:http/http.dart' as http;

import 'weather_models.dart';

const weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');
const weatherApiForecastDays = int.fromEnvironment(
  'WEATHER_FORECAST_DAYS',
  defaultValue: 3,
);

class WeatherApiClient {
  const WeatherApiClient({required this.apiKey, http.Client? client})
      : _client = client;

  final String apiKey;
  final http.Client? _client;

  Future<WeatherBundle> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    _requireKey();
    final days = weatherApiForecastDays.clamp(1, 14);
    final uri = Uri.https('api.weatherapi.com', '/v1/forecast.json', {
      'key': apiKey,
      'q': '$latitude,$longitude',
      'days': '$days',
      'aqi': 'no',
      'alerts': 'no',
    });
    final response = await _get(uri).timeout(const Duration(seconds: 18));
    final json = _decodeResponse(response);
    return WeatherBundle.fromWeatherApiJson(json);
  }

  Future<List<PlaceResult>> search(String query) async {
    _requireKey();
    final uri = Uri.https('api.weatherapi.com', '/v1/search.json', {
      'key': apiKey,
      'q': query.trim(),
    });
    final response = await _get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      _decodeResponse(response);
    }
    final results = jsonDecode(response.body) as List<dynamic>;
    return results.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final city = item['name']?.toString() ?? query.trim();
      final region = [
        if ((item['region']?.toString() ?? '').isNotEmpty)
          item['region'].toString(),
        if ((item['country']?.toString() ?? '').isNotEmpty)
          item['country'].toString(),
      ].join(', ');
      return PlaceResult(
        city: city,
        region: region,
        latitude: (item['lat'] as num).toDouble(),
        longitude: (item['lon'] as num).toDouble(),
      );
    }).toList();
  }

  Future<http.Response> _get(Uri uri) => _client?.get(uri) ?? http.get(uri);

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) return decoded as Map<String, dynamic>;
    final body = decoded is Map<String, dynamic> ? decoded : const {};
    final error = body['error'];
    final message = error is Map ? error['message']?.toString() : null;
    throw WeatherApiException(
      message ?? 'WeatherAPI.com returned HTTP ${response.statusCode}.',
    );
  }

  void _requireKey() {
    if (apiKey.trim().isEmpty) {
      throw const WeatherApiException(
        'WeatherAPI key is missing. Run with '
        '--dart-define=WEATHER_API_KEY=your_key.',
      );
    }
  }
}

class WeatherApiException implements Exception {
  const WeatherApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
