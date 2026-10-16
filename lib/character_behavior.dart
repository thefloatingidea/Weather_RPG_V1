import 'dart:math' as math;
import 'goblin_scenarios.dart';

enum GoblinBehaviorState {
  idle,
  lookAround,
  walk,
  yawn,
  inspect,
  play,
  weatherReact,
  landmarkReact,
  interact,
  rest,
  sleep,
  recover,
}

enum GoblinMood {
  calm,
  curious,
  playful,
  cautious,
  sleepy,
  surprised,
  worried,
  warm,
  cold,
  happy,
}

class CharacterTemperament {
  const CharacterTemperament({
    this.curiosity = .72,
    this.playfulness = .64,
    this.caution = .43,
    this.sleepiness = .48,
  });

  final double curiosity;
  final double playfulness;
  final double caution;
  final double sleepiness;

  Map<String, dynamic> toJson() => {
        'curiosity': curiosity,
        'playfulness': playfulness,
        'caution': caution,
        'sleepiness': sleepiness,
      };

  factory CharacterTemperament.fromJson(Map<String, dynamic>? json) {
    double read(String key, double fallback) =>
        ((json?[key] as num?)?.toDouble() ?? fallback).clamp(0.0, 1.0);

    return CharacterTemperament(
      curiosity: read('curiosity', .72),
      playfulness: read('playfulness', .64),
      caution: read('caution', .43),
      sleepiness: read('sleepiness', .48),
    );
  }

  CharacterTemperament copyWith({
    double? curiosity,
    double? playfulness,
    double? caution,
    double? sleepiness,
  }) =>
      CharacterTemperament(
        curiosity: curiosity ?? this.curiosity,
        playfulness: playfulness ?? this.playfulness,
        caution: caution ?? this.caution,
        sleepiness: sleepiness ?? this.sleepiness,
      );
}

class CharacterJournalEvent {
  const CharacterJournalEvent({
    required this.id,
    required this.title,
    required this.detail,
    required this.at,
  });

  final String id;
  final String title;
  final String detail;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'at': at.toIso8601String(),
      };

  factory CharacterJournalEvent.fromJson(Map<dynamic, dynamic> json) =>
      CharacterJournalEvent(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'A day in the weather',
        detail: json['detail'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

class CharacterProfile {
  static const currentSchemaVersion = 2;

  const CharacterProfile({
    this.temperament = const CharacterTemperament(),
    this.visitedLocations = const {},
    this.visitCounts = const {},
    this.discoveries = const {},
    this.weatherExperiences = const {},
    this.recentEvents = const [],
    this.currentLocationId,
    this.schemaVersion = currentSchemaVersion,
  });

  final CharacterTemperament temperament;
  final Set<String> visitedLocations;
  final Map<String, int> visitCounts;
  final Set<String> discoveries;
  final Set<String> weatherExperiences;
  final List<CharacterJournalEvent> recentEvents;
  final String? currentLocationId;
  final int schemaVersion;

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'temperament': temperament.toJson(),
        'visitedLocations': visitedLocations.toList(),
        'visitCounts': visitCounts,
        'discoveries': discoveries.toList(),
        'weatherExperiences': weatherExperiences.toList(),
        'recentEvents': recentEvents.map((event) => event.toJson()).toList(),
        'currentLocationId': currentLocationId,
      };

  factory CharacterProfile.fromJson(Map<dynamic, dynamic> json) {
    Set<String> readSet(String key) =>
        (json[key] as List? ?? const []).whereType<String>().toSet();

    final events = (json['recentEvents'] as List? ?? const [])
        .whereType<Map>()
        .map((event) => CharacterJournalEvent.fromJson(event))
        .toList();

    final rawVisitCounts = json['visitCounts'] as Map? ?? {};

    // Schema v1 never saved a temperament. v2+ round-trips it.
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    final temperament = version >= 2
        ? CharacterTemperament.fromJson(
            json['temperament'] as Map<String, dynamic>?,
          )
        : const CharacterTemperament();

    return CharacterProfile(
      temperament: temperament,
      visitedLocations: readSet('visitedLocations'),
      visitCounts: rawVisitCounts.map(
        (key, value) => MapEntry(key as String, (value as num).toInt()),
      ),
      discoveries: readSet('discoveries'),
      weatherExperiences: readSet('weatherExperiences'),
      recentEvents: events.take(60).toList(),
      currentLocationId: json['currentLocationId'] as String?,
    );
  }

  ProfileUpdate recordContext({
    required String locationId,
    required String locationName,
    required String landmarkId,
    required String landmarkName,
    required String weatherKey,
    required String season,
    required bool enteredLocation,
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    final visits = {...visitedLocations};
    final counts = {...visitCounts};
    final unlocked = {...discoveries};
    final experiences = {...weatherExperiences};
    final events = [...recentEvents];
    final added = <CharacterJournalEvent>[];

    void add(String id, String title, String detail) {
      if (unlocked.add(id)) {
        final event = CharacterJournalEvent(
          id: id,
          title: title,
          detail: detail,
          at: date,
        );
        events.insert(0, event);
        added.add(event);
      }
    }

    if (enteredLocation && currentLocationId != locationId) {
      final returning = visits.contains(locationId);
      final visitNumber = (counts[locationId] ?? 0) + 1;
      counts[locationId] = visitNumber;

      add(
        'visit:$locationId:$visitNumber',
        returning ? 'Back in $locationName' : 'Visited $locationName',
        returning
            ? 'The goblin recognized this weather world.'
            : 'A new place joined the goblin’s map.',
      );
      visits.add(locationId);

      if (landmarkId != 'none') {
        add(
          'landmark:$locationId:$landmarkId',
          'Spotted $landmarkName',
          'The goblin took a moment to study the landmark.',
        );
      }
    }

    if (const {'drizzle', 'rain', 'storm'}.contains(weatherKey)) {
      final key = weatherKey == 'storm' ? 'thunderstorm' : 'rain';
      if (experiences.add(key)) {
        add(
          'weather:$key',
          key == 'thunderstorm' ? 'First thunderstorm' : 'First rain',
          key == 'thunderstorm'
              ? 'A rumble became part of the goblin’s weather memories.'
              : 'The goblin met the rain and kept exploring.',
        );
      }
    } else if (weatherKey == 'snow' && experiences.add('snow')) {
      add(
        'weather:snow',
        'First snowfall',
        'The goblin remembers the first flakes of snow.',
      );
    }

    if (experiences.add('season:$season')) {
      add(
        'season:$season',
        'Season discovered: $season',
        'A new seasonal world appeared on the goblin’s travels.',
      );
    }

    return ProfileUpdate(
      CharacterProfile(
        temperament: temperament,
        visitedLocations: visits,
        visitCounts: counts,
        discoveries: unlocked,
        weatherExperiences: experiences,
        recentEvents: events.take(60).toList(),
        currentLocationId: locationId,
      ),
      added,
    );
  }
}

class ProfileUpdate {
  const ProfileUpdate(this.profile, this.addedEvents);

  final CharacterProfile profile;
  final List<CharacterJournalEvent> addedEvents;
}

/// What the profile has collected, so the journal can show progress rather than
/// only a running list of events.
class CharacterProgress {
  const CharacterProgress({
    required this.landmarkIds,
    required this.weatherKeys,
    required this.locationsVisited,
    required this.totalVisits,
    required this.visitCounts,
    required this.discoveryCount,
  });

  final Set<String> landmarkIds;
  final Set<String> weatherKeys;
  final int locationsVisited;
  final int totalVisits;
  final Map<String, int> visitCounts;
  final int discoveryCount;

  bool get hasAnyProgress =>
      landmarkIds.isNotEmpty || weatherKeys.isNotEmpty || locationsVisited > 0;

  String? get favouriteLocationId {
    if (visitCounts.isEmpty) return null;
    final best = visitCounts.entries
        .reduce((a, b) => b.value > a.value ? b : a);
    return best.value > 1 ? best.key : null;
  }

  static const empty = CharacterProgress(
    landmarkIds: {},
    weatherKeys: {},
    locationsVisited: 0,
    totalVisits: 0,
    visitCounts: {},
    discoveryCount: 0,
  );
}

extension CharacterProgressReader on CharacterProfile {
  CharacterProgress get progress {
    final landmarks = <String>{};
    for (final discovery in discoveries) {
      if (!discovery.startsWith('landmark:')) continue;
      final parts = discovery.split(':');
      if (parts.length >= 3 && parts[2].isNotEmpty) {
        landmarks.add(parts[2]);
      }
    }

    final weather = <String>{};
    for (final experience in weatherExperiences) {
      if (experience.startsWith('season:') ||
          experience == 'rain' ||
          experience == 'thunderstorm' ||
          experience == 'snow') {
        weather.add(experience);
      }
    }

    return CharacterProgress(
      landmarkIds: landmarks,
      weatherKeys: weather,
      locationsVisited: visitedLocations.length,
      totalVisits: visitCounts.values.fold(0, (sum, value) => sum + value),
      visitCounts: visitCounts,
      discoveryCount: discoveries.length,
    );
  }
}

class CharacterSceneContext {
  const CharacterSceneContext({
    required this.weatherKey,
    required this.night,
    required this.morning,
    required this.hasLandmark,
    required this.hasWater,
    required this.hasFlowers,
    required this.hasLeaves,
    required this.hasClouds,
    required this.criticalWeather,
    this.reducedMotion = false,
  });

  final String weatherKey;
  final bool night;
  final bool morning;
  final bool hasLandmark;
  final bool hasWater;
  final bool hasFlowers;
  final bool hasLeaves;
  final bool hasClouds;
  final bool criticalWeather;
  final bool reducedMotion;
}

/// One finite-state controller owns all deliberate character actions.
/// Timed poses cannot overlap; only a real weather change or a player gesture
/// may preempt an ordinary action.
class CharacterBehaviorController {
  CharacterBehaviorController({
    required this.temperament,
    String previousWeatherKey = '',
    int seed = 7319,
  })  : _random = math.Random(seed),
        _lastWeatherKey = previousWeatherKey;

  CharacterTemperament temperament;
  final math.Random _random;

  GoblinBehaviorState state = GoblinBehaviorState.idle;
  GoblinBehaviorState? previousState;
  String? previousTarget;
  GoblinMood mood = GoblinMood.calm;
  double stateAge = 0;
  double stateDuration = 0;
  double blinkAmount = 0;
  double headTurn = 0;
  double gazeX = 0;
  double gazeY = 0;
  double walkAmount = 0;
  int walkDirection = 1;
  int revision = 0;
  int taps = 0;
  String? actionTarget;

  String _lastWeatherKey = '';
  String? _lastScenarioTitle;
  double _idleWait = 1.4;
  double _interactionCooldown = 0;
  double _weatherReactionCooldown = 0;
  double _blinkWait = 2.2;
  double _blinkAge = 1;
  int _sleepTaps = 0;

  bool get isWalking => state == GoblinBehaviorState.walk;
  bool get isSleeping => state == GoblinBehaviorState.sleep;

  double get actionProgress => stateDuration <= 0
      ? 1
      : (stateAge / stateDuration).clamp(0.0, 1.0).toDouble();

  void update(double dt, CharacterSceneContext context) {
    final step = dt.clamp(0.0, .1).toDouble();

    _interactionCooldown = math.max(0, _interactionCooldown - step);
    _weatherReactionCooldown = math.max(0, _weatherReactionCooldown - step);

    _blinkAge += step;
    if (_blinkAge >= _blinkWait) {
      blinkAmount = _blinkAge - _blinkWait < .13 ? 1 : 0;
      if (_blinkAge > _blinkWait + .16) {
        _blinkAge = 0;
        _blinkWait = 2.1 + _random.nextDouble() * 3.3;
      }
    } else {
      blinkAmount = 0;
    }

    if (_lastWeatherKey.isEmpty) {
      _lastWeatherKey = context.weatherKey;
      if (_isReactionWeather(context.weatherKey)) {
        _startWeatherReaction(context.weatherKey, emergency: true);
      }
    } else if (_lastWeatherKey != context.weatherKey) {
      final old = _lastWeatherKey;
      _lastWeatherKey = context.weatherKey;
      if (_isReactionWeather(context.weatherKey)) {
        _startWeatherReaction(
          context.weatherKey,
          emergency: context.criticalWeather,
        );
      } else if (_isReactionWeather(old)) {
        _enter(
          GoblinBehaviorState.lookAround,
          1.8,
          mood: GoblinMood.calm,
          target: 'clearing sky',
        );
        headTurn = -.18;
        gazeY = -.3;
      }
    }

    stateAge += step;

    if (state == GoblinBehaviorState.walk) {
      walkAmount = walkDirection * .055 * math.sin(math.pi * actionProgress);
    } else {
      walkAmount = 0;
    }

    if (state != GoblinBehaviorState.idle && stateAge >= stateDuration) {
      if (state == GoblinBehaviorState.recover) {
        _enter(GoblinBehaviorState.idle, 0, mood: GoblinMood.calm);
        _idleWait = 1.1 + _random.nextDouble() * 1.8;
      } else {
        _enter(GoblinBehaviorState.recover, .55, mood: GoblinMood.calm);
      }
    }

    if (state == GoblinBehaviorState.idle) {
      _idleWait -= step;
      if (_idleWait <= 0) _chooseIdle(context);
    }
  }

  bool interact({
    bool longPress = false,
    required CharacterSceneContext context,
  }) {
    if (context.criticalWeather ||
        state == GoblinBehaviorState.weatherReact ||
        state == GoblinBehaviorState.recover ||
        _interactionCooldown > 0) {
      return false;
    }

    _interactionCooldown = 1.0;
    taps++;

    if (isSleeping) {
      _sleepTaps++;
      if (_sleepTaps < 2) {
        mood = GoblinMood.sleepy;
        revision++;
        return true;
      }
      _sleepTaps = 0;
    }

    final play = longPress || (taps % 4 == 0 && temperament.playfulness > .52);

    _enter(
      play ? GoblinBehaviorState.play : GoblinBehaviorState.interact,
      play ? 2.2 : 1.8,
      mood: play ? GoblinMood.playful : GoblinMood.happy,
      target: 'player',
    );
    headTurn = 0;
    gazeX = 0;
    gazeY = 0;
    return true;
  }

  void surprise({bool directHit = false}) {
    if (_weatherReactionCooldown > 0 && !directHit) return;
    _weatherReactionCooldown = directHit ? 7 : 5;
    _enter(
      directHit ? GoblinBehaviorState.recover : GoblinBehaviorState.weatherReact,
      directHit ? 1.5 + temperament.caution * .7 : 1.2,
      mood: GoblinMood.surprised,
      target: 'thunder',
    );
  }

    /// Aligns the controller with a scenario picked by `pickScenario`.
  ///
  /// Safe to call from `update` on every frame: repeated calls with the same
  /// scenario are ignored, so a rebuild cannot restart the same pose
  /// mid-animation. Player interactions and live weather reactions outrank a
  /// scenario cue, so a scenario never interrupts a tap or a lightning flinch.
  void reactToScenario(GoblinScenario scenario) {
    if (scenario.title == _lastScenarioTitle) return;

    // A live emergency or a player gesture owns the character right now.
    // Let it finish rather than snapping to a new pose underneath it.
    if (_weatherReactionCooldown > 1.5) return;
    if (_interactionCooldown > 0) return;

    _lastScenarioTitle = scenario.title;

    _enter(
      scenario.state,
      _scenarioDuration(scenario.state),
      mood: scenario.mood,
      target: scenario.title,
    );

    // Some states read better with an initial head or eye offset — without
    // one, "lookAround" stares straight ahead, which is the pose the scenario
    // text is trying to distinguish itself from.
    switch (scenario.state) {
      case GoblinBehaviorState.lookAround:
        headTurn = _random.nextBool() ? .18 : -.18;
        gazeX = headTurn.sign * .6;
        gazeY = scenario.mood == GoblinMood.curious ? -.35 : .05;
      case GoblinBehaviorState.inspect:
      case GoblinBehaviorState.landmarkReact:
        headTurn = .16;
        gazeX = .7;
        gazeY = .15;
      case GoblinBehaviorState.rest:
        gazeY = .18;
        headTurn = 0;
      case GoblinBehaviorState.sleep:
        gazeY = .5;
        headTurn = 0;
      case GoblinBehaviorState.weatherReact:
        gazeY = -.25;
      case GoblinBehaviorState.walk:
        walkDirection = _random.nextBool() ? 1 : -1;
      default:
        break;
    }
  }

  /// Natural duration for each scenario state, in seconds.
  ///
  /// Deliberately a touch longer than the idle-choice durations in
  /// `_chooseIdle`, so a scenario pose reads as intentional rather than as
  /// one of the wandering idle animations.
  double _scenarioDuration(GoblinBehaviorState s) => switch (s) {
        GoblinBehaviorState.idle => 2.0,
        GoblinBehaviorState.lookAround => 2.4,
        GoblinBehaviorState.walk => 2.8,
        GoblinBehaviorState.yawn => 1.7,
        GoblinBehaviorState.inspect => 2.3,
        GoblinBehaviorState.play => 2.1,
        GoblinBehaviorState.weatherReact => 1.9,
        GoblinBehaviorState.landmarkReact => 2.5,
        GoblinBehaviorState.interact => 1.8,
        GoblinBehaviorState.rest => 2.7,
        GoblinBehaviorState.sleep => 4.5,
        GoblinBehaviorState.recover => .6,
      };

  void _startWeatherReaction(String key, {required bool emergency}) {
    _weatherReactionCooldown = emergency ? 8 : 5;
    final mood = switch (key) {
      'storm' || 'heavy rain' => GoblinMood.worried,
      'snow' || 'cold' => GoblinMood.cold,
      'heat' => GoblinMood.warm,
      'wind' || 'sand' || 'fog' => GoblinMood.cautious,
      _ => GoblinMood.curious,
    };

    _enter(
      GoblinBehaviorState.weatherReact,
      (emergency ? 2.1 : 1.6) + temperament.caution * .7,
      mood: mood,
      target: key,
    );
    headTurn = key == 'wind' || key == 'sand' ? .2 : -.1;
    gazeY = key == 'snow' ? -.35 : 0;
  }

  bool _isReactionWeather(String key) => key != 'clear';

  void _chooseIdle(CharacterSceneContext context) {
    final choices = <(GoblinBehaviorState, double, double, GoblinMood, String?)>[
      (GoblinBehaviorState.lookAround, 1.5, 2.4, GoblinMood.curious, null),
      (GoblinBehaviorState.walk, 1.8, 3.0, GoblinMood.curious, null),
      (
        GoblinBehaviorState.inspect,
        1.5,
        2.5,
        GoblinMood.curious,
        _visibleTarget(context)
      ),
      (
        GoblinBehaviorState.play,
        1.3,
        2.1,
        GoblinMood.playful,
        _playTarget(context)
      ),
      (GoblinBehaviorState.rest, 1.7, 3.0, GoblinMood.calm, null),
      (GoblinBehaviorState.sleep, 3.0, 6.0, GoblinMood.sleepy, null),
      (
        GoblinBehaviorState.landmarkReact,
        1.6,
        2.7,
        GoblinMood.curious,
        'landmark'
      ),
      (GoblinBehaviorState.yawn, 1.2, 1.8, GoblinMood.sleepy, 'yawn'),
    ];

    final weighted = <(GoblinBehaviorState, double, double, GoblinMood, String?)>[];

    void repeatChoice(
      int count,
      (GoblinBehaviorState, double, double, GoblinMood, String?) choice,
    ) {
      for (var i = 0; i < count; i++) {
        weighted.add(choice);
      }
    }

    repeatChoice(
      2 + (temperament.curiosity * 4).round() + (temperament.caution * 3).round(),
      choices[0],
    );

    if (!context.reducedMotion) {
      repeatChoice(1 + (temperament.curiosity * 5).round(), choices[1]);
    }

    final target = _visibleTarget(context);
    if (target != null) {
      repeatChoice(
        1 + (temperament.curiosity * 5).round(),
        (GoblinBehaviorState.inspect, 1.5, 2.5, GoblinMood.curious, target),
      );
    }

    final playTarget = _playTarget(context);
    if (playTarget != null && !context.reducedMotion) {
      repeatChoice(
        1 + (temperament.playfulness * 6).round(),
        (GoblinBehaviorState.play, 1.3, 2.1, GoblinMood.playful, playTarget),
      );
    }

    if (context.morning) {
      repeatChoice(
        2,
        (GoblinBehaviorState.rest, 1.7, 3.0, GoblinMood.happy, 'stretch'),
      );
      repeatChoice(1 + (temperament.sleepiness * 2).round(), choices[7]);
    }

    if (context.night) {
      repeatChoice(1 + (temperament.sleepiness * 8).round(), choices[5]);
      repeatChoice(1 + (temperament.sleepiness * 3).round(), choices[4]);
      repeatChoice(1 + (temperament.sleepiness * 2).round(), choices[7]);
    }

    if (weighted.isEmpty) {
      _idleWait = 2;
      return;
    }

    final choice = weighted[_random.nextInt(weighted.length)];

    if (choice.$1 == GoblinBehaviorState.walk) {
      walkDirection = _random.nextBool() ? 1 : -1;
    }

    _enter(
      choice.$1,
      choice.$2 + _random.nextDouble() * (choice.$3 - choice.$2),
      mood: choice.$4,
      target: choice.$5,
    );

    if (choice.$1 == GoblinBehaviorState.lookAround) {
      final scratch = _random.nextDouble() < .16;
      if (scratch) actionTarget = 'scratch';
      headTurn = _random.nextBool() ? .18 : -.18;
      gazeX = headTurn.sign * .65;
      gazeY = context.hasClouds && _random.nextBool() ? -.5 : .05;
    } else if (choice.$1 == GoblinBehaviorState.inspect ||
        choice.$1 == GoblinBehaviorState.landmarkReact) {
      headTurn = .16;
      gazeX = .75;
      gazeY = .15;
    } else if (choice.$1 == GoblinBehaviorState.sleep) {
      gazeY = .5;
    }
  }

  String? _visibleTarget(CharacterSceneContext context) {
    if (context.hasLandmark) return 'landmark';
    if (context.hasWater) return 'puddle';
    if (context.hasFlowers) return 'flowers';
    if (context.hasLeaves) return 'falling leaf';
    if (context.hasClouds) return 'clouds';
    return null;
  }

  String? _playTarget(CharacterSceneContext context) {
    if (context.hasWater) return 'puddle';
    if (context.hasLeaves) return 'falling leaf';
    if (context.hasFlowers) return 'flowers';
    return null;
  }

  void _enter(
    GoblinBehaviorState next,
    double duration, {
    required GoblinMood mood,
    String? target,
  }) {
    previousState = state;
    previousTarget = actionTarget;
    state = next;
    stateAge = 0;
    stateDuration = duration;
    this.mood = mood;
    actionTarget = target;
    revision++;
  }
}