import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'weather_models.dart';

/// A weather lookup failure with a message safe to show the user.
class WeatherApiException implements Exception {
  WeatherApiException(this.message, {this.isRetryable = true, this.cause});

  final String message;
  final bool isRetryable;
  final Object? cause;

  @override
  String toString() => message;
}

/// HTTP client for the Weather RPG proxy.
///
/// The proxy is a Cloudflare Worker (see `proxy/worker.js`) that holds the
/// WeatherAPI.com key as a secret and enforces query validation. The Flutter
/// client never sees the raw key.
class WeatherApiClient {
  const WeatherApiClient({http.Client? client, String? baseUrl})
      : _client = client,
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = String.fromEnvironment(
    'WEATHER_PROXY_URL',
    defaultValue: 'https://weather-rpg-proxy.floatingidea.workers.dev',
  );

  static const _timeout = Duration(seconds: 18);
  static const _minQueryLength = 2;
  static const _maxQueryLength = 64;

  static final _validQuery =
      RegExp(r"^[\p{L}\p{N}\s,.\-'()]+$", unicode: true);

  final http.Client? _client;
  final String _baseUrl;

  String _normalizeQuery(String raw) {
    final query = raw.trim();

    if (query.isEmpty) {
      throw WeatherApiException('Enter a city name.', isRetryable: false);
    }
    if (query.length < _minQueryLength) {
      throw WeatherApiException(
        'City names need at least $_minQueryLength characters.',
        isRetryable: false,
      );
    }
    if (query.length > _maxQueryLength) {
      throw WeatherApiException(
        'That city name is too long.',
        isRetryable: false,
      );
    }
    if (!_validQuery.hasMatch(query)) {
      throw WeatherApiException(
        'City names can only contain letters, numbers, and basic punctuation.',
        isRetryable: false,
      );
    }
    return query;
  }

  Future<WeatherBundle> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final query = '$latitude,$longitude';
    const days = 7;

    final uri = Uri.parse('$_baseUrl/forecast')
        .replace(queryParameters: {'q': query, 'days': '$days'});

    http.Response response;
    try {
      response = await _get(uri).timeout(_timeout);
    } on TimeoutException catch (e) {
      throw WeatherApiException(
        'The weather service took too long to respond.',
        cause: e,
      );
    } on SocketException catch (e) {
      throw WeatherApiException(
        'No internet connection. Check your network and try again.',
        cause: e,
      );
    } on http.ClientException catch (e) {
      throw WeatherApiException(
        'Could not reach the weather service.',
        cause: e,
      );
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 400:
        throw WeatherApiException(
          'We could not find that location. Try a different city.',
          isRetryable: false,
        );
      case 401:
      case 403:
        throw WeatherApiException(
          'The weather service rejected the request.',
          isRetryable: false,
        );
      case 429:
        throw WeatherApiException(
          'Too many requests right now. Try again in a minute.',
        );
      default:
        if (response.statusCode >= 500) {
          throw WeatherApiException(
            'The weather service is having trouble. Try again shortly.',
          );
        }
        throw WeatherApiException(
          'Unexpected response (${response.statusCode}).',
        );
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw WeatherApiException(
        'The weather service returned an unreadable response.',
        cause: e,
      );
    }

    try {
      return WeatherBundle.fromWeatherApiJson(json);
    } catch (e, st) {
      if (kDebugMode) debugPrint('WeatherBundle parse failure: $e\n$st');
      throw WeatherApiException(
        'The weather service returned unexpected data.',
        isRetryable: false,
        cause: e,
      );
    }
  }

  /// Searches for cities matching [query].
  ///
  /// Returns an empty list when nothing matches. Throws [WeatherApiException]
  /// on network failure or a non-200 response.
  Future<List<PlaceResult>> search(String query) async {
    final normalized = _normalizeQuery(query);

    final uri = Uri.parse('$_baseUrl/search')
        .replace(queryParameters: {'q': normalized});

    http.Response response;
    try {
      response = await _get(uri).timeout(_timeout);
    } on TimeoutException catch (e) {
      throw WeatherApiException(
        'Search took too long. Try again.',
        cause: e,
      );
    } on SocketException catch (e) {
      throw WeatherApiException(
        'No internet connection.',
        cause: e,
      );
    } on http.ClientException catch (e) {
      throw WeatherApiException(
        'Could not reach the search service.',
        cause: e,
      );
    }

    if (response.statusCode != 200) {
      throw WeatherApiException(
        'Search failed (${response.statusCode}).',
        isRetryable: response.statusCode >= 500,
      );
    }

    final List<dynamic> raw;
    try {
      raw = jsonDecode(response.body) as List<dynamic>;
    } on FormatException catch (e) {
      throw WeatherApiException('Search returned unreadable data.', cause: e);
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map((entry) => PlaceResult(
              city: entry['name'] as String? ?? '',
              region: entry['region'] as String? ?? '',
              latitude: (entry['lat'] as num?)?.toDouble() ?? 0,
              longitude: (entry['lon'] as num?)?.toDouble() ?? 0,
            ))
        .where((p) => p.city.isNotEmpty)
        .toList();
  }

  Future<http.Response> _get(Uri uri) =>
      _client?.get(uri) ?? http.get(uri);
}