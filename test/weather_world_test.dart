import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/weather_rules.dart';
import 'package:weather_rpg/world_catalog.dart';

void main() {
  group('weather world location catalogue', () {
    test('matches known Indian and international landmarks', () {
      final mumbai = resolveWorldLocation(
        city: 'Mumbai',
        region: 'Maharashtra, India',
        latitude: 19.076,
        longitude: 72.8777,
      );
      final jaisalmer = resolveWorldLocation(
        city: 'Jaisalmer',
        region: 'Rajasthan, India',
        latitude: 26.9157,
        longitude: 70.9083,
      );
      final paris = resolveWorldLocation(
        city: 'Paris',
        region: 'Île-de-France, France',
        latitude: 48.8566,
        longitude: 2.3522,
      );

      expect(mumbai.landmark, WorldLandmark.gatewayOfIndia);
      expect(mumbai.biome, WorldBiome.coastal);
      expect(jaisalmer.landmark, WorldLandmark.jaisalmerFort);
      expect(jaisalmer.biome, WorldBiome.desert);
      expect(paris.landmark, WorldLandmark.eiffelTower);
    });

    test('does not attach a landmark to a same-name city elsewhere', () {
      final parisTexas = resolveWorldLocation(
        city: 'Paris',
        region: 'Texas, United States',
        latitude: 33.6609,
        longitude: -95.5555,
      );

      expect(parisTexas.landmark, WorldLandmark.none);
    });

    test('uses a biome fallback for an unlisted city', () {
      final fallback = resolveWorldLocation(
        city: 'Kochi North',
        region: 'Kerala, India',
        latitude: 10.1,
        longitude: 76.3,
      );

      expect(fallback.landmark, WorldLandmark.none);
      expect(fallback.biome, WorldBiome.coastal);
    });

    test('reverses the visual calendar across hemispheres', () {
      expect(worldSeasonForMonth(6, 40), WorldSeason.summer);
      expect(worldSeasonForMonth(6, -34), WorldSeason.winter);
      expect(worldSeasonForMonth(12, -34), WorldSeason.summer);
    });
  });

  group('weather classification', () {
    test('distinguishes drizzle, heavy rain, and thunderstorms', () {
      const drizzle = WeatherConditions(
        code: 51,
        temperatureC: 18,
        precipitationMm: .2,
        windKmh: 8,
        cloudCover: 70,
        visibilityM: 9000,
      );
      const heavyRain = WeatherConditions(
        code: 65,
        temperatureC: 18,
        precipitationMm: 8,
        windKmh: 24,
        cloudCover: 100,
        visibilityM: 2500,
      );
      const thunder = WeatherConditions(
        code: 95,
        temperatureC: 22,
        precipitationMm: 3,
        windKmh: 42,
        cloudCover: 100,
        visibilityM: 1500,
      );

      expect(drizzle.drizzle, isTrue);
      expect(drizzle.rainIntensity, lessThan(heavyRain.rainIntensity));
      expect(heavyRain.overcast, isTrue);
      expect(thunder.thunderstorm, isTrue);
    });

    test('classifies heat, dust, and visibility fog without humidity guesses',
        () {
      const hot = WeatherConditions(
        code: 0,
        temperatureC: 40,
        precipitationMm: 0,
        windKmh: 5,
        cloudCover: 0,
        visibilityM: 20000,
      );
      const dust = WeatherConditions(
        code: 30,
        temperatureC: 29,
        precipitationMm: 0,
        windKmh: 32,
        cloudCover: 45,
        visibilityM: 800,
      );
      const fog = WeatherConditions(
        code: 45,
        temperatureC: 12,
        precipitationMm: 0,
        windKmh: 3,
        cloudCover: 90,
        visibilityM: 800,
      );

      expect(hot.extremeHeat, isTrue);
      expect(dust.dusty, isTrue);
      expect(dust.foggy, isFalse);
      expect(fog.foggy, isTrue);
      expect(hot.foggy, isFalse);
    });
  });
}
