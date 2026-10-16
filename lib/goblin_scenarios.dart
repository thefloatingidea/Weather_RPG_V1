import 'dart:math' as math;

import 'character_behavior.dart';
import 'weather_rules.dart';
import 'world_catalog.dart';

/// Everything the scenario picker needs to know about the current moment.
class ScenarioContext {
  const ScenarioContext({
    required this.weatherCode,
    required this.isDay,
    required this.temperatureC,
    required this.windKmh,
    required this.precipitationMm,
    required this.biome,
    required this.landmark,
    required this.season,
    required this.visitCount,
    required this.hourOfDay,
    this.isFirstRainHere = false,
    this.isFirstSnowHere = false,
    this.isFirstStormHere = false,
  });

  final int weatherCode;
  final bool isDay;
  final double temperatureC;
  final double windKmh;
  final double precipitationMm;
  final WorldBiome biome;
  final WorldLandmark landmark;
  final WorldSeason season;
  final int visitCount;
  final int hourOfDay;
  final bool isFirstRainHere;
  final bool isFirstSnowHere;
  final bool isFirstStormHere;

  bool get raining =>
      const {51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82}
          .contains(weatherCode);
  bool get snowing => const {71, 73, 75, 77, 85, 86}.contains(weatherCode);
  bool get storming => const {95, 96, 99}.contains(weatherCode);
  bool get dusting => const {30, 31, 32, 33, 34, 35}.contains(weatherCode);
  bool get foggy => const {45, 48}.contains(weatherCode);
  bool get overcast => weatherCode == 3;
  bool get clear => weatherCode <= 2;
  bool get hot => temperatureC >= strongHeatThresholdC;
  bool get cold => temperatureC <= 5;
  bool get windy => windKmh >= strongWindThresholdKmh;
  bool get gale => windKmh >= galeWindThresholdKmh;
  bool get arid =>
      biome == WorldBiome.desert || biome == WorldBiome.coldDesert;
  bool get coastal => biome == WorldBiome.coastal;
  bool get mountain => biome == WorldBiome.mountain;
  bool get isMorning => hourOfDay >= 5 && hourOfDay < 11;
  bool get isMidday => hourOfDay >= 11 && hourOfDay < 15;
  bool get isEvening => hourOfDay >= 15 && hourOfDay < 20;
  bool get isNight => hourOfDay >= 20 || hourOfDay < 5;
  bool get firstVisit => visitCount <= 1;
  bool get returning => visitCount == 2;
  bool get local => visitCount >= 3;
}

/// A single scene the goblin plays through, with the mood and behavior it
/// should adopt while it plays.
class GoblinScenario {
  const GoblinScenario({
    required this.title,
    required this.body,
    required this.emoji,
    required this.mood,
    required this.state,
  });

  final String title;
  final String body;
  final String emoji;
  final GoblinMood mood;
  final GoblinBehaviorState state;
}

class _Entry {
  const _Entry(this.scenario, this.matches, {this.baseWeight = 1.0});
  final GoblinScenario scenario;
  final bool Function(ScenarioContext) matches;
  final double baseWeight;
}

/// Picks the most fitting scenario for the current moment, weighted by the
/// goblin's temperament so the same weather reads differently on different
/// characters.
///
/// Pass [seed] to make the choice deterministic (useful for tests and for
/// keeping the same scenario while the user is looking at one screen).
GoblinScenario pickScenario({
  required ScenarioContext ctx,
  required CharacterTemperament temperament,
  int? seed,
}) {
  final candidates = <(GoblinScenario, double)>[];
  for (final entry in _entries) {
    if (!entry.matches(ctx)) continue;
    final weight = entry.baseWeight * _temperamentAffinity(entry.scenario, temperament);
    if (weight <= 0) continue;
    candidates.add((entry.scenario, weight));
  }

  if (candidates.isEmpty) return _fallback(ctx);

  final rng = seed == null ? math.Random() : math.Random(seed);
  final total = candidates.fold<double>(0, (sum, c) => sum + c.$2);
  var roll = rng.nextDouble() * total;
  for (final c in candidates) {
    roll -= c.$2;
    if (roll <= 0) return c.$1;
  }
  return candidates.last.$1;
}

double _temperamentAffinity(GoblinScenario s, CharacterTemperament t) {
  return switch (s.mood) {
    GoblinMood.playful => 0.35 + t.playfulness * 1.65,
    GoblinMood.curious => 0.35 + t.curiosity * 1.65,
    GoblinMood.cautious || GoblinMood.worried => 0.35 + t.caution * 1.65,
    GoblinMood.sleepy => 0.35 + t.sleepiness * 1.65,
    _ => 1.0,
  };
}

GoblinScenario _fallback(ScenarioContext ctx) => GoblinScenario(
      title: ctx.isNight ? 'Night watcher' : 'Forecast scout',
      body: ctx.isNight
          ? 'Checks the sky, checks the path, decides the sky can wait.'
          : 'Checks the sky, checks the forecast, then asks the goblin beside him.',
      emoji: ctx.isNight ? '🌙' : '🧭',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.lookAround,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Scenario library
// ─────────────────────────────────────────────────────────────────────────────

const _entries = <_Entry>[
  // ── Clear and sunny ───────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Sun saluter',
      body: 'Finds the warmest rock in sight. Sits on it. Approves.',
      emoji: '☀️',
      mood: GoblinMood.happy,
      state: GoblinBehaviorState.rest,
    ),
    _clearMorning,
  ),
  _Entry(
    GoblinScenario(
      title: 'Shadow borrower',
      body: 'Auditions three tree shadows before settling on the second one.',
      emoji: '🌳',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.rest,
    ),
    _clearMiddayHot,
  ),
  _Entry(
    GoblinScenario(
      title: 'Colour watcher',
      body: 'Stops walking to watch the light turn gold across the ground.',
      emoji: '🌅',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.lookAround,
    ),
    _clearEvening,
  ),
  _Entry(
    GoblinScenario(
      title: 'Star counter',
      body: 'Loses count around forty. Starts over. Loses count again.',
      emoji: '⭐',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.lookAround,
    ),
    _clearNight,
  ),
  _Entry(
    GoblinScenario(
      title: 'Horizon checker',
      body: 'Squints at the far edge of the world and decides it can wait.',
      emoji: '🧭',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.lookAround,
    ),
    _clearAny,
  ),

  // ── Cloudy and overcast ───────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Cloud reader',
      body: 'Decides one cloud looks like a fish. Shares this with nobody.',
      emoji: '☁️',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.lookAround,
    ),
    _overcast,
  ),
  _Entry(
    GoblinScenario(
      title: 'Weather sniffer',
      body: 'Tilts his head. Something in the air has changed and he knows it.',
      emoji: '👃',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.lookAround,
    ),
    _overcastWindy,
  ),
  _Entry(
    GoblinScenario(
      title: 'Lamp lighter',
      body: 'Holds the lantern up to the grey sky, as if checking it still works.',
      emoji: '🏮',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.inspect,
    ),
    _overcastEvening,
  ),

  // ── Rain ──────────────────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Rain greeter',
      body: 'Holds out a hand to test the first rain here. Nods at the result.',
      emoji: '🌧️',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.weatherReact,
    ),
    _firstRain,
    baseWeight: 2.5,
  ),
  _Entry(
    GoblinScenario(
      title: 'Puddle inspector',
      body: 'Checks each puddle for depth. Verdict: perfect. Checks another.',
      emoji: '💧',
      mood: GoblinMood.playful,
      state: GoblinBehaviorState.play,
    ),
    _rainPlayful,
    baseWeight: 1.4,
  ),
  _Entry(
    GoblinScenario(
      title: 'Hood up',
      body: 'Hood pulled tight, eyes on the sky, watching where the water pools.',
      emoji: '🧥',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.weatherReact,
    ),
    _rainCautious,
    baseWeight: 1.4,
  ),
  _Entry(
    GoblinScenario(
      title: 'Leaf shelter',
      body: 'Stands under a leaf. Debates the leaf’s structural integrity.',
      emoji: '🍃',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.recover,
    ),
    _heavyRain,
  ),
  _Entry(
    GoblinScenario(
      title: 'Drizzle ignorer',
      body: 'Pretends not to notice the drizzle. The drizzle notices him.',
      emoji: '🌦️',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.walk,
    ),
    _drizzle,
  ),
  _Entry(
    GoblinScenario(
      title: 'Ripple watcher',
      body: 'Stares at a puddle as the rings spread. Tries to count them.',
      emoji: '💧',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.inspect,
    ),
    _rainAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Damp scout',
      body: 'Picks a path around the wettest ground. The ground disagrees.',
      emoji: '🥾',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.walk,
    ),
    _rainAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Rain listener',
      body: 'Holds still and just listens to the rain on the roof above.',
      emoji: '🌧️',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.rest,
    ),
    _rainNight,
  ),

  // ── Storm ─────────────────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Thunder counter',
      body: 'Counts the gap between flash and rumble. Gets to three. Impressed.',
      emoji: '⛈️',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.weatherReact,
    ),
    _firstStorm,
    baseWeight: 2.0,
  ),
  _Entry(
    GoblinScenario(
      title: 'Lantern holder',
      body: 'Holds the lantern a little closer. Not scared. Just careful.',
      emoji: '🏮',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.recover,
    ),
    _stormCautious,
  ),
  _Entry(
    GoblinScenario(
      title: 'Shelter scout',
      body: 'Evaluates the nearest overhang. Rejects it. Evaluates another.',
      emoji: '🪨',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.walk,
    ),
    _stormAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Lightning flinch',
      body: 'Flinches on the flash, not the rumble. Every time.',
      emoji: '⚡',
      mood: GoblinMood.surprised,
      state: GoblinBehaviorState.weatherReact,
    ),
    _stormAny,
  ),

  // ── Snow ──────────────────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Catch tester',
      body: 'Catches a flake on a mitt. Watches it melt. Catches another.',
      emoji: '❄️',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.weatherReact,
    ),
    _firstSnow,
    baseWeight: 2.5,
  ),
  _Entry(
    GoblinScenario(
      title: 'Snowball novice',
      body: 'Packs one. It falls apart. Packs another. This one is worse.',
      emoji: '⛄',
      mood: GoblinMood.playful,
      state: GoblinBehaviorState.play,
    ),
    _snowPlayful,
  ),
  _Entry(
    GoblinScenario(
      title: 'Footprint tracker',
      body: 'Checks behind himself to make sure the footprints are still there.',
      emoji: '👣',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.lookAround,
    ),
    _snowCautious,
  ),
  _Entry(
    GoblinScenario(
      title: 'Breath watcher',
      body: 'Puffs into the cold and watches the little cloud vanish. Does it again.',
      emoji: '💨',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.inspect,
    ),
    _snowAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'First tracks',
      body: 'Realises the snow is untouched. Walks carefully to keep it that way.',
      emoji: '🌨️',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.walk,
    ),
    _snowMorning,
  ),

  // ── Fog ───────────────────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Lantern detective',
      body: 'Follows the lantern glow. Loses the path. Finds it again.',
      emoji: '🔦',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.walk,
    ),
    _fogAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Slow walker',
      body: 'Steps carefully. Nothing in this fog is worth rushing into.',
      emoji: '🌫️',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.walk,
    ),
    _fogCautious,
  ),
  _Entry(
    GoblinScenario(
      title: 'Mist watcher',
      body: 'Watches the mist move through the trees. It moves back.',
      emoji: '🌫️',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.lookAround,
    ),
    _fogMorning,
  ),

  // ── Heat ──────────────────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Shade auditor',
      body: 'Audits the nearest shadow. Rates it acceptable. Settles in.',
      emoji: '🌡️',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.rest,
    ),
    _hotArid,
  ),
  _Entry(
    GoblinScenario(
      title: 'Canteen checker',
      body: 'Shakes the canteen. Hears it slosh. Saves the rest anyway.',
      emoji: '🥤',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.inspect,
    ),
    _hotHumid,
  ),
  _Entry(
    GoblinScenario(
      title: 'Shimmer watcher',
      body: 'Sees the air wobble above a rock. Tells nobody, but files it away.',
      emoji: '🫧',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.lookAround,
    ),
    _hotAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Sun avoider',
      body: 'Walks the long way around a patch of bright ground. Worth it.',
      emoji: '🌞',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.walk,
    ),
    _hotMidday,
  ),

  // ── Cold ──────────────────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Mitten counter',
      body: 'Has two mittens. Checks. Still two. Good.',
      emoji: '🧤',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.inspect,
    ),
    _coldAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Scarf fortress',
      body: 'Wraps the scarf tighter until only the eyes remain. Better.',
      emoji: '🧣',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.recover,
    ),
    _coldWindy,
  ),
  _Entry(
    GoblinScenario(
      title: 'Shiver walker',
      body: 'Walks faster. It does not help. Walks faster anyway.',
      emoji: '🥶',
      mood: GoblinMood.cold,
      state: GoblinBehaviorState.walk,
    ),
    _coldAny,
  ),

  // ── Wind ──────────────────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Scarf wrangler',
      body: 'The scarf has plans of its own. Negotiations are ongoing.',
      emoji: '💨',
      mood: GoblinMood.playful,
      state: GoblinBehaviorState.weatherReact,
    ),
    _windyAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Hat grabber',
      body: 'Grabs the hat with both hands. The hat is not going anywhere.',
      emoji: '🎩',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.weatherReact,
    ),
    _galeAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Leaf hopper',
      body: 'Chases a falling leaf. The leaf wins. He tries again.',
      emoji: '🍂',
      mood: GoblinMood.playful,
      state: GoblinBehaviorState.play,
    ),
    _windyAutumn,
  ),
  _Entry(
    GoblinScenario(
      title: 'Wind listener',
      body: 'Tilts an ear toward the trees. Something is in there. Probably wind.',
      emoji: '🌬️',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.lookAround,
    ),
    _windyAny,
  ),

  // ── Dust and sandstorm ────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Goggle adjuster',
      body: 'Tightens the goggles. Tightens them again. They cannot be tighter.',
      emoji: '🥽',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.weatherReact,
    ),
    _dustAny,
  ),
  _Entry(
    GoblinScenario(
      title: 'Sand spitter',
      body: 'Spits out sand. There will be more sand. This is understood.',
      emoji: '🏜️',
      mood: GoblinMood.cautious,
      state: GoblinBehaviorState.recover,
    ),
    _dustAny,
  ),

  // ── Landmark-specific ────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Dome sketcher',
      body: 'Tries to draw the dome in the journal. The dome is harder than it looks.',
      emoji: '🕌',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.inspect,
    ),
    _atTajMahal,
    baseWeight: 3.0,
  ),
  _Entry(
    GoblinScenario(
      title: 'Tower counter',
      body: 'Tries to count the tower’s levels. Loses count at three. Starts over.',
      emoji: '🗼',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.lookAround,
    ),
    _atEiffelOrTokyo,
    baseWeight: 3.0,
  ),
  _Entry(
    GoblinScenario(
      title: 'Skyline study',
      body: 'Looks up at the buildings and does a slow, careful spin.',
      emoji: '🏙️',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.lookAround,
    ),
    _atSkyline,
    baseWeight: 3.0,
  ),
  _Entry(
    GoblinScenario(
      title: 'Landmark sketcher',
      body: 'Sketches the landmark in the journal. It is not to scale. It is fine.',
      emoji: '✏️',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.inspect,
    ),
    _hasLandmark,
  ),

  // ── Location flavour (biome) ──────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'Wave counter',
      body: 'Counts waves. Reaches nine. Decides the sea has won.',
      emoji: '🌊',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.lookAround,
    ),
    _coastal,
  ),
  _Entry(
    GoblinScenario(
      title: 'Peak viewer',
      body: 'Looks up at the mountains. The mountains look back. Politely.',
      emoji: '⛰️',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.lookAround,
    ),
    _mountain,
  ),
  _Entry(
    GoblinScenario(
      title: 'Dune inspector',
      body: 'Picks up a handful of sand. Watches it fall. Picks up another.',
      emoji: '🏜️',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.inspect,
    ),
    _aridNoWeather,
  ),

  // ── Visit history ────────────────────────────────────────────────────────
  _Entry(
    GoblinScenario(
      title: 'New world entry',
      body: 'Takes a slow look around. Marks the spot in the journal.',
      emoji: '📍',
      mood: GoblinMood.curious,
      state: GoblinBehaviorState.lookAround,
    ),
    _firstVisit,
    baseWeight: 1.8,
  ),
  _Entry(
    GoblinScenario(
      title: 'Familiar path',
      body: 'Walks the path without looking down. He knows this one.',
      emoji: '🥾',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.walk,
    ),
    _returning,
  ),
  _Entry(
    GoblinScenario(
      title: 'Local nod',
      body: 'Nods at a rock like it is an old friend. The rock does not reply.',
      emoji: '🪨',
      mood: GoblinMood.calm,
      state: GoblinBehaviorState.rest,
    ),
    _local,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Matchers — kept as named functions so the entry list stays readable.
// ─────────────────────────────────────────────────────────────────────────────

bool _clearMorning(ScenarioContext c) => c.clear && c.isMorning;
bool _clearMiddayHot(ScenarioContext c) => c.clear && c.isMidday && c.hot;
bool _clearEvening(ScenarioContext c) => c.clear && c.isEvening;
bool _clearNight(ScenarioContext c) => c.clear && c.isNight;
bool _clearAny(ScenarioContext c) => c.clear;

bool _overcast(ScenarioContext c) => c.overcast && !c.windy;
bool _overcastWindy(ScenarioContext c) => c.overcast && c.windy;
bool _overcastEvening(ScenarioContext c) => c.overcast && c.isEvening;

bool _firstRain(ScenarioContext c) => c.raining && c.isFirstRainHere;
bool _rainPlayful(ScenarioContext c) => c.raining;
bool _rainCautious(ScenarioContext c) => c.raining;
bool _heavyRain(ScenarioContext c) =>
    c.raining && c.precipitationMm >= 5 && !c.storming;
bool _drizzle(ScenarioContext c) =>
    const {51, 53, 55, 56, 57}.contains(c.weatherCode);
bool _rainAny(ScenarioContext c) => c.raining && !c.storming;
bool _rainNight(ScenarioContext c) => c.raining && c.isNight;

bool _firstStorm(ScenarioContext c) => c.storming && c.isFirstStormHere;
bool _stormCautious(ScenarioContext c) => c.storming;
bool _stormAny(ScenarioContext c) => c.storming;

bool _firstSnow(ScenarioContext c) => c.snowing && c.isFirstSnowHere;
bool _snowPlayful(ScenarioContext c) => c.snowing;
bool _snowCautious(ScenarioContext c) => c.snowing;
bool _snowAny(ScenarioContext c) => c.snowing;
bool _snowMorning(ScenarioContext c) => c.snowing && c.isMorning;

bool _fogAny(ScenarioContext c) => c.foggy;
bool _fogCautious(ScenarioContext c) => c.foggy;
bool _fogMorning(ScenarioContext c) => c.foggy && c.isMorning;

bool _hotArid(ScenarioContext c) => c.hot && c.arid;
bool _hotHumid(ScenarioContext c) => c.hot && !c.arid;
bool _hotAny(ScenarioContext c) => c.hot;
bool _hotMidday(ScenarioContext c) => c.hot && c.isMidday;

bool _coldAny(ScenarioContext c) => c.cold && !c.snowing;
bool _coldWindy(ScenarioContext c) => c.cold && c.windy && !c.snowing;

bool _windyAny(ScenarioContext c) => c.windy;
bool _galeAny(ScenarioContext c) => c.gale;
bool _windyAutumn(ScenarioContext c) => c.windy && c.season == WorldSeason.autumn;

bool _dustAny(ScenarioContext c) => c.dusting;

bool _atTajMahal(ScenarioContext c) => c.landmark == WorldLandmark.tajMahal;
bool _atEiffelOrTokyo(ScenarioContext c) =>
    c.landmark == WorldLandmark.eiffelTower ||
    c.landmark == WorldLandmark.tokyoFuji;
bool _atSkyline(ScenarioContext c) =>
    c.landmark == WorldLandmark.newYorkSkyline ||
    c.landmark == WorldLandmark.singaporeSkyline ||
    c.landmark == WorldLandmark.dubaiTower;
bool _hasLandmark(ScenarioContext c) => c.landmark != WorldLandmark.none;

bool _coastal(ScenarioContext c) => c.coastal;
bool _mountain(ScenarioContext c) => c.mountain;
bool _aridNoWeather(ScenarioContext c) => c.arid && c.clear;

bool _firstVisit(ScenarioContext c) => c.firstVisit;
bool _returning(ScenarioContext c) => c.returning;
bool _local(ScenarioContext c) => c.local;