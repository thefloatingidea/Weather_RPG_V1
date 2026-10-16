import 'package:flutter/material.dart';

import '../weather_api.dart';

class WeatherErrorView extends StatelessWidget {
  const WeatherErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final apiError =
        error is WeatherApiException ? error as WeatherApiException : null;
    final message = apiError?.message ?? 'Something went wrong.';
    final canRetry = apiError?.isRetryable ?? true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (canRetry) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}