import 'package:flutter/material.dart';

import '../weather_rules.dart';

class DiscoveryContext {
  const DiscoveryContext({
    this.tappedLandmarkId,
    this.weatherCategory,
    this.timeOfDay,
  });

  final String? tappedLandmarkId;
  final WeatherCategory? weatherCategory;
  final TimeOfDay? timeOfDay;
}

sealed class DiscoveryCondition {
  const DiscoveryCondition();
  bool isSatisfied(DiscoveryContext ctx);
}

class TapLandmarkUnderWeather extends DiscoveryCondition {
  const TapLandmarkUnderWeather(this.landmarkId, this.category);

  final String landmarkId;
  final WeatherCategory category;

  @override
  bool isSatisfied(DiscoveryContext ctx) =>
      ctx.tappedLandmarkId == landmarkId && ctx.weatherCategory == category;
}

class VisitAtTimeOfDay extends DiscoveryCondition {
  const VisitAtTimeOfDay(this.timeOfDay);

  final TimeOfDay timeOfDay;

  @override
  bool isSatisfied(DiscoveryContext ctx) => ctx.timeOfDay == timeOfDay;
}

class AlwaysUnlocked extends DiscoveryCondition {
  const AlwaysUnlocked();

  @override
  bool isSatisfied(DiscoveryContext ctx) => true;
}