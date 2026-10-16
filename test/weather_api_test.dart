import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_rpg/weather_api.dart';

void main() {
  test('rejects empty query without touching the network', () async {
    final api = WeatherApiClient(
      client: MockClient((_) => throw StateError('network should not be hit')),
      baseUrl: 'https://example.test',
    );

    await expectLater(
      api.fetchForecast(latitude: 0, longitude: 0),
      throwsA(isA<WeatherApiException>()
          .having((e) => e.isRetryable, 'isRetryable', false)),
    );
  });

  test('400 maps to a non-retryable error', () async {
    final api = WeatherApiClient(
      client: MockClient((_) async => http.Response('{}', 400)),
      baseUrl: 'https://example.test',
    );

    await expectLater(
      api.fetchForecast(latitude: 0, longitude: 0),
      throwsA(isA<WeatherApiException>()
          .having((e) => e.isRetryable, 'isRetryable', false)),
    );
  });

  test('429 maps to a retryable error', () async {
    final api = WeatherApiClient(
      client: MockClient((_) async => http.Response('{}', 429)),
      baseUrl: 'https://example.test',
    );

    await expectLater(
      api.fetchForecast(latitude: 0, longitude: 0),
      throwsA(isA<WeatherApiException>()
          .having((e) => e.isRetryable, 'isRetryable', true)),
    );
  });

  test('SocketException maps to a retryable offline error', () async {
    final api = WeatherApiClient(
      client: MockClient((_) async => throw const SocketException('offline')),
      baseUrl: 'https://example.test',
    );

    await expectLater(
      api.fetchForecast(latitude: 0, longitude: 0),
      throwsA(isA<WeatherApiException>()
          .having((e) => e.isRetryable, 'isRetryable', true)),
    );
  });
}