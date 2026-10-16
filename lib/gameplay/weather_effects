import '../weather_rules.dart';

class WeatherEffect {
  const WeatherEffect({
    required this.movementMultiplier,
    required this.energyDrainPerMinute,
    required this.journalEntryId,
  });

  final double movementMultiplier;
  final double energyDrainPerMinute;
  final String? journalEntryId;
}

WeatherEffect effectFor(SceneEnvironment env) => switch (env) {
      SceneEnvironment.cyclone => const WeatherEffect(
          movementMultiplier: 0.6,
          energyDrainPerMinute: 2.5,
          journalEntryId: 'cyclone_shelter',
        ),
      SceneEnvironment.flood => const WeatherEffect(
          movementMultiplier: 0.45,
          energyDrainPerMinute: 3.0,
          journalEntryId: 'flood_high_ground',
        ),
      SceneEnvironment.sandstorm => const WeatherEffect(
          movementMultiplier: 0.55,
          energyDrainPerMinute: 2.0,
          journalEntryId: 'sandstorm_cover',
        ),
      SceneEnvironment.desertHeat => const WeatherEffect(
          movementMultiplier: 0.75,
          energyDrainPerMinute: 1.5,
          journalEntryId: 'desert_shade',
        ),
      _ => const WeatherEffect(
          movementMultiplier: 1.0,
          energyDrainPerMinute: 0.0,
          journalEntryId: null,
        ),
    };