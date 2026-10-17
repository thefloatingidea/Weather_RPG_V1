import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/character_behavior.dart';

CharacterSceneContext context({
  String weather = 'clear',
  bool night = false,
  bool morning = false,
  bool landmark = false,
  bool water = false,
  bool flowers = false,
  bool leaves = false,
  bool clouds = false,
  bool critical = false,
  bool reducedMotion = false,
}) =>
    CharacterSceneContext(
      weatherKey: weather,
      night: night,
      morning: morning,
      hasLandmark: landmark,
      hasWater: water,
      hasFlowers: flowers,
      hasLeaves: leaves,
      hasClouds: clouds,
      criticalWeather: critical,
      reducedMotion: reducedMotion,
    );

void main() {
  group('goblin finite-state behavior', () {
    test('runs coordinated idle actions for three minutes within bounds', () {
      final behavior = CharacterBehaviorController(
        temperament: const CharacterTemperament(),
        seed: 42,
      );
      final observed = <GoblinBehaviorState>{};
      for (var i = 0; i < 1800; i++) {
        behavior.update(.1, context(landmark: true, water: true, clouds: true));
        observed.add(behavior.state);
        expect(behavior.walkAmount.abs(), lessThanOrEqualTo(.055));
        expect(behavior.blinkAmount, inInclusiveRange(0, 1));
      }
      expect(observed, contains(GoblinBehaviorState.walk));
      expect(observed, contains(GoblinBehaviorState.inspect));
      expect(observed, contains(GoblinBehaviorState.lookAround));
    });

    test('reacts once to weather transitions and notices clearing skies', () {
      final behavior = CharacterBehaviorController(
        temperament: const CharacterTemperament(),
        seed: 3,
      );
      behavior.update(.1, context());
      behavior.update(.1, context(weather: 'drizzle'));
      expect(behavior.state, GoblinBehaviorState.weatherReact);
      final reactionRevision = behavior.revision;
      for (var i = 0; i < 6; i++) {
        behavior.update(.1, context(weather: 'drizzle'));
      }
      expect(behavior.revision, reactionRevision);
      behavior.update(.1, context());
      expect(behavior.state, GoblinBehaviorState.lookAround);
      expect(behavior.actionTarget, 'clearing sky');
    });

    test('supports long press and blocks interaction during critical weather',
        () {
      final behavior = CharacterBehaviorController(
        temperament: const CharacterTemperament(),
        seed: 7,
      );
      behavior.update(.1, context());
      expect(behavior.interact(longPress: true, context: context()), isTrue);
      expect(behavior.state, GoblinBehaviorState.play);
      expect(behavior.interact(context: context()), isFalse);
      for (var i = 0; i < 12; i++) {
        behavior.update(.1, context());
      }
      expect(
        behavior.interact(context: context(weather: 'storm', critical: true)),
        isFalse,
      );
    });

    test('returns to idle after a lightning surprise recovery', () {
      final behavior = CharacterBehaviorController(
        temperament: const CharacterTemperament(),
        seed: 9,
      );
      behavior.update(.1, context());
      behavior.surprise(directHit: true);
      expect(behavior.state, GoblinBehaviorState.recover);
      for (var i = 0; i < 23; i++) {
        behavior.update(.1, context());
      }
      expect(behavior.state, isNot(GoblinBehaviorState.recover));
    });

    test('night increases sleeping behavior and morning allows stretching', () {
      final behavior = CharacterBehaviorController(
        temperament: const CharacterTemperament(sleepiness: 1),
        seed: 17,
      );
      var sawSleep = false;
      for (var i = 0; i < 1200; i++) {
        behavior.update(.1, context(night: true));
        sawSleep |= behavior.state == GoblinBehaviorState.sleep;
      }
      expect(sawSleep, isTrue);

      final morning = CharacterBehaviorController(
        temperament: const CharacterTemperament(),
        seed: 11,
      );
      var sawStretch = false;
      for (var i = 0; i < 900; i++) {
        morning.update(.1, context(morning: true));
        sawStretch |= morning.actionTarget == 'stretch';
      }
      expect(sawStretch, isTrue);
    });

    test('system reduced motion skips autonomous walking and play jumps', () {
      final behavior = CharacterBehaviorController(
        temperament: const CharacterTemperament(curiosity: 1, playfulness: 1),
        seed: 29,
      );
      for (var i = 0; i < 900; i++) {
        behavior.update(.1, context(water: true, reducedMotion: true));
        expect(behavior.state, isNot(GoblinBehaviorState.walk));
        expect(behavior.state, isNot(GoblinBehaviorState.play));
      }
    });
  });

  test('journal remembers first visits, returns, weather, and survives JSON',
      () {
    final first = CharacterProfile().recordContext(
      locationId: 'agra',
      locationName: 'Agra',
      landmarkId: 'tajMahal',
      landmarkName: 'the Taj Mahal',
      weatherKey: 'rain',
      season: 'winter',
      enteredLocation: true,
      now: DateTime.utc(2026, 1, 1),
    );
    final away = first.profile.recordContext(
      locationId: 'jaipur',
      locationName: 'Jaipur',
      landmarkId: 'hawaMahal',
      landmarkName: 'Hawa Mahal',
      weatherKey: 'clear',
      season: 'spring',
      enteredLocation: true,
      now: DateTime.utc(2026, 3, 1),
    );
    final returned = away.profile.recordContext(
      locationId: 'agra',
      locationName: 'Agra',
      landmarkId: 'tajMahal',
      landmarkName: 'the Taj Mahal',
      weatherKey: 'storm',
      season: 'summer',
      enteredLocation: true,
      now: DateTime.utc(2026, 6, 1),
    );

    expect(returned.profile.visitCounts['agra'], 2);
    expect(returned.addedEvents.map((event) => event.title),
        contains('Back in Agra'));
    expect(returned.profile.weatherExperiences,
        containsAll({'rain', 'thunderstorm'}));
    final restored = CharacterProfile.fromJson(returned.profile.toJson());
    expect(restored.discoveries, returned.profile.discoveries);
    expect(restored.visitedLocations, {'agra', 'jaipur'});
    expect(restored.visitCounts, {'agra': 2, 'jaipur': 1});

    final legacyJson = Map<String, dynamic>.from(returned.profile.toJson())
      ..remove('schemaVersion')
      ..remove('temperament');
    final legacyProfile = CharacterProfile.fromJson(legacyJson);
    expect(legacyProfile.temperament.curiosity, .72);
    expect(legacyProfile.temperament.playfulness, .64);
    expect(legacyProfile.toJson()['schemaVersion'],
        CharacterProfile.currentSchemaVersion);
    expect(legacyProfile.toJson(), contains('temperament'));
  });
}
