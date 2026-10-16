import 'package:flutter_test/flutter_test.dart';
import 'package:weather_rpg/character_behavior.dart';
import 'package:weather_rpg/world_catalog.dart';

/// One recorded context, mirroring what the app passes to `recordContext`.
typedef Visit = ({
  String locationId,
  String locationName,
  String landmarkId,
  String weatherKey,
  String season,
  bool entered,
});

/// Shorthand for a visit that enters the location.
Visit visit(
  String locationId,
  String locationName,
  String landmarkId, {
  String weatherKey = 'clear',
  String season = 'summer',
  bool entered = true,
}) =>
    (
      locationId: locationId,
      locationName: locationName,
      landmarkId: landmarkId,
      weatherKey: weatherKey,
      season: season,
      entered: entered,
    );

/// Builds a profile by recording real contexts, so the tests exercise the same
/// path the app uses rather than hand-assembling the sets.
CharacterProfile profileAfter(List<Visit> visits) {
  var profile = const CharacterProfile();
  for (final entry in visits) {
    profile = profile.recordContext(
      locationId: entry.locationId,
      locationName: entry.locationName,
      landmarkId: entry.landmarkId,
      landmarkName: entry.landmarkId == 'none'
          ? entry.locationName
          : landmarkDisplayName(entry.landmarkId),
      weatherKey: entry.weatherKey,
      season: entry.season,
      enteredLocation: entry.entered,
    ).profile;
  }
  return profile;
}

void main() {
  group('character progress', () {
    test('an untouched profile reports nothing collected', () {
      final progress = const CharacterProfile().progress;

      expect(progress.hasAnyProgress, isFalse);
      expect(progress.landmarkIds, isEmpty);
      expect(progress.weatherKeys, isEmpty);
      expect(progress.locationsVisited, 0);
      expect(progress.totalVisits, 0);
      expect(progress.favouriteLocationId, isNull);
    });

    test('landmarks are extracted from the discovery ids', () {
      final profile = profileAfter([
        visit('agra', 'Agra', 'tajMahal'),
        visit('paris', 'Paris', 'eiffelTower'),
      ]);
      final progress = profile.progress;

      expect(progress.landmarkIds, containsAll(['tajMahal', 'eiffelTower']));
      expect(progress.landmarkIds, hasLength(2));
      expect(progress.locationsVisited, 2);
    });

    test('a location with no landmark contributes no landmark', () {
      final profile = profileAfter(
          [visit('regional-frontier', 'Regional frontier', 'none')]);

      expect(profile.progress.landmarkIds, isEmpty);
      expect(profile.progress.locationsVisited, 1);
    });

    test('weather memories are recognised and seasons stay separate', () {
      final profile = profileAfter([
        visit('mumbai', 'Mumbai', 'gatewayOfIndia',
            weatherKey: 'storm', season: 'summer'),
        visit('srinagar', 'Srinagar', 'srinagarLake',
            weatherKey: 'snow', season: 'winter'),
      ]);
      final progress = profile.progress;

      expect(
          progress.weatherKeys,
          containsAll(
              ['thunderstorm', 'snow', 'season:summer', 'season:winter']));
      // A storm records the thunderstorm memory, not the plain rain one.
      expect(progress.weatherKeys, isNot(contains('rain')));
    });

    test('plain rain records the rain memory', () {
      final profile = profileAfter([
        visit('kolkata', 'Kolkata', 'howrahBridge', weatherKey: 'rain'),
      ]);

      expect(profile.progress.weatherKeys, contains('rain'));
      expect(profile.progress.weatherKeys, isNot(contains('thunderstorm')));
    });

    test('visit counts accumulate and pick a favourite', () {
      // A visit only counts on entry, so the goblin has to leave in between.
      final profile = profileAfter([
        visit('delhi', 'Delhi', 'indiaGate'),
        visit('agra', 'Agra', 'tajMahal'),
        visit('delhi', 'Delhi', 'indiaGate'),
        visit('agra', 'Agra', 'tajMahal'),
        visit('delhi', 'Delhi', 'indiaGate'),
      ]);
      final progress = profile.progress;

      expect(progress.locationsVisited, 2);
      expect(progress.totalVisits, 5);
      expect(progress.visitCounts['delhi'], 3);
      expect(progress.visitCounts['agra'], 2);
      expect(progress.favouriteLocationId, 'delhi');
    });

    test('staying put does not add a visit', () {
      final profile = profileAfter([
        visit('delhi', 'Delhi', 'indiaGate'),
        visit('delhi', 'Delhi', 'indiaGate', entered: false),
        visit('delhi', 'Delhi', 'indiaGate', entered: false),
      ]);

      expect(profile.progress.totalVisits, 1);
      expect(profile.progress.visitCounts['delhi'], 1);
    });

    test('a single visit each leaves no favourite', () {
      final profile = profileAfter([
        visit('delhi', 'Delhi', 'indiaGate'),
        visit('agra', 'Agra', 'tajMahal'),
      ]);

      expect(profile.progress.favouriteLocationId, isNull);
    });

    test('progress survives a JSON round trip', () {
      final profile = profileAfter([
        visit('agra', 'Agra', 'tajMahal',
            weatherKey: 'rain', season: 'autumn'),
      ]);
      final progress = CharacterProfile.fromJson(profile.toJson()).progress;

      expect(progress.landmarkIds, contains('tajMahal'));
      expect(progress.weatherKeys, containsAll(['rain', 'season:autumn']));
      expect(progress.locationsVisited, 1);
      expect(progress.totalVisits, 1);
    });
  });

  group('collection catalogue', () {
    test('every catalogued landmark maps to a real WorldLandmark', () {
      for (final entry in landmarkCatalog) {
        expect(entry.landmark, isNot(WorldLandmark.none));
        expect(entry.name, isNotEmpty);
        expect(entry.emoji, isNotEmpty);
      }
    });

    test('the catalogue covers every landmark except none', () {
      final catalogued = landmarkCatalog.map((e) => e.landmark).toSet();
      final everyLandmark = WorldLandmark.values
          .where((l) => l != WorldLandmark.none)
          .toSet();

      expect(catalogued.difference(everyLandmark), isEmpty,
          reason: 'the catalogue names a landmark that does not exist');
      expect(everyLandmark.difference(catalogued), isEmpty,
          reason: 'a landmark exists with no catalogue entry, so it could '
              'never be shown as collected');
    });

    test('no landmark is listed twice', () {
      final ids = landmarkCatalog.map((e) => e.landmark).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every city landmark is in the catalogue', () {
      // A city whose landmark is missing from the catalogue could never show
      // as collected in the journal.
      final catalogued = landmarkCatalog.map((e) => e.landmark).toSet();
      for (final location in worldLocations) {
        if (location.landmark == WorldLandmark.none) continue;
        expect(catalogued, contains(location.landmark),
            reason: '${location.id} has landmark ${location.landmark.name} '
                'which is not in the catalogue');
      }
    });

    test('weather badges do not repeat a key', () {
      final keys = weatherBadgeCatalog.map((b) => b.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
    });

    test('landmark display names resolve', () {
      expect(landmarkDisplayName('tajMahal'), 'Taj Mahal');
      expect(landmarkDisplayName('newYorkSkyline'), 'New York Skyline');
      // An unknown id still produces something readable.
      expect(landmarkDisplayName('someUnknownPlace'), 'Some Unknown Place');
    });
  });
}
