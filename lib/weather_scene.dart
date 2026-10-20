import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'world_catalog.dart';
import 'weather_rules.dart';
import 'character_behavior.dart';
import 'goblin_sprites.dart';
import 'goblin_scenarios.dart';
import 'local_markers.dart';
import 'world_detail.dart';

ui.Color weatherSceneSkyColor({
  required bool isDay,
  required bool sandstorm,
  required bool storm,
  required bool rain,
  required bool fog,
  required bool overcast,
  required bool snowy,
  required bool hot,
  required bool spring,
  required bool summer,
  required double cloudCover,
}) {
  if (!isDay) {
    if (sandstorm) return const ui.Color(0xFF322630);
    if (storm || rain) return const ui.Color(0xFF111C30);
    if (fog || overcast || cloudCover >= 72) {
      return const ui.Color(0xFF20283C);
    }
    if (snowy) return const ui.Color(0xFF17243A);
    return const ui.Color(0xFF101B35);
  }
  if (sandstorm) return const ui.Color(0xFFC67A43);
  if (storm || rain) return const ui.Color(0xFF3A4C5B);
  if (fog) return const ui.Color(0xFF849BA5);
  if (overcast) return const ui.Color(0xFF89999E);
  if (snowy) return const ui.Color(0xFFB8D1DC);
  if (hot) return const ui.Color(0xFFF5A64C);
  if (spring) return const ui.Color(0xFF86C9D3);
  if (summer) return const ui.Color(0xFF65B9D8);
  return const ui.Color(0xFF6EC7E8);
}

ui.Color weatherSceneGroundColor({
  required bool isDay,
  required bool arid,
  required bool snow,
  required bool rain,
  required bool storm,
  required bool autumn,
  required bool spring,
  required bool summer,
  required bool winterSeason,
}) {
  if (!isDay) {
    if (snow) return const ui.Color(0xFF354957);
    if (arid) return const ui.Color(0xFF4A382F);
    if (rain || storm) return const ui.Color(0xFF18343A);
    if (autumn) return const ui.Color(0xFF3D3031);
    return const ui.Color(0xFF1D3B35);
  }
  if (arid) return const ui.Color(0xFFC98542);
  if (snow) return const ui.Color(0xFFDCEAF0);
  if (autumn) return const ui.Color(0xFF856344);
  if (spring) return const ui.Color(0xFF397452);
  if (summer) return const ui.Color(0xFF3F7448);
  if (winterSeason) return const ui.Color(0xFF625F59);
  if (rain || storm) return const ui.Color(0xFF263D48);
  return const ui.Color(0xFF315E4D);
}

enum _HorizonKind {
  woodedRidge,
  canopy,
  dune,
  mountain,
  skyline,
  coast,
  riverPlain,
}

/// Layers a caller can suppress, so tests can measure one element in isolation.
/// Only the debug entry point sets this; normal rendering uses [none].
enum DebugSceneLayers {
  none,
  withoutLandmark,
  withoutCharacter,
  withoutLandmarkAndCharacter,
}

enum _AmbientKind { bird, butterfly, frog, firefly, owl, cricket }

class _AmbientCreature {
  _AmbientCreature({
    required this.kind,
    required this.x,
    required this.y,
    required this.direction,
    required this.spawnChance,
    required this.minWait,
    required this.waitRange,
    required this.minDuration,
    required this.durationRange,
    required math.Random random,
  }) : waitRemaining = random.nextDouble() * minWait;

  final _AmbientKind kind;
  final double x;
  final double y;
  final double direction;
  final double spawnChance;
  final double minWait;
  final double waitRange;
  final double minDuration;
  final double durationRange;
  double waitRemaining;
  double age = 0;
  double duration = 0;
  bool visible = false;

  void update(double dt, math.Random random) {
    if (visible) {
      age += dt;
      if (age >= duration) visible = false;
      return;
    }
    waitRemaining -= dt;
    if (waitRemaining > 0) return;
    if (random.nextDouble() < spawnChance) {
      visible = true;
      age = 0;
      duration = minDuration + random.nextDouble() * durationRange;
    }
    waitRemaining = minWait + random.nextDouble() * waitRange;
  }
}

class WeatherSceneConfig {
  const WeatherSceneConfig({
    required this.weatherCode,
    required this.isDay,
    required this.temperatureC,
    required this.windKmh,
    required this.location,
    this.precipitationMm = 0,
    this.month = 6,
    this.latitude = 0,
    this.longitude = 0,
    this.city = '',
    this.region = '',
    this.cloudCover,
    this.visibilityM,
    this.windDirectionDeg = 0,
    this.localHour,
    this.profile = const CharacterProfile(),
    this.previousWeatherKey = '',
    this.environment = SceneEnvironment.live,
    this.reduceFlashing = false,
    this.reduceMotion = false,
    this.scenario,
  });

  final int weatherCode;
  final bool isDay;
  final double temperatureC;
  final double windKmh;
  final WorldLocation location;
  final double precipitationMm;
  final int month;
  final double latitude;
  final double longitude;
  final String city;
  final String region;
  final double? cloudCover;
  final double? visibilityM;
  final double windDirectionDeg;
  final int? localHour;
  final CharacterProfile profile;
  final String previousWeatherKey;
  final SceneEnvironment environment;
  final bool reduceFlashing;
  final bool reduceMotion;
  final GoblinScenario? scenario;
}

/// Holds one Flame game across ordinary Flutter rebuilds so character actions
/// continue naturally while fresh weather data is applied.
class WeatherSceneHost extends StatefulWidget {
  const WeatherSceneHost({super.key, required this.config});

  final WeatherSceneConfig config;

  @override
  State<WeatherSceneHost> createState() => _WeatherSceneHostState();
}

class _WeatherSceneHostState extends State<WeatherSceneHost> {
  late final WeatherSceneGame _game = WeatherSceneGame(config: widget.config);

  @override
  void initState() {
    super.initState();
    // Loading is idempotent and cheap after the first call, so this only guards
    // against a host that mounted before the shared warm-up finished.
    unawaited(_game.loadCharacterSprites());
  }

  @override
  void didUpdateWidget(covariant WeatherSceneHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updateConfig(widget.config);
  }

  @override
  Widget build(BuildContext context) => GameWidget(game: _game);
}

/// Pixel-art weather world. The environment is drawn procedurally in Flame; the
/// character uses the PNG sprite frames in `assets/images/goblin_frames`, with
/// the procedural goblin retained as a fallback if those frames cannot load.
class WeatherSceneGame extends FlameGame with TapCallbacks, LongPressCallbacks {
  WeatherSceneGame({required this.config})
      : _ambientRandom = math.Random(config.location.id.codeUnits
            .fold<int>(17, (sum, value) => sum * 31 + value)) {
    _configureAmbientLife();
  }

  WeatherSceneConfig config;
  final math.Random _ambientRandom;
  final List<_AmbientCreature> _ambientCreatures = [];
  int get weatherCode => config.weatherCode;
  bool get isDay => config.isDay;
  double get temperatureC => config.temperatureC;
  double get windKmh => config.windKmh;
  double get precipitationMm => config.precipitationMm;
  int get month => config.month;
  double get latitude => config.latitude;
  double get longitude => config.longitude;
  String get city => config.city;
  String get region => config.region;
  double? get cloudCover => config.cloudCover;
  double? get visibilityM => config.visibilityM;
  double get windDirectionDeg => config.windDirectionDeg;
  int? get localHour => config.localHour;
  CharacterProfile get profile => config.profile;
  String get previousWeatherKey => config.previousWeatherKey;
  bool get reduceMotion => config.reduceMotion;
  WorldLocation get location => config.location;
  SceneEnvironment get environment => config.environment;
  bool get reduceFlashing => config.reduceFlashing;
  GoblinScenario? get scenario => config.scenario;

  late WeatherConditions _conditions = WeatherConditions(
    code: weatherCode,
    temperatureC: temperatureC,
    precipitationMm: precipitationMm,
    windKmh: windKmh,
    cloudCover: cloudCover,
    visibilityM: visibilityM,
  );

  void updateConfig(WeatherSceneConfig next) {
    final ambientContextChanged = next.location.id != config.location.id ||
        next.weatherCode != config.weatherCode ||
        next.isDay != config.isDay ||
        next.temperatureC != config.temperatureC ||
        next.windKmh != config.windKmh ||
        next.precipitationMm != config.precipitationMm ||
        next.cloudCover != config.cloudCover ||
        next.visibilityM != config.visibilityM ||
        next.month != config.month ||
        next.environment != config.environment;
    config = next;
    _conditions = WeatherConditions(
      code: next.weatherCode,
      temperatureC: next.temperatureC,
      precipitationMm: next.precipitationMm,
      windKmh: next.windKmh,
      cloudCover: next.cloudCover,
      visibilityM: next.visibilityM,
    );
    _cachedBehaviorContext = null;
    _behavior.temperament = next.profile.temperament;
    if (ambientContextChanged) _configureAmbientLife();
  }

  double _elapsed = 0;
  double _sunExposure = 0;
  double _strikeAge = 99;
  double _nextStrike = 7;
  bool _directHit = false;
  String? _dialogue;
  double _dialogueAge = 0;
  double _lastAmbientDialogueAt = -100;
  int _lastQuipIndex = -1;
  double _hitRecovery = 0;
  final math.Random _random = math.Random();
  late final CharacterBehaviorController _behavior =
      CharacterBehaviorController(
    temperament: profile.temperament,
    previousWeatherKey: previousWeatherKey,
    seed: location.id.codeUnits.fold(17, (sum, value) => sum * 31 + value),
  );
  int _lastBehaviorRevision = -1;
  bool _longPressHandled = false;

  /// Goblin sprite frames, or null while the assets are still loading (or if
  /// loading failed). A null source falls back to the procedural goblin, so the
  /// scene is always renderable.
  GoblinSprites? _sprites;
  bool _spritesRequested = false;

  /// Loads the character sprite frames. Call once before mounting the game;
  /// repeated calls are cheap because [GoblinSprites.warmCache] reuses the
  /// shared image cache. Failures leave [_sprites] null, which falls back to
  /// the procedural character rather than throwing into the render loop.
  Future<void> loadCharacterSprites() async {
    if (_spritesRequested) return;
    _spritesRequested = true;
    try {
      await GoblinSprites.warmCache();
      _sprites = GoblinSprites.fromCache();
    } catch (error, stack) {
      _spritesRequested = false;
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'weather_scene',
        context: ErrorDescription('loading goblin sprite frames'),
      ));
    }
  }

  /// True once the sprite frames are available and the character renders from
  /// them rather than from the procedural fallback.
  bool get usesSpriteCharacter => _sprites != null && !_sprites!.isEmpty;

  /// Test seam: installs already-decoded sprite frames without going through the
  /// asset bundle, which `flutter test` does not build.
  @visibleForTesting
  void debugSetSprites(GoblinSprites sprites) {
    _spritesRequested = true;
    _sprites = sprites;
  }

  /// Test seam: suppresses one drawn layer so a frame can be measured with the
  /// landmark or the character removed. Leave at [DebugSceneLayers.none] in app
  /// code.
  @visibleForTesting
  DebugSceneLayers debugHiddenLayers = DebugSceneLayers.none;

  CharacterSceneContext? _cachedBehaviorContext;
  int? _cachedBehaviorHour;
  final List<String> _recentDialogue = [];
  double _boltStartX = 0;
  double _boltTargetX = 0;
  double _boltTargetY = 0;
  ui.Color _boltColor = const ui.Color(0xFFF3FCFF);
  final List<ui.Offset> _boltPoints = [];
  final List<ui.Offset> _branchStarts = [];
  final List<ui.Offset> _branchKnees = [];
  final List<ui.Offset> _branchTips = [];

  bool get _cyclone => environment == SceneEnvironment.cyclone;
  bool get _flood => environment == SceneEnvironment.flood;
  bool get _desertHeat =>
      environment == SceneEnvironment.desertHeat ||
      (_live &&
          location.isArid &&
          isDay &&
          temperatureC >= strongHeatThresholdC &&
          const [0, 1, 2].contains(weatherCode));
  bool get _sandstorm =>
      environment == SceneEnvironment.sandstorm ||
      (_live &&
          location.isArid &&
          const [30, 31, 32, 33, 34, 35].contains(weatherCode));
  bool get _live => environment == SceneEnvironment.live;

    LocalMarker? _cachedMarker;
  String? _cachedMarkerKey;

  /// The local marker for the current city, or null if none applies.
  ///
  /// Markers are suppressed when the location has a landmark, so a scene
  /// never carries two competing focal points.
  LocalMarker? get _localMarker {
    if (location.landmark != WorldLandmark.none) return null;
    final key = '$city|$region';
    if (_cachedMarkerKey == key) return _cachedMarker;
    _cachedMarkerKey = key;
    _cachedMarker = pickLocalMarker(city: city, region: region);
    return _cachedMarker;
  }

  /// Lane the marker occupies, as a fraction of scene width.
  ///
  /// With no landmark present, the character holds the centre, so the marker
  /// is pushed to the right.
  double get _markerLaneX => .74;
  
  WorldSeason get _season {
    return worldSeasonForMonth(month, latitude);
  }

  bool get _winterWorld => _live && _snow;
  bool get _winterSeason =>
      _live && location.seasonalFoliage && _season == WorldSeason.winter;
  double get _environmentMotionScale => reduceMotion ? .32 : 1.0;

  /// Stable per-place seed for decorative detail (see world_detail.dart).
  /// Fallback places share ids per zone ('regional-desert'...), so the
  /// coordinates are mixed in to keep neighbouring places different.
  int get _detailSeed => detailSeed(
      '${location.id}|${location.latitude.toStringAsFixed(1)}|${location.longitude.toStringAsFixed(1)}');
  bool get _cold => _live && (_snow || temperatureC <= 12);
  bool get _autumnWorld =>
      _live && location.seasonalFoliage && _season == WorldSeason.autumn;
  bool get _springWorld =>
      _live && location.seasonalFoliage && _season == WorldSeason.spring;
  bool get _summerWorld => _live && _season == WorldSeason.summer;

  bool get _humidHabitat =>
      location.biome == WorldBiome.tropical ||
      location.biome == WorldBiome.coastal ||
      location.biome == WorldBiome.river;

  bool get _woodedHabitat =>
      location.biome == WorldBiome.temperate ||
      location.biome == WorldBiome.tropical ||
      location.biome == WorldBiome.mountain;
  double get _floodProgress =>
      (_elapsed * (reduceMotion ? .65 : 1) / 25).clamp(0.0, 1.0);
  double get _routePhase => _elapsed % 14;
  bool get _walking {
    if (_live) return _behavior.isWalking;
    if (_cyclone || _sandstorm) return true;
    if (_flood) return _elapsed < 4.5;
    if (_desertHeat) return _elapsed < 4;
    return _routePhase < 4 || (_routePhase >= 7 && _routePhase < 11);
  }

  /// The character's horizontal lane, as a fraction of scene width.
  ///
  /// Landmark footprints were measured to straddle the centre of every scene, so
  /// a centred character always covered the landmark's most recognizable feature.
  /// When a landmark is present the character keeps to the right-hand lane; with
  /// no landmark it stays centred.
  double get _characterLane =>
      location.landmark == WorldLandmark.none ? .50 : .755;

  /// Extent of the character's lateral walk, in scene-width fractions.
  double get _characterLaneSpan =>
      location.landmark == WorldLandmark.none ? .30 : .12;

  /// Fore-and-aft sweep for the non-interactive route scenes, oscillating
  /// smoothly between -1 and 1 with a reversal at each end.
  double get _routeSweep =>
      math.sin(math.pi * ((_routePhase / 14) % 1.0)).abs() * 2 - 1;

  bool get _walkingLeft {
    if (_live) {
      return _behavior.isWalking && _behavior.walkDirection < 0;
    }
    if (_cyclone || _sandstorm || _desertHeat) {
      // These scenes sweep laterally, so facing follows the current direction.
      return math.cos(math.pi * ((_routePhase / 14) % 1.0)) < 0;
    }
    // Route scenes move right on the outbound leg and left on the return leg.
    return _routePhase >= 7 && _routePhase < 11;
  }
  double get _sceneX {
    if (_cyclone) {
      return .20 + .11 * (_wind / 160) + .02 * math.sin(_elapsed * 4);
    }
    // The flood set-piece places the raft and alert sign in its own left-of-
    // centre slot, so the character is matched to those rather than to the
    // landmark lane (a flood scene draws no landmark).
    if (_flood) return .40;
    if (_sandstorm) {
      return _characterLane + .06 * math.sin(_elapsed * .35);
    }
    if (_desertHeat) {
      return _elapsed < 4
          ? .32 + (_characterLane - .02 - .32) * (_elapsed / 4)
          : _characterLane - .02;
    }
    final walkScale = reduceFlashing || reduceMotion ? .5 : 1.0;
    if (_live) {
      final lane = _characterLane;
      return (lane + _behavior.walkAmount * walkScale * (.05 / .055))
          .clamp(lane - .05, lane + .05)
          .toDouble();
    }
    return _characterLane + _routeSweep * _characterLaneSpan / 2;
  }

  double get _strideSpeed => _cyclone
      ? 12
      : _sandstorm
          ? 10
          : 7;
  double get _wind => _cyclone
      ? 60 + 100 * (_elapsed / 30).clamp(0.0, 1.0)
      : environment == SceneEnvironment.sandstorm
          ? 72
          : environment == SceneEnvironment.flood
              ? 34
              : windKmh;
  bool get _rainCode => _conditions.raining;
  bool get _storm =>
      _cyclone || _flood || (_live && const [95, 96, 99].contains(weatherCode));
  bool get _thunderstorm => _live && _conditions.thunderstorm;
  bool get _snow => _live && _conditions.snowing;
  bool get _rain => _cyclone || _flood || _storm || (_live && _rainCode);
  bool get _fog => _live && _conditions.foggy;
  bool get _sunBeamActive =>
      isDay &&
      (_desertHeat ||
          (_live &&
              temperatureC >= strongHeatThresholdC &&
              const [0, 1, 2].contains(weatherCode)));
  double get _sunHeatProgress => _desertHeat
      ? (_elapsed / 8).clamp(0.0, 1.0).toDouble()
      : (_sunExposure /
              8 *
              ((temperatureC - strongHeatThresholdC) /
                      (extremeHeatThresholdC - strongHeatThresholdC))
                  .clamp(0.0, 1.0))
          .clamp(0.0, 1.0)
          .toDouble();
  bool get _heatStress => _live && _conditions.strongHeat;
  bool get _hot =>
      _desertHeat ||
      (_live && location.isArid && temperatureC >= strongHeatThresholdC);
  bool get _windy => _wind >= windyThresholdKmh;
  double get _cloudCoverage => _conditions.cloudPercent;
  bool get _overcast => _conditions.overcast;
  double get _rainIntensity => _conditions.rainIntensity;
  bool get _lightRain => _live && _conditions.drizzle && !_thunderstorm;

  ui.Color get _skyColor {
    return weatherSceneSkyColor(
      isDay: isDay,
      sandstorm: _sandstorm,
      storm: _storm || _cyclone || _flood,
      rain: _rain,
      fog: _fog,
      overcast: _overcast,
      snowy: _winterWorld,
      hot: _hot,
      spring: _springWorld,
      summer: _summerWorld,
      cloudCover: _cloudCoverage,
    );
  }

  ui.Color get _groundColor => weatherSceneGroundColor(
        isDay: isDay,
        arid: location.isArid || _sandstorm,
        snow: _winterWorld,
        rain: _rain,
        storm: _storm,
        autumn: _autumnWorld,
        spring: _springWorld,
        summer: _summerWorld,
        winterSeason: _winterSeason,
      );

  /// Night dimming wash, applied per element rather than over the whole scene.
  static const ui.Color _nightWashColor = ui.Color(0xFF202C4D);

  /// Dusk colour the late-afternoon landscape leans toward as the light fades,
  /// softening the step between the day and night sky palettes.
  static const ui.Color _duskSkyColor = ui.Color(0xFF6B5670);

  /// Sky colour after the lighting model has had its say. Exposed for tests.
  @visibleForTesting
  ui.Color get debugLitSkyColor {
    final base = _skyColor;
    final fall = _nightAmount;
    if (fall <= 0) return base;
    return ui.Color.lerp(base, _duskSkyColor, (fall * .55).clamp(0.0, 1.0))!;
  }

  /// Night dimming strength for the current hour, 0 by day and 1 at night.
  @visibleForTesting
  double get debugNightAmount => _nightAmount;

  /// Strength of the warm sunrise/sunset cast.
  @visibleForTesting
  double get debugGoldenAmount => _goldenAmount;

  /// Where the sun sits between rise and set, or null when it is below the
  /// horizon. Drives both the sun's screen position and the light direction.
  @visibleForTesting
  double? get debugSunProgress => _sunProgress;

  /// Lateral offset of the mid-ground layer, in logical pixels, for a scene of
  /// the given width. Distant layers share the far horizon's fixed frame; the
  /// character's layer stays fixed too, so this is the layer that reads as
  /// "nearer than the horizon, further than the character".
  @visibleForTesting
  double debugParallaxMidOffset(double width) => _parallaxMidOffset(width);
  static const int _nightWashMaxAlpha = 0x33;

  /// Fraction of the way from rise to set, 0..1, or null outside daylight.
  double? get _sunProgress {
    final hour = localHour;
    if (hour == null) return null;
    // The scene advances a few seconds per hour, so the sun drifts visibly.
    final hourNow = hour + _elapsed / 3600;
    if (hourNow <= _sunriseHour || hourNow >= _sunsetHour) return null;
    return ((hourNow - _sunriseHour) / (_sunsetHour - _sunriseHour))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static const double _sunriseHour = 6.0;
  static const double _sunsetHour = 18.0;

  /// How dark the current hour is: 0 in full daylight, 1 at deep night, with
  /// linear ramps across dawn and dusk.
  double get _nightAmount {
    final hour = localHour;
    if (hour == null) return isDay ? 0.0 : 1.0;
    final hourNow = hour + _elapsed / 3600;
    // Wrap so a scene left running past midnight keeps a sane hour.
    final at = hourNow % 24;
    const dawnStart = 5.0, dawnEnd = 7.5;
    const duskStart = 19.0, duskEnd = 21.0;

    if (at <= dawnStart || at >= duskEnd) return 1.0;
    if (at < dawnEnd) {
      return ((dawnEnd - at) / (dawnEnd - dawnStart)).clamp(0.0, 1.0).toDouble();
    }
    if (at < duskStart) return 0.0;
    return ((at - duskStart) / (duskEnd - duskStart)).clamp(0.0, 1.0).toDouble();
  }

  /// Strength of the warm sunrise/sunset cast, peaking at the horizon.
  double get _goldenAmount {
    final progress = _sunProgress;
    if (progress == null) return 0.0;
    // Fades out as the sun climbs away from the horizon.
    final elevation = math.sin(progress * math.pi);
    return ((1 - elevation) * .9).clamp(0.0, 1.0).toDouble();
  }

  /// The single light cast over the whole landscape layer, replacing the old
  /// flat night rectangle. Zero alpha means full daylight.
  ui.Color get _lightTint {
    final night = _nightAmount;
    final golden = _goldenAmount;
    var alpha = (night * _nightWashMaxAlpha).round();
    var color = _nightWashColor;
    if (golden > 0) {
      color = ui.Color.lerp(color, const ui.Color(0xFFFF9A55), .55)!;
      alpha = math.max(alpha, (golden * 0x2E).round());
    }
    return ui.Color.fromARGB(
      alpha.clamp(0, 255).toInt(),
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    );
  }

  void _configureAmbientLife() {
    _ambientCreatures.clear();
    void add(
      _AmbientKind kind, {
      required int count,
      required double yMin,
      required double yRange,
      required double spawnChance,
      required double minWait,
      required double waitRange,
      required double minDuration,
      required double durationRange,
    }) {
      for (var i = 0; i < count; i++) {
        _ambientCreatures.add(_AmbientCreature(
          kind: kind,
          x: .08 + _ambientRandom.nextDouble() * .84,
          y: yMin + _ambientRandom.nextDouble() * yRange,
          direction: _ambientRandom.nextBool() ? 1 : -1,
          spawnChance: spawnChance,
          minWait: minWait,
          waitRange: waitRange,
          minDuration: minDuration,
          durationRange: durationRange,
          random: _ambientRandom,
        ));
      }
    }

    final clearEnough = !_thunderstorm && !_sandstorm && !_fog;
    if (isDay && clearEnough && _wind < galeWindThresholdKmh) {
      add(_AmbientKind.bird,
          count: 2,
          yMin: .12,
          yRange: .19,
          spawnChance: .72,
          minWait: 15,
          waitRange: 19,
          minDuration: 5,
          durationRange: 5);
    }
    if (isDay &&
        _springWorld &&
        clearEnough &&
        _wind < strongWindThresholdKmh) {
      add(_AmbientKind.butterfly,
          count: 2,
          yMin: .48,
          yRange: .30,
          spawnChance: .68,
          minWait: 12,
          waitRange: 16,
          minDuration: 3,
          durationRange: 4);
    }
    if ((_humidHabitat || _woodedHabitat) &&
        _hasWater &&
        (_rain || !_winterWorld)) {
      add(_AmbientKind.frog,
          count: 2,
          yMin: .78,
          yRange: .10,
          spawnChance: .64,
          minWait: 10,
          waitRange: 15,
          minDuration: 2,
          durationRange: 2.5);
    }
    if (!isDay && clearEnough && (_humidHabitat || _woodedHabitat)) {
      add(_AmbientKind.firefly,
          count: 4,
          yMin: .42,
          yRange: .38,
          spawnChance: .78,
          minWait: 3,
          waitRange: 8,
          minDuration: 2,
          durationRange: 4);
    }
    if (!isDay && clearEnough && _woodedHabitat && !_rain) {
      add(_AmbientKind.owl,
          count: 1,
          yMin: .20,
          yRange: .16,
          spawnChance: .42,
          minWait: 24,
          waitRange: 30,
          minDuration: 5,
          durationRange: 4);
    }
    if (!isDay && location.biome != WorldBiome.urban && !_sandstorm) {
      add(_AmbientKind.cricket,
          count: 2,
          yMin: .84,
          yRange: .10,
          spawnChance: .48,
          minWait: 16,
          waitRange: 24,
          minDuration: 2,
          durationRange: 3);
    }
  }

  bool get _hasWater =>
      location.biome == WorldBiome.coastal ||
      location.biome == WorldBiome.river ||
      _conditions.raining ||
      precipitationMm > 0;

  String get _behaviorWeatherKey {
    if (_conditions.thunderstorm) return 'storm';
    if (_conditions.snowing) return 'snow';
    if (_conditions.raining) {
      return _rainIntensity >= .65 ? 'heavy rain' : 'drizzle';
    }
    if (_conditions.dusty || _sandstorm) return 'sand';
    if (temperatureC >= strongHeatThresholdC && isDay) return 'heat';
    if (_conditions.foggy) return 'fog';
    if (temperatureC <= 5) return 'cold';
    if (windKmh >= windyThresholdKmh) return 'wind';
    return 'clear';
  }

  CharacterSceneContext get _characterContext {
    final hour = localHour == null
        ? null
        : (localHour! + (_elapsed / 3600).floor()) % 24;
    if (_cachedBehaviorContext != null && _cachedBehaviorHour == hour) {
      return _cachedBehaviorContext!;
    }
    _cachedBehaviorHour = hour;
    return _cachedBehaviorContext = CharacterSceneContext(
      weatherKey: _behaviorWeatherKey,
      night: hour != null ? hour >= 21 || hour < 5 : !isDay,
      morning: hour != null ? hour >= 5 && hour <= 10 : false,
      hasLandmark: location.landmark != WorldLandmark.none,
      hasWater: location.biome == WorldBiome.coastal ||
          location.biome == WorldBiome.river ||
          (_rain && precipitationMm > 0),
      hasFlowers: _springWorld,
      hasLeaves: _autumnWorld,
      hasClouds: !_hot && !_sandstorm && _cloudCoverage >= 20,
      criticalWeather: _thunderstorm ||
          windKmh >= galeWindThresholdKmh ||
          (temperatureC >= extremeHeatThresholdC && isDay) ||
          (_conditions.raining && _rainIntensity >= .82),
      reducedMotion: reduceMotion,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Wait for tap-up so a long press is not also treated as a normal tap.
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_longPressHandled) {
      _longPressHandled = false;
      return;
    }
    _handleCharacterTouch(event.canvasPosition.x, event.canvasPosition.y,
        longPress: false);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _longPressHandled = false;
  }

  @override
  void onLongPressStart(LongPressStartEvent event) {
    super.onLongPressStart(event);
    _longPressHandled = true;
    _handleCharacterTouch(event.canvasPosition.x, event.canvasPosition.y,
        longPress: true);
  }

  void _handleCharacterTouch(double tapX, double tapY,
      {required bool longPress}) {
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;

    final unit = math.max(2.0, math.min(w, h) * .014).toDouble();
    final goblinX = w * _sceneX;
    final goblinFloor = _sceneFloor(h);
    final inGoblinBounds = (tapX - goblinX).abs() <= unit * 8 &&
        tapY >= goblinFloor - unit * 30 &&
        tapY <= goblinFloor + unit * 2;

    if (inGoblinBounds) {
      if (_behavior.interact(
          longPress: longPress, context: _characterContext)) {
        _tellWeatherQuip(longPress: longPress);
      }
    }
  }

  double _sceneFloor(double h) {
    final floodProgress = _floodProgress;
    return _flood
        ? h * math.min(.82, .88 - .38 * floodProgress)
        : h * ((_rain && !_hot && !_winterWorld && !_sandstorm) ? .82 : .87);
  }

  void _tellWeatherQuip({bool longPress = false}) {
    if (longPress) {
      _say('A long press! I thought we were having a staring contest.');
      return;
    }
    final quips = _cyclone
        ? const [
            'Forecast: gusts to 160. My scarf has resigned.',
            'I asked the wind to chill. It took that literally.',
            'My hat is now somewhere in next week’s forecast.',
          ]
        : _flood
            ? const [
                'This raft is great. The water level keeps raising the stakes.',
                'I wanted a waterfront home. The water misunderstood.',
                'My boots are now tiny indoor swimming pools.',
              ]
            : _desertHeat
                ? const [
                    'I am not blushing. The sun is just very persuasive.',
                    'My shade is smaller than my to-do list.',
                    'I brought water. The desert asked for the whole bottle.',
                  ]
                : _sandstorm
                    ? const [
                        'I packed a sand-wich. The storm packed the rest.',
                        'My goggles are clear. The view has other plans.',
                        'I can see the dune. I think it moved.',
                      ]
                    : _storm
                        ? const [
                            'I asked the thunder for a quiet night. It said “no”.',
                            'That lightning was a bright idea. Not mine.',
                            'The forecast says “chance of a dramatic entrance”.',
                          ]
                        : _snow || temperatureC <= 12
                            ? const [
                                'I tried to catch a snowflake. Now I have a cold hand.',
                                'My breath is making tiny clouds. I should charge rent.',
                                'I wore two mittens. My nose is still jealous.',
                              ]
                            : _rain
                                ? const [
                                    'Puddles are just tiny sky mirrors with commitment issues.',
                                    'I stepped in a puddle. It stepped in both boots.',
                                    'Rain check? I think the sky already cashed it.',
                                  ]
                                : _fog
                                    ? const [
                                        'I can’t see the forecast, but it says “you are here”.',
                                        'I followed my lantern. Good news: I found me.',
                                        'The fog said hello. I think. We should meet again.',
                                      ]
                                    : _windy
                                        ? const [
                                            'Wind check: my scarf is flying first class.',
                                            'I leaned into the wind. It leaned back.',
                                            'My hat just became a weather balloon.',
                                          ]
                                        : _hot
                                            ? const [
                                                'I am making my own humidity.',
                                                'The sun and I have a very warm relationship.',
                                                'If I stand still, do I count as shade?',
                                              ]
                                            : _springWorld
                                                ? const [
                                                    'Pollen forecast: my sneeze arrives right on time.',
                                                    'I stopped to smell the flowers. They tickled back.',
                                                    'Spring has sprung. I am still looking for my hat.',
                                                  ]
                                                : _autumnWorld
                                                    ? const [
                                                        'I am leaf-ing this forecast to the experts.',
                                                        'A leaf landed on my hood. New seasonal outfit!',
                                                        'The trees are shedding. I should try that with chores.',
                                                      ]
                                                    : const [
                                                        'The sky is clear. My thoughts are partly cloudy.',
                                                        'Forecast says sunny. I brought my best squint.',
                                                        'Lovely weather. I planned this outfit by accident.',
                                                      ];
    final options = <int>[
      for (var i = 0; i < quips.length; i++)
        if (i != _lastQuipIndex) i,
    ];
    final next = options[_random.nextInt(options.length)];
    _lastQuipIndex = next;
    _say(quips[next]);
  }

  void _say(String line, {double seconds = 4.2}) {
    if (_recentDialogue.contains(line) && _recentDialogue.isNotEmpty) {
      line = _recentDialogue.first;
    }
    _recentDialogue
      ..remove(line)
      ..insert(0, line);
    if (_recentDialogue.length > 5) _recentDialogue.removeLast();
    _dialogue = line;
    _dialogueAge = seconds;
  }

  void _triggerStrike({required bool directHit}) {
    _strikeAge = 0;
    _directHit = directHit;
    _hitRecovery = directHit ? 1.35 : 0.55;
    _behavior.surprise(directHit: directHit);
    _prepareLightning(directHit);
    if (directHit && !reduceFlashing) {
      HapticFeedback.heavyImpact();
    }
  }

  void _prepareLightning(bool directHit) {
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;

    final goblinX = w * _sceneX;
    _boltTargetX = directHit
        ? (goblinX + (_random.nextDouble() - .5) * w * .12)
            .clamp(w * .05, w * .95)
            .toDouble()
        : w * (.18 + _random.nextDouble() * .64);
    _boltTargetY = directHit
        ? h * (.49 + _random.nextDouble() * .08)
        : h * (.62 + _random.nextDouble() * .28);
    _boltStartX = (_boltTargetX + (_random.nextDouble() - .5) * w * .42)
        .clamp(w * .04, w * .96)
        .toDouble();
    _boltColor = [
      const ui.Color(0xFFF3FCFF),
      const ui.Color(0xFFDDF5FF),
      const ui.Color(0xFFE9E2FF),
    ][_random.nextInt(3)];

    _boltPoints.clear();
    _branchStarts.clear();
    _branchKnees.clear();
    _branchTips.clear();
    const segments = 7;
    for (var i = 1; i <= segments; i++) {
      final t = i / segments;
      final centerX = ui.lerpDouble(_boltStartX, _boltTargetX, t)!;
      final jitter = (_random.nextDouble() - .5) * w * .13 * (1 - t);
      _boltPoints.add(ui.Offset(centerX + jitter, _boltTargetY * t));
    }
    for (var i = 0; i < 3; i++) {
      final from = _boltPoints[1 + _random.nextInt(_boltPoints.length - 2)];
      final direction = _random.nextBool() ? 1.0 : -1.0;
      _branchStarts.add(from);
      _branchKnees.add(ui.Offset(
        (from.dx + direction * w * (.025 + _random.nextDouble() * .035))
            .clamp(w * .02, w * .98)
            .toDouble(),
        from.dy + h * (.025 + _random.nextDouble() * .035),
      ));
      final knee = _branchKnees.last;
      _branchTips.add(ui.Offset(
        (knee.dx + direction * w * (.018 + _random.nextDouble() * .028))
            .clamp(w * .02, w * .98)
            .toDouble(),
        knee.dy + h * (.015 + _random.nextDouble() * .03),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _behavior.update(dt, _characterContext);
    final activeScenario = config.scenario;
    if (activeScenario != null) {
      _behavior.reactToScenario(activeScenario);
    }
    for (final creature in _ambientCreatures) {
      creature.update(dt, _ambientRandom);
    }
    if (_behavior.revision != _lastBehaviorRevision) {
      _lastBehaviorRevision = _behavior.revision;
      _speakForBehavior();
    }
    _strikeAge += dt;
    _hitRecovery = math.max(0.0, _hitRecovery - dt);
    _sunExposure = _sunBeamActive
        ? _sunExposure + dt
        : math.max(0.0, _sunExposure - dt * 2);
    _dialogueAge = math.max(0.0, _dialogueAge - dt);
    if (_dialogueAge == 0) _dialogue = null;
    if (_thunderstorm && _strikeAge >= _nextStrike) {
      _triggerStrike(directHit: _random.nextDouble() < .28);
      _nextStrike = 6 + _random.nextDouble() * 9;
    }
  }

  void _speakForBehavior() {
    if (_dialogueAge > 1.2) return;
    final isWeatherReaction =
        _behavior.state == GoblinBehaviorState.weatherReact;
    final dialogueCooldown = isWeatherReaction ? 12.0 : 28.0;
    if (_elapsed - _lastAmbientDialogueAt < dialogueCooldown) return;
    final target = _behavior.actionTarget;
    switch (_behavior.state) {
      case GoblinBehaviorState.weatherReact:
        final line = switch (target) {
          'storm' => _unusedLine(profile.temperament.caution > .62
              ? [
                  'That thunder arrived with absolutely no manners.',
                  'I am calm. My ears are simply standing up.',
                  'I shall wait here until the sky stops shouting.',
                ]
              : [
                  'That thunder arrived with absolutely no manners.',
                  'Was that thunder or the sky dropping its lunch?',
                  'The sky has a very loud opinion today.',
                ]),
          'heavy rain' => _unusedLine([
              'Shelter plan: hood first, dignity later.',
              'I am trusting this hood with my entire afternoon.',
              'The puddles are growing faster than my confidence.',
            ]),
          'drizzle' => _unusedLine([
              'A little rain. I shall inspect each drop personally.',
              'The rain is being polite. I shall be polite back.',
              'Tiny drops, enormous commitment.',
            ]),
          'snow' => _unusedLine([
              'Snow! I am accepting tiny cold visitors.',
              'I caught a snowflake. It vanished. Very suspicious.',
              'A snowflake landed on me. I shall call it a hat.',
            ]),
          'wind' || 'sand' => _unusedLine([
              'I am leaning. The wind is still winning.',
              'My scarf is trying to explore without me.',
              'I planted my feet. The wind read the instructions too.',
            ]),
          'heat' => _unusedLine([
              'I am moving to the nearest patch of shade.',
              'If I stand very still, I can become my own shade.',
              'The sun is cooking me at a very personal pace.',
            ]),
          'fog' => _unusedLine([
              'I can see the path. The path is being shy.',
              'I am sure the horizon is around here somewhere.',
              'The fog made the world smaller. Convenient, I suppose.',
            ]),
          'cold' => _unusedLine([
              'I have become a very small bundle of scarf.',
              'My ears have requested a warmer forecast.',
              'I am keeping my hands in my sleeves until spring.',
            ]),
          _ => 'The weather changed. I should take a look.',
        };
        _sayAmbient(line, seconds: 3.8);
      case GoblinBehaviorState.landmarkReact:
        _sayAmbient('The ${_landmarkTitle()} deserves a closer look.',
            seconds: 3.8);
      case GoblinBehaviorState.inspect:
        final line = switch (target) {
          'landmark' =>
            'I wonder how long the ${_landmarkTitle()} has watched this weather.',
          'puddle' => 'A puddle! It is almost as reflective as I am.',
          'flowers' => 'These flowers smell like excellent weather.',
          'falling leaf' => 'That leaf is taking the scenic route.',
          'clouds' => 'I think that cloud looks a bit like a goblin.',
          _ => 'What have we got here?',
        };
        _sayAmbient(line, seconds: 3.5);
      case GoblinBehaviorState.play:
        final line = switch (target) {
          'puddle' => 'Puddle hop! My boots regret nothing.',
          'falling leaf' => 'I nearly caught it. The leaf has escape plans.',
          'flowers' => 'I am not dancing. The flowers started it.',
          _ => 'A tiny victory dance for the weather.',
        };
        _sayAmbient(line, seconds: 3.6);
      case GoblinBehaviorState.sleep:
        _sayAmbient('Just resting my eyes. Very weather-aware of me.',
            seconds: 2.2);
      case GoblinBehaviorState.yawn:
        _sayAmbient(
            'The forecast is fascinating. I may have blinked for a minute.',
            seconds: 3.2);
      case GoblinBehaviorState.lookAround when target == 'scratch':
        _sayAmbient('I had a thought. It wandered off.', seconds: 2.8);
      case GoblinBehaviorState.lookAround when target == 'clearing sky':
        _sayAmbient('The sky is clearing. Back to my important wandering.',
            seconds: 3.5);
      default:
        break;
    }
  }

  void _sayAmbient(String line, {required double seconds}) {
    _say(line, seconds: seconds);
    _lastAmbientDialogueAt = _elapsed;
  }

  String _unusedLine(List<String> options) {
    final fresh =
        options.where((line) => !_recentDialogue.contains(line)).toList();
    final pool = fresh.isEmpty ? options : fresh;
    return pool[_random.nextInt(pool.length)];
  }

  String _landmarkTitle() {
    final words = location.landmark.name
        .replaceAllMapped(
            RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
        .replaceAll('_', ' ');
    if (words.isEmpty) return location.name;
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;

    _rect(canvas, 0, 0, w, h, debugLitSkyColor);

    final hour = localHour;
    if (isDay &&
        hour != null &&
        ((hour >= 5 && hour <= 8) || (hour >= 17 && hour <= 20))) {
      final sunrise = hour <= 8;
      final tint =
          sunrise ? const ui.Color(0x24FFB37B) : const ui.Color(0x2AFF855E);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, h * .30, w, h * .42),
        ui.Paint()
          ..shader = ui.Gradient.linear(
            ui.Offset(0, h * .30),
            ui.Offset(0, h * .72),
            [tint, const ui.Color(0x00FFB37B)],
          ),
      );
    }

    _drawSkyDetails(canvas, w, h);

    if (_desertHeat && isDay) {
      final pulse = .94 + .06 * math.sin(_elapsed * 2.4);
      final center = ui.Offset(w * .79, h * .15);
      canvas.drawCircle(center, w * .17 * pulse,
          ui.Paint()..color = const ui.Color(0x33FFF0A0));
      canvas.drawCircle(center, w * .12 * pulse,
          ui.Paint()..color = const ui.Color(0xFFFFD653));
    } else if (isDay &&
        !_storm &&
        !_rain &&
        !_fog &&
        const [0, 1, 2].contains(weatherCode)) {
      final sunSize = _winterWorld ? .07 : .10;
      final progress = _sunProgress ?? .8;
      // Arcs from the east at sunrise to the west at sunset, sitting low and
      // warm near the horizon and high and pale at noon.
      final centre = ui.Offset(
        w * (.14 + .72 * progress),
        h * (.18 + .24 * math.sin(progress * math.pi)),
      );
      final sun = _winterWorld
          ? const ui.Color(0xFFE5E8D8)
          : ui.Color.lerp(const ui.Color(0xFFFFB265),
              const ui.Color(0xFFFFF0A6), math.sin(progress * math.pi))!;
      _rect(canvas, centre.dx, centre.dy, w * sunSize, h * sunSize, sun);
      _rect(canvas, centre.dx + w * .02, centre.dy - h * .02,
          w * sunSize * .60, h * sunSize * 1.35, sun);
    } else if (!isDay &&
        !_storm &&
        !_rain &&
        !_fog &&
        !_sandstorm &&
        !_cyclone &&
        !_flood &&
        _cloudCoverage < 68) {
      // The moon runs the same arc as the sun, mirrored across the sky.
      final progress = _sunProgress ?? .2;
      final centre = ui.Offset(
        w * (.86 - .72 * progress),
        h * (.18 + .24 * math.sin(progress * math.pi)),
      );
      final moonSize = w * .075;
      canvas.drawCircle(centre + ui.Offset(moonSize / 2, moonSize / 2),
          moonSize / 2, ui.Paint()..color = const ui.Color(0xFFDDEBFF));
      // A bite out of one side keeps it reading as a moon, not a ball.
      canvas.drawCircle(centre + ui.Offset(moonSize * .84, moonSize * .30),
          moonSize * .32, ui.Paint()..color = _skyColor);
    }

    if (!_desertHeat && !_sandstorm) {
      final cloudTone = !isDay
          ? (_storm || _rain
              ? const ui.Color(0xFF26334A)
              : const ui.Color(0xFF485369))
          : _storm
              ? const ui.Color(0xFF26364E)
              : _overcast
                  ? const ui.Color(0xFF7B8990)
                  : _winterWorld
                      ? const ui.Color(0xFFD3E0E4)
                      : const ui.Color(0xFFD7EDF1);
      final cloudCount = (_cloudCoverage / 25).ceil().clamp(1, 4);
      for (var i = 0; i < cloudCount; i++) {
        final cloudWidth = w * (.19 + (i % 2) * .045);
        final direction = math.sin(windDirectionDeg * math.pi / 180);
        final drift = _elapsed *
            _environmentMotionScale *
            (4 + i * 1.8) *
            (direction >= 0 ? 1 : -1);
        final x =
            ((w * (.06 + i * .25) + drift) % (w + cloudWidth)) - cloudWidth;
        final y = h * (.13 + (i % 3) * .055);
        _cloud(canvas, x, y, cloudWidth, cloudTone);
      }
    }
    _drawAtmosphericDistance(canvas, w, h);
    _rect(canvas, 0, h * .57, w, h * .43, _groundColor);
    // The sea sits behind the near ground so coastal cities read as waterfronts.
    _drawHorizonWater(canvas, w, h);
    final groundEdge = !isDay
        ? (_winterWorld
            ? const ui.Color(0xFF718995)
            : location.isArid || _sandstorm
                ? const ui.Color(0xFF72513E)
                : const ui.Color(0xFF294A40))
        : (location.isArid || _sandstorm)
            ? const ui.Color(0xFFE9B65E)
            : _winterWorld
                ? const ui.Color(0xFFF2F6F1)
                : _autumnWorld
                    ? const ui.Color(0xFFAD8150)
                    : _winterSeason
                        ? const ui.Color(0xFF8B8172)
                        : const ui.Color(0xFF47765A);
    _rect(canvas, 0, h * .56, w, h * .035, groundEdge);
    _drawHorizon(canvas, w, h);
    _drawGroundPath(canvas, w, h);

    if (location.isArid || _sandstorm) {
      // Low dunes make arid terrain read as desert without inventing a landmark.
      final duneLip = ui.Path()
        ..moveTo(0, h * .76)
        ..quadraticBezierTo(w * .25, h * .69, w * .48, h * .75)
        ..quadraticBezierTo(w * .73, h * .80, w, h * .70)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(duneLip, ui.Paint()..color = const ui.Color(0xFFD99A54));
      for (var i = 0; i < 4; i++) {
        final tx = w * (.31 + i * .025);
        final ty = h * (.80 + (i % 2) * .025);
        _rect(canvas, tx, ty, w * .012, h * .008, const ui.Color(0xFF98613D));
        _rect(canvas, tx + w * .013, ty + h * .008, w * .012, h * .008,
            const ui.Color(0xFF98613D));
      }
    } else if (location.biome == WorldBiome.temperate ||
        location.biome == WorldBiome.tropical) {
      // Climate-aware tree line drawn at the mid-ground. Species, height and
      // colour come from the location's climate zone, so a Canadian city gets
      // pines while a Mediterranean city gets cypresses and a tropical city
      // gets palms.
      final seed = worldLocationSeed(location);
      final rng = math.Random(seed);
      final species = location.defaultTree;
      final treeCount = 7 + rng.nextInt(3);
      for (var i = 0; i < treeCount; i++) {
        final x = w * (i / treeCount) + (i.isEven ? 0 : w * .035);
        final treeW = w * (.13 + rng.nextDouble() * .04);
        final treeH = h * (.21 + rng.nextDouble() * .08);
        final sway = _windy
            ? math.sin(_elapsed * _environmentMotionScale * 3 +
                    i +
                    windDirectionDeg / 90) *
                w *
                (.006 + (_wind / 160).clamp(0.0, .06))
            : 0.0;
        _drawClimateTree(
          canvas,
          x + w * .06 + sway,
          h * .61,
          treeW,
          treeH,
          species,
          snowy: _winterWorld,
          autumn: _autumnWorld,
          spring: _springWorld,
        );
      }
    }

    // Mid-ground layer: terrain detail and the landmark slide together, and
    // further than the far horizon beneath them, which gives the wind depth.
    final midOffset = _parallaxMidOffset(w);
    canvas.save();
    canvas.translate(midOffset, 0);
    _drawTerrainDetails(canvas, w, h);
    if (!_flood) {
      paintBiomeGroundDetail(
        canvas,
        WorldDetailContext(
          w: w,
          h: h,
          seed: _detailSeed,
          biome: location.biome,
          arid: location.isArid || _sandstorm,
          winter: _winterWorld,
          storm: _storm,
          elapsed: _elapsed * _environmentMotionScale,
          zone: location.climate,
        ),
      );
    }
    
    if (debugHiddenLayers != DebugSceneLayers.withoutLandmark && debugHiddenLayers != DebugSceneLayers.withoutLandmarkAndCharacter) {
      if (location.landmark != WorldLandmark.none) {
        _drawCatalogLandmark(canvas, w, h);
      } else {
        _drawLocalMarker(canvas, w, h);
      }
    }
    canvas.restore();
    if (_rain) _drawWetGround(canvas, w, h);
    _drawFrostDetails(canvas, w, h);

    if (_cyclone) {
      _drawCyclone(canvas, w, h);
    } else if (_flood) {
      _drawFlood(canvas, w, h);
    } else if (_sandstorm) {
      _drawSandstorm(canvas, w, h);
    } else if (_rain &&
        !_hot &&
        !_winterWorld &&
        location.landmark == WorldLandmark.none &&
        location.biome == WorldBiome.temperate) {
      _drawRainyForest(canvas, w, h);
    }

    // Light the landscape as one layer, driven by the hour: a cool wash after
    // dusk and a warm cast at sunrise and sunset. Windows, lamps and the
    // character's lantern are drawn afterwards so they stay bright against it.
    final lightTint = _lightTint;
    if (lightTint.a > 0) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, h * .42, w, h * .58),
        ui.Paint()..color = lightTint,
      );
    }
    if (!isDay) {
      _drawNightLights(canvas, w, h);
    }
    _drawAmbientLife(canvas, w, h);

    _drawWeatherParticles(canvas, w, h);
    if (_live) _drawSeasonParticles(canvas, w, h);
    final floodProgress = _floodProgress;
    final x = w * _sceneX;
    final floor = _sceneFloor(h);
    _drawSunBeam(canvas, w, h, x, floor);
    final windAngle = math.cos(windDirectionDeg * math.pi / 180).sign;
    final lean = _cyclone
        ? .10 + .16 * (_wind / 160)
        : _sandstorm
            ? .22 * (windAngle == 0 ? 1 : windAngle)
            : _windy
                ? math.min(_wind / 160, .11) * (windAngle == 0 ? 1 : windAngle)
                : 0.0;
    if (debugHiddenLayers != DebugSceneLayers.withoutCharacter && debugHiddenLayers != DebugSceneLayers.withoutLandmarkAndCharacter) {
      canvas.save();
      canvas.translate(x, floor);
      final characterUnit = math.max(2.0, math.min(w, h) * .014).toDouble();
      if (_behavior.state == GoblinBehaviorState.play &&
          !reduceFlashing &&
          !reduceMotion) {
        canvas.translate(
            0,
            -math.sin(_behavior.actionProgress * math.pi) *
                characterUnit *
                1.2);
      }
      canvas.rotate(lean);
      if (_walkingLeft) canvas.scale(-1, 1);
      _drawGoblin(canvas, w, h, x: 0, floor: 0);
      canvas.restore();
    }
     _drawForeground(canvas, w, h);   // <-- add this
    if (_flood) _drawFloodAlert(canvas, w, h, floor, floodProgress);
    _drawLightning(canvas, w, h);
    // Short recovery vignette after a hit; no repeated strobing.
    if (_hitRecovery > 0 && _directHit) {
      final a = (_hitRecovery / 1.35 * 22).round().clamp(0, 22).toInt();
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h),
          ui.Paint()..color = ui.Color.fromARGB(a, 18, 22, 28));
    }

    if (_fog) {
      final visibility = visibilityM ?? 700;
      final alpha = (18 + (1800 - visibility).clamp(0, 1500) / 50)
          .round()
          .clamp(18, 48)
          .toInt();
      final mist = ui.Color.fromARGB(alpha, 179, 202, 207);
      _rect(canvas, 0, h * .24, w, h * .10, mist.withValues(alpha: .28));
      _rect(canvas, 0, h * .50, w, h * .10, mist.withValues(alpha: .42));
      _rect(canvas, 0, h * .76, w, h * .07, mist.withValues(alpha: .34));
    }
    _drawSpeechBubble(canvas, w, h);
    // A small pixel prompt makes the scene discoverable and testable.
    if (_thunderstorm) {
      _rect(canvas, w * .34, h * .91, w * .43, h * .045,
          const ui.Color(0xAA0A1B2B));
      final promptPaint = ui.Paint()..color = const ui.Color(0xFFEAF7FF);
      // Tiny pixel glyph-like marks instead of a font dependency inside Flame.
      for (var i = 0; i < 10; i++) {
        _rect(canvas, w * .385 + i * w * .018, h * .925, w * .009, h * .012,
            i == 0 ? const ui.Color(0xFFFFC857) : promptPaint.color);
      }
    }
  }

  void _drawNightLights(ui.Canvas canvas, double w, double h) {
    if (isDay) return;
    final settlement = location.biome == WorldBiome.urban ||
        location.biome == WorldBiome.temperate ||
        location.biome == WorldBiome.tropical ||
        location.biome == WorldBiome.river ||
        location.biome == WorldBiome.coastal ||
        location.biome == WorldBiome.mountain ||
        location.landmark == WorldLandmark.jaisalmerFort;
    if (!settlement) return;
    final lamp = ui.Paint()..color = const ui.Color(0xFFFFCF75);
    final glow = ui.Paint()..color = const ui.Color(0x55FFB94D);
    for (var i = 0; i < 3; i++) {
      final x = w * (.14 + i * .34);
      final y = h * (.51 + (i.isOdd ? .035 : 0));
      canvas.drawCircle(ui.Offset(x, y), math.max(2.0, w * .012), glow);
      _rect(canvas, x - w * .006, y - h * .006, w * .012, h * .014, lamp.color);
    }
  }

  void _drawAmbientLife(ui.Canvas canvas, double w, double h) {
    if (_ambientCreatures.isEmpty) return;
    final unit = math.max(2.0, math.min(w, h) * .009).toDouble();
    final motion = reduceMotion ? 0.0 : 1.0;
    for (final creature in _ambientCreatures) {
      if (!creature.visible) continue;
      final age = creature.age;
      final progress = (age / creature.duration).clamp(0.0, 1.0);
      final travel = creature.kind == _AmbientKind.bird ||
              creature.kind == _AmbientKind.owl
          ? creature.direction * progress * .30 * motion
          : math.sin(
                  age * (creature.kind == _AmbientKind.butterfly ? 2.1 : 1.3)) *
              .025 *
              motion;
      final x = (creature.x + travel) % 1.0 * w;
      final bob = math.sin(age * 4.2) * .012 * motion;
      final y = h * (creature.y + bob);
      switch (creature.kind) {
        case _AmbientKind.bird:
          final wing = motion == 0 ? 0.0 : math.sin(age * 9) * unit;
          final paint = ui.Paint()
            ..color = const ui.Color(0xFF263C4C)
            ..strokeWidth = math.max(1.2, unit * .38)
            ..strokeCap = ui.StrokeCap.square;
          canvas.drawLine(
              ui.Offset(x - unit * 1.8, y + wing), ui.Offset(x, y), paint);
          canvas.drawLine(
              ui.Offset(x, y), ui.Offset(x + unit * 1.8, y - wing), paint);
        case _AmbientKind.butterfly:
          final flutter =
              motion == 0 ? .8 : .45 + .35 * math.sin(age * 8).abs();
          final wing = ui.Paint()
            ..color = const ui.Color(0xFFE9A6D2).withValues(alpha: flutter);
          canvas.drawCircle(ui.Offset(x - unit, y), unit * .8, wing);
          canvas.drawCircle(ui.Offset(x + unit, y), unit * .8, wing);
          _rect(canvas, x - unit * .18, y - unit * .5, unit * .36, unit,
              const ui.Color(0xFF594857));
        case _AmbientKind.frog:
          final hop =
              motion == 0 ? 0.0 : math.sin(age * 3.6).abs() * unit * 1.6;
          final frogY = y - hop;
          _rect(canvas, x - unit * 1.5, frogY, unit * 3, unit * 1.7,
              const ui.Color(0xFF5A9B55));
          _rect(canvas, x - unit, frogY - unit * .7, unit * .7, unit * .7,
              const ui.Color(0xFFE6E78B));
          _rect(canvas, x + unit * .3, frogY - unit * .7, unit * .7, unit * .7,
              const ui.Color(0xFFE6E78B));
          _rect(canvas, x - unit * 1.4, frogY + unit * 1.3, unit, unit * .5,
              const ui.Color(0xFF3E7045));
          _rect(canvas, x + unit * .5, frogY + unit * 1.3, unit, unit * .5,
              const ui.Color(0xFF3E7045));
        case _AmbientKind.firefly:
          final pulse = reduceFlashing
              ? .55
              : .35 + .35 * (.5 + .5 * math.sin(age * 2.2));
          final radius = unit * (1.1 + pulse);
          canvas.drawCircle(
              ui.Offset(x, y),
              radius * 2.0,
              ui.Paint()
                ..color = const ui.Color(0x40FFE58A).withValues(alpha: pulse));
          _rect(canvas, x - unit * .3, y - unit * .3, unit * .6, unit * .6,
              const ui.Color(0xFFFFE58A));
        case _AmbientKind.owl:
          final owl = const ui.Color(0xFF29323C);
          _rect(canvas, x - unit * 1.5, y, unit * 3, unit * 2.2, owl);
          _rect(canvas, x - unit, y - unit * .6, unit, unit, owl);
          _rect(canvas, x + unit * .2, y - unit * .6, unit, unit, owl);
          _rect(canvas, x - unit * .8, y + unit * .5, unit * .5, unit * .5,
              const ui.Color(0xFFFFDA82));
          _rect(canvas, x + unit * .3, y + unit * .5, unit * .5, unit * .5,
              const ui.Color(0xFFFFDA82));
        case _AmbientKind.cricket:
          final cricket = ui.Paint()
            ..color = const ui.Color(0xFFA6BB69)
            ..strokeWidth = math.max(1.0, unit * .25);
          canvas.drawLine(ui.Offset(x - unit, y),
              ui.Offset(x + unit, y - unit * .25), cricket);
          canvas.drawLine(ui.Offset(x, y),
              ui.Offset(x + unit * .6, y + unit * .8), cricket);
          canvas.drawLine(ui.Offset(x, y),
              ui.Offset(x - unit * .5, y + unit * .7), cricket);
      }
    }
  }

  void _drawFrostDetails(ui.Canvas canvas, double w, double h) {
    if (!_cold || _snow || temperatureC > 0) return;
    final frost = const ui.Color(0x887FABB7);
    for (var i = 0; i < 8; i++) {
      final x = w * (.05 + (i * 13 % 91) / 100);
      final y = h * (.655 + (i * 7 % 8) / 100);
      _rect(canvas, x, y, w * .022, h * .006, frost);
    }
  }

  void _drawSunBeam(
      ui.Canvas canvas, double w, double h, double goblinX, double floor) {
    if (!_sunBeamActive) return;
    final phase = .5 + .5 * math.sin(_elapsed * 2.1);
    // The beam leaves from wherever the sun is drawn, so light and source agree.
    final progress = _sunProgress ?? .85;
    final topX = w * (.14 + .72 * progress);
    final topY = h * (.30 + .24 * math.sin(progress * math.pi));
    final targetY = floor - h * .20;
    final spread = w * (.022 + .006 * phase);
    final beam = ui.Path()
      ..moveTo(topX - w * .038, topY)
      ..lineTo(topX + w * .038, topY)
      ..lineTo(goblinX + spread, targetY)
      ..lineTo(goblinX - spread, targetY)
      ..close();
    canvas.drawPath(
      beam,
      ui.Paint()
        ..color = ui.Color.fromARGB((25 + phase * 18).round(), 255, 222, 127),
    );
    canvas.drawLine(
      ui.Offset(topX, topY),
      ui.Offset(goblinX, targetY),
      ui.Paint()
        ..color = ui.Color.fromARGB((68 + phase * 48).round(), 255, 231, 160)
        ..strokeWidth = math.max(1.5, w * .006),
    );
    canvas.drawCircle(
      ui.Offset(goblinX, targetY),
      w * (.028 + .005 * phase),
      ui.Paint()..color = const ui.Color(0x33FFD166),
    );
  }

  void _drawSpeechBubble(ui.Canvas canvas, double w, double h) {
    final message = _dialogue;
    if (message == null || _dialogueAge <= 0) return;

    final unit = math.max(2.0, math.min(w, h) * .014).toDouble();
    final fontSize = (w * .033).clamp(10.0, 15.0).toDouble();
    // With a landmark present the bubble shares the right-hand lane with the
    // character, so it is laid out narrower and allowed an extra line rather than
    // overflowing the frame edge.
    final hasLandmark = location.landmark != WorldLandmark.none;
    final painter = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          color: const ui.Color(0xFF26343A),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: hasLandmark ? 4 : 3,
    )..layout(maxWidth: w * (hasLandmark ? .40 : .50));

    const horizontalPadding = 9.0;
    const verticalPadding = 7.0;
    final bubbleWidth = painter.width + horizontalPadding * 2;
    final bubbleHeight = painter.height + verticalPadding * 2;
    final goblinX = w * _sceneX;
    final floor = _sceneFloor(h);
    // The character keeps to the right-hand lane once a landmark is present, so
    // the bubble is pushed with it. A centred bubble would sit over the landmark
    // it just stopped covering.
    final rightLimit = w - bubbleWidth - 5;
    final left = hasLandmark
        ? (goblinX - bubbleWidth * .28).clamp(w * .46, rightLimit).toDouble()
        : (goblinX - bubbleWidth / 2).clamp(5.0, rightLimit);
    final top = (floor - unit * 30 - bubbleHeight - unit * 2)
        .clamp(6.0, h - bubbleHeight - 6);
    final bubble = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(left, top, bubbleWidth, bubbleHeight),
      const ui.Radius.circular(5),
    );
    canvas.drawRRect(
      bubble.shift(const ui.Offset(0, 3)),
      ui.Paint()..color = const ui.Color(0x99071219),
    );
    canvas.drawRRect(bubble, ui.Paint()..color = const ui.Color(0xFFF0DFB8));
    canvas.drawRRect(
      bubble,
      ui.Paint()
        ..color = const ui.Color(0xFF534335)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final tail = ui.Path()
      ..moveTo(goblinX - unit * 1.8, top + bubbleHeight - 1)
      ..lineTo(goblinX, top + bubbleHeight + unit * 2.2)
      ..lineTo(goblinX + unit * 1.8, top + bubbleHeight - 1)
      ..close();
    canvas.drawPath(tail, ui.Paint()..color = const ui.Color(0xFFF0DFB8));
    canvas.drawLine(
      ui.Offset(goblinX - unit * 1.8, top + bubbleHeight - .5),
      ui.Offset(goblinX, top + bubbleHeight + unit * 2.2),
      ui.Paint()
        ..color = const ui.Color(0xFF534335)
        ..strokeWidth = 1.3,
    );
    canvas.drawLine(
      ui.Offset(goblinX, top + bubbleHeight + unit * 2.2),
      ui.Offset(goblinX + unit * 1.8, top + bubbleHeight - .5),
      ui.Paint()
        ..color = const ui.Color(0xFF534335)
        ..strokeWidth = 1.3,
    );
    painter.paint(
      canvas,
      ui.Offset(left + horizontalPadding, top + verticalPadding),
    );
  }

  void _drawPixelTree(ui.Canvas canvas, double centerX, double baseY,
      double width, double height, ui.Color foliage, bool snow) {
    final trunkW = width * .13;
    _rect(canvas, centerX - trunkW / 2, baseY - height * .34, trunkW,
        height * .34, const ui.Color(0xFF493326));
    if (snow || weatherCode == 71 || weatherCode == 73) {
      final pine = ui.Path()
        ..moveTo(centerX, baseY - height)
        ..lineTo(centerX - width * .27, baseY - height * .67)
        ..lineTo(centerX - width * .15, baseY - height * .67)
        ..lineTo(centerX - width * .40, baseY - height * .38)
        ..lineTo(centerX - width * .20, baseY - height * .38)
        ..lineTo(centerX - width * .48, baseY - height * .10)
        ..lineTo(centerX + width * .48, baseY - height * .10)
        ..lineTo(centerX + width * .20, baseY - height * .38)
        ..lineTo(centerX + width * .40, baseY - height * .38)
        ..lineTo(centerX + width * .15, baseY - height * .67)
        ..lineTo(centerX + width * .27, baseY - height * .67)
        ..close();
      canvas.drawPath(pine, ui.Paint()..color = foliage);
      final litSide = ui.Path()
        ..moveTo(centerX, baseY - height)
        ..lineTo(centerX - width * .27, baseY - height * .67)
        ..lineTo(centerX - width * .15, baseY - height * .67)
        ..lineTo(centerX - width * .40, baseY - height * .38)
        ..lineTo(centerX - width * .20, baseY - height * .38)
        ..lineTo(centerX - width * .48, baseY - height * .10)
        ..lineTo(centerX, baseY - height * .10)
        ..close();
      canvas.drawPath(litSide, ui.Paint()..color = const ui.Color(0x334EBB9C));
      if (snow) {
        for (var tier = 0; tier < 3; tier++) {
          final y = baseY - height * (.68 - tier * .25);
          _rect(
              canvas,
              centerX - width * (.22 + tier * .08),
              y,
              width * (.44 + tier * .16),
              height * .035,
              const ui.Color(0xFFEAF7FA));
        }
      }
    } else if (_winterSeason) {
      final branches = ui.Paint()
        ..color = const ui.Color(0xFF554239)
        ..strokeWidth = width * .055
        ..strokeCap = ui.StrokeCap.square;
      final crownY = baseY - height * .73;
      canvas.drawLine(ui.Offset(centerX, baseY - height * .34),
          ui.Offset(centerX, crownY), branches);
      for (var branch = 0; branch < 4; branch++) {
        final y = baseY - height * (.42 + branch * .11);
        final side = branch.isEven ? -1.0 : 1.0;
        canvas.drawLine(
            ui.Offset(centerX, y),
            ui.Offset(centerX + side * width * .34, y - height * .12),
            branches);
        canvas.drawLine(
            ui.Offset(centerX + side * width * .34, y - height * .12),
            ui.Offset(centerX + side * width * .46, y - height * .20),
            branches);
      }
    } else {
      // Chunky canopy tiers make the tree silhouette read at scene scale.
      final highlight = _autumnWorld
          ? const ui.Color(0xFFD28B46)
          : _springWorld
              ? const ui.Color(0xFF70A85B)
              : const ui.Color(0xFF347451);
      for (var tier = 0; tier < 3; tier++) {
        final tierWidth = width * (1 - tier * .23);
        final y = baseY - height * (.40 + tier * .25);
        _rect(canvas, centerX - tierWidth * .42, y, tierWidth * .84,
            height * .25, foliage);
        _rect(canvas, centerX - tierWidth * .29, y - height * .09,
            tierWidth * .58, height * .13, highlight);
        _rect(
            canvas,
            centerX - tierWidth * .30,
            y,
            tierWidth * .20,
            height * .035,
            _autumnWorld
                ? const ui.Color(0x44FFD184)
                : const ui.Color(0x446FC878));
      }
      _rect(canvas, centerX - width * .42, baseY - height * .15, width * .84,
          height * .035, const ui.Color(0xFF193F35));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Climate-aware tree drawing
  // ───────────────────────────────────────────────────────────────────────────

  /// Dispatches to the right tree silhouette for a climate zone. Different
  /// zones produce visibly different vegetation so two temperate towns do not
  /// render identically.
  void _drawClimateTree(
    ui.Canvas canvas,
    double centerX,
    double baseY,
    double width,
    double height,
    TreeSpecies species, {
    bool snowy = false,
    bool autumn = false,
    bool spring = false,
  }) {
    switch (species) {
      case TreeSpecies.broadleaf:
        _drawPixelTree(canvas, centerX, baseY, width, height,
            autumn
                ? const ui.Color(0xFF9A5735)
                : spring
                    ? const ui.Color(0xFF286F4E)
                    : const ui.Color(0xFF245B3F),
            snowy);
      case TreeSpecies.pine:
        _drawPixelTree(canvas, centerX, baseY, width, height,
            snowy ? const ui.Color(0xFF547F91) : const ui.Color(0xFF245239),
            true);
      case TreeSpecies.palm:
        _drawPalm(canvas, centerX, baseY, width, height);
      case TreeSpecies.cypress:
        _drawCypress(canvas, centerX, baseY, width, height);
      case TreeSpecies.cactus:
        _drawCactus(canvas, centerX, baseY, width, height);
      case TreeSpecies.shrub:
        _drawShrub(canvas, centerX, baseY, width, height, snowy);
      case TreeSpecies.baobab:
        _drawBaobab(canvas, centerX, baseY, width, height);
    }
  }

  void _drawPalm(ui.Canvas canvas, double centerX, double baseY,
      double width, double height) {
    const trunk = ui.Color(0xFF6B4930);
    const trunkDark = ui.Color(0xFF4C3421);
    const frond = ui.Color(0xFF1F6B3A);
    const frondLit = ui.Color(0xFF3E9256);

    final trunkW = math.max(1.5, width * 0.075);
    final trunkTop = baseY - height * 0.72;
    // Slight curve so palms don't read as fence posts.
    final curve = width * 0.10;

    final trunkPath = ui.Path()
      ..moveTo(centerX - trunkW / 2, baseY)
      ..lineTo(centerX - trunkW / 2 + curve, trunkTop)
      ..lineTo(centerX + trunkW / 2 + curve, trunkTop)
      ..lineTo(centerX + trunkW / 2, baseY)
      ..close();
    canvas.drawPath(trunkPath, ui.Paint()..color = trunk);

    // Trunk rings.
    for (var i = 1; i < 5; i++) {
      final t = i / 5;
      final y = baseY - height * 0.72 * t;
      final xOff = curve * t;
      _rect(canvas, centerX - trunkW * 0.7 + xOff, y, trunkW * 1.4,
          height * 0.018, trunkDark);
    }

    final topX = centerX + curve;
    // Six fronds radiating up and out.
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + (i - 2.5) * 0.42;
      final frondLen = width * (0.55 + (i % 2) * 0.12);
      final endX = topX + math.cos(angle) * frondLen;
      final endY = trunkTop + math.sin(angle) * frondLen * 0.55;
      canvas.drawLine(
        ui.Offset(topX, trunkTop),
        ui.Offset(endX, endY),
        ui.Paint()
          ..color = frond
          ..strokeWidth = math.max(1.5, width * 0.065),
      );
      canvas.drawLine(
        ui.Offset(topX, trunkTop - height * 0.01),
        ui.Offset(endX - width * 0.02, endY + height * 0.01),
        ui.Paint()
          ..color = frondLit
          ..strokeWidth = math.max(1.0, width * 0.038),
      );
    }

    // Coconuts at the crown.
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(
        ui.Offset(topX + i * width * 0.05, trunkTop + height * 0.025),
        math.max(1.0, width * 0.028),
        ui.Paint()..color = trunkDark,
      );
    }
  }

  void _drawCypress(ui.Canvas canvas, double centerX, double baseY,
      double width, double height) {
    const body = ui.Color(0xFF2C5340);
    const highlight = ui.Color(0xFF467058);

    final treeW = math.max(3.0, width * 0.24);
    // Narrow column, tapering to a point.
    final path = ui.Path()
      ..moveTo(centerX, baseY - height)
      ..lineTo(centerX - treeW * 0.5, baseY - height * 0.30)
      ..lineTo(centerX - treeW * 0.5, baseY - height * 0.06)
      ..lineTo(centerX + treeW * 0.5, baseY - height * 0.06)
      ..lineTo(centerX + treeW * 0.5, baseY - height * 0.30)
      ..close();
    canvas.drawPath(path, ui.Paint()..color = body);

    // Sun-side highlight.
    final lit = ui.Path()
      ..moveTo(centerX, baseY - height)
      ..lineTo(centerX - treeW * 0.5, baseY - height * 0.30)
      ..lineTo(centerX - treeW * 0.5, baseY - height * 0.06)
      ..lineTo(centerX - treeW * 0.15, baseY - height * 0.06)
      ..lineTo(centerX - treeW * 0.15, baseY - height * 0.30)
      ..close();
    canvas.drawPath(lit, ui.Paint()..color = highlight);

    // Tiny trunk.
    _rect(canvas, centerX - width * 0.03, baseY - height * 0.08,
        width * 0.06, height * 0.08, const ui.Color(0xFF4A3222));
  }

  void _drawCactus(ui.Canvas canvas, double centerX, double baseY,
      double width, double height) {
    const body = ui.Color(0xFF3E7C4B);
    const ridge = ui.Color(0xFF67A56F);

    final trunkW = math.max(2.0, width * 0.16);
    // Main column.
    _rect(canvas, centerX - trunkW / 2, baseY - height, trunkW, height, body);

    // Two arms, one on each side.
    final armY1 = baseY - height * 0.55;
    final armY2 = baseY - height * 0.40;
    _rect(canvas, centerX - width * 0.24, armY1 + height * 0.20,
        trunkW * 0.75, height * 0.20, body);
    _rect(canvas, centerX - width * 0.24, armY1, width * 0.09,
        height * 0.25, body);
    _rect(canvas, centerX + width * 0.15, armY2 + height * 0.15,
        trunkW * 0.75, height * 0.18, body);
    _rect(canvas, centerX + width * 0.15, armY2, width * 0.09,
        height * 0.20, body);

    // Ribs.
    for (var i = 0; i < 3; i++) {
      final rx = centerX - trunkW * 0.5 + (i + 1) * trunkW / 4;
      _rect(canvas, rx, baseY - height, math.max(1.0, trunkW * 0.10),
          height, ridge);
    }
  }

  void _drawShrub(ui.Canvas canvas, double centerX, double baseY,
      double width, double height, bool snowy) {
    final tone = snowy ? const ui.Color(0xFF5E6E68) : const ui.Color(0xFF3D6B45);
    final lit = snowy
        ? const ui.Color(0xFF96A6A0)
        : const ui.Color(0xFF61986A);
    final shrubW = width * 0.55;
    final shrubH = height * 0.42;
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(centerX, baseY - shrubH * 0.5),
        width: shrubW,
        height: shrubH,
      ),
      ui.Paint()..color = tone,
    );
    // Two lighter bumps on top for texture.
    for (var i = -1; i <= 1; i += 2) {
      canvas.drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset(centerX + i * shrubW * 0.22,
              baseY - shrubH * 0.75),
          width: shrubW * 0.34,
          height: shrubH * 0.45,
        ),
        ui.Paint()..color = lit,
      );
    }
  }

  void _drawBaobab(ui.Canvas canvas, double centerX, double baseY,
      double width, double height) {
    const trunk = ui.Color(0xFF7A5638);
    const trunkDark = ui.Color(0xFF5B3E28);
    const canopy = ui.Color(0xFF3F6D3A);

    // Very fat trunk that tapers into a bulge.
    final trunkW = width * 0.32;
    final path = ui.Path()
      ..moveTo(centerX - trunkW * 0.5, baseY)
      ..lineTo(centerX - trunkW * 0.35, baseY - height * 0.65)
      ..lineTo(centerX + trunkW * 0.35, baseY - height * 0.65)
      ..lineTo(centerX + trunkW * 0.5, baseY)
      ..close();
    canvas.drawPath(path, ui.Paint()..color = trunk);
    // A rounded bulge around waist height.
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(centerX, baseY - height * 0.42),
        width: trunkW * 1.15,
        height: height * 0.30,
      ),
      ui.Paint()..color = trunk,
    );
    // Bark line.
    _rect(canvas, centerX - trunkW * 0.04, baseY - height * 0.65,
        trunkW * 0.08, height * 0.65, trunkDark);

    // Wide, sparse, flat canopy.
    final canopyW = width * 0.95;
    final canopyH = height * 0.28;
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(centerX, baseY - height * 0.78),
        width: canopyW,
        height: canopyH,
      ),
      ui.Paint()..color = canopy,
    );
    // Leaf clusters around the canopy edge, sparse enough to read as baobab.
    for (var i = 0; i < 7; i++) {
      final angle = i * math.pi * 2 / 7;
      final cx = centerX + math.cos(angle) * canopyW * 0.42;
      final cy = baseY - height * 0.78 + math.sin(angle) * canopyH * 0.35;
      canvas.drawCircle(
          ui.Offset(cx, cy), math.max(1.2, width * 0.045),
          ui.Paint()..color = canopy);
    }
  }

  void _drawSeasonParticles(ui.Canvas canvas, double w, double h) {
    if (_autumnWorld) {
      for (var i = 0; i < 15; i++) {
        final drift =
            math.sin(_elapsed * _environmentMotionScale * 1.4 + i) * w * .025;
        final x = (w * ((i * 29 % 97) / 100) +
                drift +
                _elapsed * _environmentMotionScale * (8 + i % 3 * 3)) %
            w;
        final y = (h * ((i * 17 % 48) / 100) +
                _elapsed * _environmentMotionScale * (12 + i % 4 * 3)) %
            (h * .58);
        final leaf = ui.Path()
          ..moveTo(x, y)
          ..lineTo(x + w * .014, y + h * .006)
          ..lineTo(x + w * .008, y + h * .018)
          ..lineTo(x - w * .006, y + h * .010)
          ..close();
        canvas.drawPath(
            leaf,
            ui.Paint()
              ..color = i.isEven
                  ? const ui.Color(0xFFE0A04A)
                  : const ui.Color(0xFFB95F36));
      }
    } else if (_springWorld) {
      for (var i = 0; i < 10; i++) {
        final x = (w * ((i * 31 % 96) / 100) +
                math.sin(_elapsed * _environmentMotionScale * 1.8 + i) *
                    w *
                    .035 +
                _elapsed * _environmentMotionScale * 5) %
            w;
        final y = (h * ((i * 13 % 44) / 100) +
                _elapsed * _environmentMotionScale * 9) %
            (h * .57);
        final petal =
            i.isEven ? const ui.Color(0xFFFFD3DF) : const ui.Color(0xFFFFF0BD);
        _rect(canvas, x, y, w * .012, h * .009, petal);
        _rect(canvas, x + w * .005, y - h * .004, w * .007, h * .008, petal);
      }
    }
  }

    /// Foreground plane: grass tufts, rocks, and small debris drawn in front of
  /// everything else and moving fastest with wind. This is what turns the
  /// scene from a diorama into a place with depth.
  void _drawForeground(ui.Canvas canvas, double w, double h) {
    final unit = math.max(2.0, math.min(w, h) * .020).toDouble();
    final seed = worldLocationSeed(location);
    final rng = math.Random(seed ^ 0x5AF3);
    // Foreground moves more than mid-ground: the closest layer swings widest
    // when wind blows. Same formula, bigger scale.
    final wind = (_wind / 160).clamp(0.0, 1.0).toDouble();
    final bearing = math.cos(windDirectionDeg * math.pi / 180);
    final direction = bearing == 0 ? 1.0 : bearing.sign;
    final swayBase = w * .05 * wind * direction * _environmentMotionScale;
    final baseY = h * .955;

    // Short grass tufts across the bottom edge. Density varies by biome so
    // a desert gets sparse tufts and a plains city gets a full band.
    final density = switch (location.biome) {
      WorldBiome.desert || WorldBiome.coldDesert => 6,
      WorldBiome.coastal => 10,
      WorldBiome.urban => 5,
      _ => 14,
    };
    final grassCount = density + rng.nextInt(4);
    final tuftColour = _foregroundGrassColour;

    for (var i = 0; i < grassCount; i++) {
      final baseX = w * (i + rng.nextDouble() * .5) / grassCount;
      final height = unit * (2.2 + rng.nextDouble() * 2.6);
      final sway = math.sin(_elapsed * 2.4 + i * .7) * unit * .35 +
          swayBase * (.4 + rng.nextDouble() * .4);
      final x = baseX + sway;
      // Each tuft is three vertical blades at slightly different angles.
      _rect(canvas, x - unit * .18, baseY - height, unit * .35, height,
          tuftColour);
      _rect(canvas, x + unit * .30, baseY - height * .78, unit * .32,
          height * .78, tuftColour);
      _rect(canvas, x - unit * .55, baseY - height * .55, unit * .30,
          height * .55, tuftColour);
    }

    // A few small rocks sitting just inside the bottom edge. They anchor the
    // foreground without blocking the character's feet.
    final rockCount = 2 + rng.nextInt(3);
    final rockColour = _foregroundRockColour;
    for (var i = 0; i < rockCount; i++) {
      final x = w * (.06 + rng.nextDouble() * .88);
      final y = baseY + unit * rng.nextDouble() * .9;
      final rw = unit * (1.6 + rng.nextDouble() * 1.4);
      final rh = rw * (.55 + rng.nextDouble() * .35);
      // Rock is a flattened oval with a highlight sliver on the sun side.
      canvas.drawOval(
        ui.Rect.fromLTWH(x - rw / 2, y - rh, rw, rh),
        ui.Paint()..color = rockColour,
      );
      _rect(canvas, x - rw * .35, y - rh * 1.05, rw * .4, rh * .18,
          rockColour.withAlpha(200));
    }

    // One larger silhouette in the corner — a fallen branch, a leaf, or a
    // piece of debris. Rotates by biome so each region has its own character.
    final cornerX = rng.nextBool() ? w * .04 : w * .96;
    final cornerDir = cornerX < w * .5 ? 1.0 : -1.0;
    _drawForegroundCornerProp(canvas, cornerX, baseY, unit, cornerDir, rng);
  }

  ui.Color get _foregroundGrassColour {
    if (_winterWorld) return const ui.Color(0xFF26474A);
    if (_autumnWorld) return const ui.Color(0xFF4A2E1C);
    if (_hot) return const ui.Color(0xFF6B4A24);
    if (_storm || _rain) return const ui.Color(0xFF15262A);
    if (isDay) return const ui.Color(0xFF1B3A26);
    return const ui.Color(0xFF16261E);
  }

  ui.Color get _foregroundRockColour {
    if (_winterWorld) return const ui.Color(0xFF3E4F55);
    if (_hot) return const ui.Color(0xFF6E4A28);
    if (isDay) return const ui.Color(0xFF3A3228);
    return const ui.Color(0xFF23201A);
  }

  /// A single large prop in the very front corner of the frame. Reads as
  /// "the camera is standing right next to this."
  void _drawForegroundCornerProp(ui.Canvas canvas, double x, double baseY,
      double unit, double direction, math.Random rng) {
    final kind = rng.nextInt(3);
    final colour = _foregroundGrassColour;
    switch (kind) {
      case 0:
        // Fallen branch lying across the corner.
        final length = unit * (8 + rng.nextDouble() * 4);
        final tilt = direction * .18;
        canvas.save();
        canvas.translate(x, baseY + unit * 1.5);
        canvas.rotate(tilt);
        _rect(canvas, -length * .5, -unit * .5, length, unit, colour);
        // A couple of small twigs branching off.
        _rect(canvas, length * .1, -unit * 1.2, unit * .4, unit * .8, colour);
        _rect(canvas, length * .28, -unit * 1.4, unit * .35, unit * 1.1,
            colour);
        canvas.restore();
      case 1:
        // Large leaf.
        final w0 = unit * (5 + rng.nextDouble() * 3);
        final h0 = w0 * .5;
        canvas.save();
        canvas.translate(x, baseY);
        canvas.rotate(direction * .3);
        canvas.drawOval(
          ui.Rect.fromLTWH(-w0 * .5, -h0 * .5, w0, h0),
          ui.Paint()..color = colour,
        );
        // Central vein.
        _rect(canvas, -w0 * .45, -unit * .08, w0 * .9, unit * .16,
            colour.withAlpha(140));
        canvas.restore();
      case 2:
        // Small clump of taller grass, denser than the tufts above.
        for (var i = 0; i < 6; i++) {
          final gx = x + (rng.nextDouble() - .5) * unit * 3.5;
          final gh = unit * (3 + rng.nextDouble() * 3);
          _rect(canvas, gx, baseY - gh, unit * .45, gh, colour);
        }
    }
  }


  // ───────────────────────────────────────────────────────────────────────────
  // Local Markers
  // ───────────────────────────────────────────────────────────────────────────

  /// Draws the current city's local marker, if any, plus its small name tag.
  void _drawLocalMarker(ui.Canvas canvas, double w, double h) {
    final marker = _localMarker;
    if (marker == null) return;
    final x = w * _markerLaneX;
    final y = _sceneFloor(h);
    final u = math.max(1.5, math.min(w, h) * .009).toDouble();

    switch (marker.kind) {
      case LocalMarkerKind.jhumkaShop:
        _drawJhumkaShop(canvas, x, y, u);
      case LocalMarkerKind.brasswareShop:
        _drawBrasswareShop(canvas, x, y, u);
      case LocalMarkerKind.lockShop:
        _drawLockShop(canvas, x, y, u);
      case LocalMarkerKind.bangleStall:
        _drawBangleStall(canvas, x, y, u);
      case LocalMarkerKind.chikanStall:
        _drawChikanStall(canvas, x, y, u);
      case LocalMarkerKind.pethaShop:
        _drawPethaShop(canvas, x, y, u);
      case LocalMarkerKind.littiChokha:
        _drawLittiChokha(canvas, x, y, u);
      case LocalMarkerKind.pohaJalebiCart:
        _drawPohaJalebiCart(canvas, x, y, u);
      case LocalMarkerKind.orangeBasket:
        _drawOrangeBasket(canvas, x, y, u);
      case LocalMarkerKind.biryaniPot:
        _drawBiryaniPot(canvas, x, y, u);
      case LocalMarkerKind.rosogollaStall:
        _drawRosogollaStall(canvas, x, y, u);
      case LocalMarkerKind.filterCoffeeStand:
        _drawFilterCoffeeStand(canvas, x, y, u);
      case LocalMarkerKind.diyaCluster:
        _drawDiyaCluster(canvas, x, y, u);
      case LocalMarkerKind.kathputliPuppet:
        _drawKathputliPuppet(canvas, x, y, u);
      case LocalMarkerKind.vadaPavCart:
        _drawVadaPavCart(canvas, x, y, u);
      case LocalMarkerKind.tramStop:
        _drawTramStop(canvas, x, y, u);
      case LocalMarkerKind.chaiStall:
        _drawChaiStall(canvas, x, y, u);
      case LocalMarkerKind.cafeTable:
        _drawCafeTable(canvas, x, y, u);
      case LocalMarkerKind.vendingMachine:
        _drawVendingMachine(canvas, x, y, u);
      case LocalMarkerKind.phoneBox:
        _drawPhoneBox(canvas, x, y, u);
      case LocalMarkerKind.hotDogCart:
        _drawHotDogCart(canvas, x, y, u);
      case LocalMarkerKind.scooter:
        _drawScooter(canvas, x, y, u);
      case LocalMarkerKind.hawkerStall:
        _drawHawkerStall(canvas, x, y, u);
    }
  }

  // ── Indian markers ────────────────────────────────────────────────────────

  /// Small shop front hung with jhumkas. The Bareilly signature.
  void _drawJhumkaShop(ui.Canvas canvas, double x, double y, double u) {
    const wood = ui.Color(0xFF7A5638);
    const woodDark = ui.Color(0xFF4C3421);
    const cloth = ui.Color(0xFFB0413A);
    const gold = ui.Color(0xFFE4B54D);
    const goldDark = ui.Color(0xFF9D7A28);
    // Booth back and roof.
    _rect(canvas, x - u * 9, y - u * 16, u * 18, u * 16, wood);
    _rect(canvas, x - u * 11, y - u * 18, u * 22, u * 3, woodDark);
    _rect(canvas, x - u * 11, y - u * 15, u * 22, u * 1.2, cloth);
    // Hanging rack.
    _rect(canvas, x - u * 7, y - u * 14, u * 14, u * .5, woodDark);
    // Three jhumkas: dome, ring, and three beads, descending sizes.
    for (var i = -1; i <= 1; i++) {
      final jx = x + i * u * 5;
      final jy = y - u * 13;
      // Hook line.
      _rect(canvas, jx - u * .12, jy, u * .25, u * 1.5, goldDark);
      // Bell.
      canvas.drawArc(
        ui.Rect.fromLTWH(jx - u * 1.4, jy + u * 1.5, u * 2.8, u * 2.4),
        0,
        math.pi,
        true,
        ui.Paint()..color = gold,
      );
      _rect(canvas, jx - u * 1.4, jy + u * 1.6, u * 2.8, u * .35, goldDark);
      // Beads.
      for (var b = 0; b < 3; b++) {
        canvas.drawCircle(
          ui.Offset(jx - u * .7 + b * u * .7, jy + u * 4.4),
          u * .28,
          ui.Paint()..color = gold,
        );
      }
      // Small sway highlight.
      _rect(canvas, jx - u * .2, jy + u * 1.9, u * .3, u * .8,
          const ui.Color(0xFFFFE9A8));
    }
    // Counter and a small tray.
    _rect(canvas, x - u * 9, y - u * 3, u * 18, u * .8, woodDark);
    _rect(canvas, x + u * 2, y - u * 2.8, u * 5, u * .4, gold);
  }

  void _drawBrasswareShop(ui.Canvas canvas, double x, double y, double u) {
    const wall = ui.Color(0xFF6B4A34);
    const brass = ui.Color(0xFFD9A24E);
    const brassLit = ui.Color(0xFFF1C876);
    const brassDark = ui.Color(0xFF8E6423);
    _rect(canvas, x - u * 9, y - u * 14, u * 18, u * 14, wall);
    _rect(canvas, x - u * 10, y - u * 16, u * 20, u * 2.5,
        const ui.Color(0xFF3C2A1E));
    // Stacked pots, three sizes.
    for (var i = 0; i < 3; i++) {
      final px = x - u * 6 + i * u * 6;
      final ph = u * (4 + i * .6);
      canvas.drawOval(
        ui.Rect.fromLTWH(px - u * 2.2, y - ph, u * 4.4, ph),
        ui.Paint()..color = brass,
      );
      canvas.drawArc(
        ui.Rect.fromLTWH(px - u * 2.2, y - ph, u * 4.4, ph),
        math.pi,
        math.pi,
        false,
        ui.Paint()
          ..color = brassDark
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      // Rim and highlight.
      _rect(canvas, px - u * 1.8, y - ph, u * 3.6, u * .4, brassLit);
      _rect(canvas, px - u * 1.4, y - ph + u * .9, u * .8, ph * .55,
          brassLit.withAlpha(120));
    }
  }

  void _drawLockShop(ui.Canvas canvas, double x, double y, double u) {
    const wall = ui.Color(0xFF5B4632);
    const iron = ui.Color(0xFF7C8894);
    const ironDark = ui.Color(0xFF424A54);
    _rect(canvas, x - u * 9, y - u * 15, u * 18, u * 15, wall);
    _rect(canvas, x - u * 10, y - u * 17, u * 20, u * 2.5,
        const ui.Color(0xFF34281F));
    // Rack with padlocks in three rows.
    for (var row = 0; row < 3; row++) {
      final ry = y - u * (12 - row * 4);
      _rect(canvas, x - u * 7, ry, u * 14, u * .35, ironDark);
      for (var col = 0; col < 4; col++) {
        final lx = x - u * 5.5 + col * u * 3.6;
        // Body.
        _rect(canvas, lx, ry + u * .5, u * 1.8, u * 2.4, iron);
        _rect(canvas, lx, ry + u * .5, u * 1.8, u * .4, ironDark);
        // Shackle.
        canvas.drawArc(
          ui.Rect.fromLTWH(lx + u * .3, ry - u * .4, u * 1.2, u * 1.4),
          math.pi,
          math.pi,
          false,
          ui.Paint()
            ..color = iron
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = u * .35,
        );
      }
    }
  }

  void _drawBangleStall(ui.Canvas canvas, double x, double y, double u) {
    const frame = ui.Color(0xFF5A4733);
    const cloth = ui.Color(0xFFE8C76A);
    _rect(canvas, x - u * 9, y - u * 16, u * 18, u * 16,
        const ui.Color(0xFF6B5A43));
    _rect(canvas, x - u * 10, y - u * 18, u * 20, u * 2.5, frame);
    _rect(canvas, x - u * 9, y - u * 15.5, u * 18, u * 1.2, cloth);
    // Three wire racks, each hung with bangles.
    const colours = [
      ui.Color(0xFFD1435B),
      ui.Color(0xFF3B80B8),
      ui.Color(0xFF4FA85E),
      ui.Color(0xFFE1A034),
      ui.Color(0xFF9B55C4),
    ];
    for (var rack = 0; rack < 3; rack++) {
      final rx = x - u * 6 + rack * u * 6;
      _rect(canvas, rx - u * .12, y - u * 13, u * .25, u * 12, frame);
      for (var b = 0; b < 4; b++) {
        final by = y - u * (12 - b * 2.8);
        canvas.drawCircle(
          ui.Offset(rx, by),
          u * 1.1,
          ui.Paint()
            ..color = colours[(rack + b) % colours.length]
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = u * .55,
        );
      }
    }
  }

  void _drawChikanStall(ui.Canvas canvas, double x, double y, double u) {
    const wood = ui.Color(0xFF6B4A34);
    const cloth = ui.Color(0xFFF2ECD8);
    const thread = ui.Color(0xFF8AAE68);
    _rect(canvas, x - u * 9, y - u * 14, u * 18, u * 14, wood);
    _rect(canvas, x - u * 10, y - u * 16, u * 20, u * 2.5,
        const ui.Color(0xFF3F2E22));
    // Three panels of chikankari hanging down.
    for (var i = 0; i < 3; i++) {
      final px = x - u * 6 + i * u * 6;
      _rect(canvas, px - u * 2, y - u * 13, u * 4, u * 12, cloth);
      // Embroidered motif, small vine.
      for (var d = 0; d < 5; d++) {
        canvas.drawCircle(
          ui.Offset(px - u * .8 + (d % 3) * u * .8, y - u * (11.6 - d * 1.8)),
          u * .35,
          ui.Paint()..color = thread,
        );
      }
      canvas.drawLine(
        ui.Offset(px - u * 1.2, y - u * 1.5),
        ui.Offset(px + u * 1.2, y - u * 1.5),
        ui.Paint()
          ..color = thread
          ..strokeWidth = u * .35,
      );
    }
  }

  void _drawPethaShop(ui.Canvas canvas, double x, double y, double u) {
    const counter = ui.Color(0xFF6B4A34);
    const counterTop = ui.Color(0xFF9A6A44);
    const petha = ui.Color(0xFFF0E7D0);
    const pethaEdge = ui.Color(0xFFD6CBAA);
    _rect(canvas, x - u * 9, y - u * 8, u * 18, u * 8, counter);
    _rect(canvas, x - u * 10, y - u * 9, u * 20, u * 1.5, counterTop);
    // Three trays of petha cubes.
    for (var t = 0; t < 3; t++) {
      final tx = x - u * 7 + t * u * 7;
      _rect(canvas, tx - u * 2.6, y - u * 10, u * 5.2, u * 1.4,
          const ui.Color(0xFF4A3A28));
      for (var row = 0; row < 2; row++) {
        for (var col = 0; col < 3; col++) {
          _rect(
            canvas,
            tx - u * 2 + col * u * 1.4,
            y - u * (9.6 - row * .9),
            u * 1.1,
            u * .8,
            petha,
          );
          _rect(canvas, tx - u * 2 + col * u * 1.4,
              y - u * (9.6 - row * .9), u * 1.1, u * .18, pethaEdge);
        }
      }
    }
  }

  void _drawLittiChokha(ui.Canvas canvas, double x, double y, double u) {
    const stone = ui.Color(0xFF5A544A);
    const fire = ui.Color(0xFFE86A2F);
    const litti = ui.Color(0xFFA67845);
    const chokha = ui.Color(0xFF8A4A33);
    // Fire ring.
    _rect(canvas, x - u * 5, y - u * 1.5, u * 10, u * 1.5, stone);
    for (var i = 0; i < 5; i++) {
      canvas.drawArc(
        ui.Rect.fromLTWH(x - u * 3 + i * u * 1.4, y - u * 3, u * 1.4, u * 3),
        0,
        math.pi,
        true,
        ui.Paint()..color = fire.withAlpha(180),
      );
    }
    // Littis on sticks around the fire.
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + (i - 1.5) * .5;
      final lx = x + math.cos(a) * u * 3.2;
      final ly = y - u * 2.5 + math.sin(a) * u * 1.2;
      canvas.drawCircle(ui.Offset(lx, ly), u * .9,
          ui.Paint()..color = litti);
    }
    // Chokha bowl to the side.
    canvas.drawArc(
      ui.Rect.fromLTWH(x + u * 5, y - u * 3.5, u * 3.4, u * 3),
      0,
      math.pi,
      true,
      ui.Paint()..color = chokha,
    );
    _rect(canvas, x + u * 4.8, y - u * 2.2, u * 3.8, u * .5,
        const ui.Color(0xFF4A2A1E));
  }

  void _drawPohaJalebiCart(ui.Canvas canvas, double x, double y, double u) {
    const cart = ui.Color(0xFF8E6A3E);
    const cartDark = ui.Color(0xFF5C4226);
    const plate = ui.Color(0xFFEFE4C9);
    const poha = ui.Color(0xFFE1C378);
    const jalebi = ui.Color(0xFFD8722C);
    // Cart body and wheels.
    _rect(canvas, x - u * 9, y - u * 8, u * 18, u * 5.5, cart);
    _rect(canvas, x - u * 9, y - u * 8.5, u * 18, u * 1, cartDark);
    canvas.drawCircle(ui.Offset(x - u * 6, y - u * 1.5), u * 1.6,
        ui.Paint()..color = cartDark);
    canvas.drawCircle(ui.Offset(x + u * 6, y - u * 1.5), u * 1.6,
        ui.Paint()..color = cartDark);
    // Poha on a shallow tray.
    _rect(canvas, x - u * 8, y - u * 10, u * 8, u * 1.2, plate);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        ui.Offset(x - u * 6.8 + (i % 3) * u * 1.8, y - u * 9.4 - (i ~/ 3) * u * .8),
        u * .5,
        ui.Paint()..color = poha,
      );
    }
    // Jalebis, spirals.
    _rect(canvas, x + u * 1, y - u * 10, u * 7, u * 1.2, plate);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        ui.Offset(x + u * 2.5 + i * u * 2, y - u * 9.5),
        u * .9,
        ui.Paint()
          ..color = jalebi
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = u * .6,
      );
    }
  }

  void _drawOrangeBasket(ui.Canvas canvas, double x, double y, double u) {
    const wicker = ui.Color(0xFFB58B4A);
    const wickerDark = ui.Color(0xFF7C5C2F);
    const orange = ui.Color(0xFFE8812A);
    const leaf = ui.Color(0xFF3F7A3A);
    // Two baskets side by side.
    for (var b = 0; b < 2; b++) {
      final bx = x + (b - .5) * u * 10;
      // Basket body.
      canvas.drawArc(
        ui.Rect.fromLTWH(bx - u * 4.4, y - u * 6, u * 8.8, u * 6),
        0,
        math.pi,
        true,
        ui.Paint()..color = wicker,
      );
      _rect(canvas, bx - u * 4.4, y - u * 3.2, u * 8.8, u * .5, wickerDark);
      // Oranges piled on top.
      for (var r = 0; r < 3; r++) {
        final count = 3 - r;
        for (var i = 0; i < count; i++) {
          final ox = bx - (count - 1) * u * 1.4 + i * u * 2.8;
          final oy = y - u * (7 + r * 1.9);
          canvas.drawCircle(ui.Offset(ox, oy), u * 1.2,
              ui.Paint()..color = orange);
          _rect(canvas, ox - u * .25, oy - u * 1.4, u * .5, u * .6, leaf);
        }
      }
    }
  }

  void _drawBiryaniPot(ui.Canvas canvas, double x, double y, double u) {
    const pot = ui.Color(0xFF6E6A63);
    const potDark = ui.Color(0xFF3F3D38);
    const lid = ui.Color(0xFFD9B774);
    const steam = ui.Color(0x55FFFFFF);
    // Large dum pot.
    canvas.drawArc(
      ui.Rect.fromLTWH(x - u * 6, y - u * 10, u * 12, u * 10),
      0,
      math.pi,
      true,
      ui.Paint()..color = pot,
    );
    _rect(canvas, x - u * 6, y - u * 6, u * 12, u * 1, potDark);
    _rect(canvas, x - u * 6.6, y - u * 10.5, u * 13.2, u * 1.4, lid);
    _rect(canvas, x - u * .8, y - u * 12, u * 1.6, u * 1.6, lid);
    // Steam wisps rising above.
    for (var i = 0; i < 3; i++) {
      final sx = x - u * 3 + i * u * 3;
      final sy = y - u * (13 + (i * 1.4));
      canvas.drawCircle(ui.Offset(sx, sy), u * 1.1,
          ui.Paint()..color = steam);
    }
  }

  void _drawRosogollaStall(ui.Canvas canvas, double x, double y, double u) {
    const wood = ui.Color(0xFF6B4A34);
    const glass = ui.Color(0x88B8D8E0);
    const syrup = ui.Color(0xFFE7C980);
    const rosogolla = ui.Color(0xFFF5EAD0);
    _rect(canvas, x - u * 9, y - u * 12, u * 18, u * 12, wood);
    _rect(canvas, x - u * 9.5, y - u * 12, u * 19, u * 1.5,
        const ui.Color(0xFF3D2A1E));
    // Glass case with two trays of rosogollas.
    for (var t = 0; t < 2; t++) {
      final ty = y - u * (10 - t * 4.6);
      _rect(canvas, x - u * 7.5, ty, u * 15, u * 3.6, glass);
      _rect(canvas, x - u * 7, ty + u * .5, u * 14, u * 2.6, syrup);
      for (var i = 0; i < 6; i++) {
        canvas.drawCircle(
          ui.Offset(x - u * 5.5 + i * u * 2.2, ty + u * 1.8),
          u * .85,
          ui.Paint()..color = rosogolla,
        );
      }
      _rect(canvas, x - u * 7.5, ty, u * 15, u * .3,
          const ui.Color(0xFFCBA96A));
    }
  }

  void _drawFilterCoffeeStand(ui.Canvas canvas, double x, double y, double u) {
    const steel = ui.Color(0xFFC7CDD0);
    const steelDark = ui.Color(0xFF7A8185);
    const coffee = ui.Color(0xFF5A3419);
    const steam = ui.Color(0x55FFFFFF);
    // Small counter.
    _rect(canvas, x - u * 6, y - u * 8, u * 12, u * 8,
        const ui.Color(0xFF6B4A34));
    _rect(canvas, x - u * 6.5, y - u * 8.5, u * 13, u * 1.2, steelDark);
    // Filter coffee set: upper drum, lower tumbler, small davara beside.
    // Upper drum.
    _rect(canvas, x - u * 3, y - u * 14, u * 6, u * 4.2, steel);
    _rect(canvas, x - u * 3, y - u * 14, u * 6, u * .4, steelDark);
    _rect(canvas, x - u * 3.4, y - u * 10.3, u * 6.8, u * .8, steelDark);
    // Drip.
    _rect(canvas, x - u * .15, y - u * 9.4, u * .3, u * 1.2, coffee);
    // Lower tumbler with coffee.
    _rect(canvas, x - u * 2.6, y - u * 8.4, u * 5.2, u * 3.4, steel);
    _rect(canvas, x - u * 2.2, y - u * 7.6, u * 4.4, u * 2.2, coffee);
    // Small davara to the side.
    _rect(canvas, x + u * 3.2, y - u * 6.4, u * 2.6, u * 1.4, steel);
    _rect(canvas, x + u * 3.4, y - u * 6.2, u * 2.2, u * .5, coffee);
    // Steam.
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        ui.Offset(x - u * 1 + i * u * 1.2, y - u * (16 + i * .8)),
        u * .9,
        ui.Paint()..color = steam,
      );
    }
  }

  void _drawDiyaCluster(ui.Canvas canvas, double x, double y, double u) {
    const water = ui.Color(0xFF2B4A63);
    const diya = ui.Color(0xFFB15A34);
    const flame = ui.Color(0xFFF5C252);
    const flameCore = ui.Color(0xFFFFF1B0);
    // Small pool of water.
    canvas.drawOval(
      ui.Rect.fromLTWH(x - u * 12, y - u * 2, u * 24, u * 4),
      ui.Paint()..color = water,
    );
    _rect(canvas, x - u * 11, y - u * 2, u * 22, u * .4,
        const ui.Color(0xFF5D86A1));
    // Diyas floating.
    for (var i = 0; i < 4; i++) {
      final dx = x - u * 8 + i * u * 5.4 + math.sin(_elapsed * .8 + i) * u * .4;
      final dy = y - u * .4;
      // Bowl.
      canvas.drawArc(
        ui.Rect.fromLTWH(dx - u * 1.4, dy - u * 1, u * 2.8, u * 2),
        0,
        math.pi,
        true,
        ui.Paint()..color = diya,
      );
      // Flame.
      canvas.drawCircle(ui.Offset(dx, dy - u * 2),
          u * .9, ui.Paint()..color = flame);
      canvas.drawCircle(ui.Offset(dx, dy - u * 2),
          u * .4, ui.Paint()..color = flameCore);
    }
  }

  void _drawKathputliPuppet(ui.Canvas canvas, double x, double y, double u) {
    const stand = ui.Color(0xFF4A3420);
    const body = ui.Color(0xFFC64A3A);
    const sash = ui.Color(0xFFE0B448);
    const face = ui.Color(0xFFF2DFB6);
    const eyes = ui.Color(0xFF1B1B1B);
    // Stand.
    _rect(canvas, x - u * .2, y - u * 2, u * .4, u * 2, stand);
    _rect(canvas, x - u * 3, y - u * 1, u * 6, u * .7, stand);
    // Vertical control stick.
    _rect(canvas, x - u * .2, y - u * 20, u * .4, u * 18, stand);
    _rect(canvas, x - u * 4, y - u * 20, u * 8, u * .4, stand);
    // Puppet body.
    _rect(canvas, x - u * 2, y - u * 16, u * 4, u * 6, body);
    // Sash across the chest.
    _rect(canvas, x - u * 2, y - u * 12, u * 4, u * 1, sash);
    // Head and features.
    _rect(canvas, x - u * 1.4, y - u * 19, u * 2.8, u * 3, face);
    _rect(canvas, x - u * 1, y - u * 18.2, u * .5, u * .5, eyes);
    _rect(canvas, x + u * .5, y - u * 18.2, u * .5, u * .5, eyes);
    // Skirt flare.
    final skirt = ui.Path()
      ..moveTo(x - u * 2, y - u * 10)
      ..lineTo(x - u * 3.4, y - u * 5)
      ..lineTo(x + u * 3.4, y - u * 5)
      ..lineTo(x + u * 2, y - u * 10)
      ..close();
    canvas.drawPath(skirt, ui.Paint()..color = body);
    _rect(canvas, x - u * 3, y - u * 6.5, u * 6, u * .6, sash);
  }

  void _drawVadaPavCart(ui.Canvas canvas, double x, double y, double u) {
    const cart = ui.Color(0xFF8A6238);
    const cartDark = ui.Color(0xFF5A3E22);
    const fryer = ui.Color(0xFF3F3B33);
    const oil = ui.Color(0xFFC58A3A);
    const bun = ui.Color(0xFFDCB478);
    const chutney = ui.Color(0xFF4E7B3A);
    // Cart.
    _rect(canvas, x - u * 9, y - u * 8, u * 18, u * 6, cart);
    _rect(canvas, x - u * 9, y - u * 8.5, u * 18, u * 1, cartDark);
    canvas.drawCircle(ui.Offset(x - u * 6, y - u * 1.4), u * 1.5,
        ui.Paint()..color = cartDark);
    canvas.drawCircle(ui.Offset(x + u * 6, y - u * 1.4), u * 1.5,
        ui.Paint()..color = cartDark);
    // Fryer with oil on one side.
    _rect(canvas, x - u * 7, y - u * 11.5, u * 7, u * 3.5, fryer);
    _rect(canvas, x - u * 6.4, y - u * 10.8, u * 5.8, u * 2.2, oil);
    // A vada floating.
    canvas.drawCircle(ui.Offset(x - u * 4, y - u * 9.6), u * .9,
        ui.Paint()..color = ui.Color(0xFFD3A054));
    // Stack of pav on the other side.
    _rect(canvas, x + u * 1, y - u * 10, u * 7, u * 2, cartDark);
    for (var r = 0; r < 3; r++) {
      for (var i = 0; i < 3; i++) {
        canvas.drawArc(
          ui.Rect.fromLTWH(
              x + u * (1.5 + i * 2.2), y - u * (10 - r * 1), u * 1.8, u * 1),
          0,
          math.pi,
          true,
          ui.Paint()..color = bun,
        );
      }
    }
    // Chutney bowl.
    canvas.drawArc(
      ui.Rect.fromLTWH(x + u * 1.4, y - u * 7.6, u * 2.6, u * 1.8),
      0,
      math.pi,
      true,
      ui.Paint()..color = chutney,
    );
  }

  void _drawTramStop(ui.Canvas canvas, double x, double y, double u) {
    const pole = ui.Color(0xFF4B4E52);
    const roof = ui.Color(0xFF7A4032);
    const glass = ui.Color(0x88B8D8E0);
    const sign = ui.Color(0xFFE8C76A);
    // Two poles.
    _rect(canvas, x - u * 6, y - u * 14, u * .7, u * 14, pole);
    _rect(canvas, x + u * 5.3, y - u * 14, u * .7, u * 14, pole);
    // Roof.
    final roofPath = ui.Path()
      ..moveTo(x - u * 8, y - u * 14)
      ..lineTo(x - u * 6, y - u * 17)
      ..lineTo(x + u * 6, y - u * 17)
      ..lineTo(x + u * 8, y - u * 14)
      ..close();
    canvas.drawPath(roofPath, ui.Paint()..color = roof);
    // Glass backing.
    _rect(canvas, x - u * 6, y - u * 14, u * 12, u * 8, glass);
    // Bench inside.
    _rect(canvas, x - u * 5, y - u * 8.5, u * 10, u * 1, pole);
    // Timetable sign on the front.
    _rect(canvas, x - u * 4.5, y - u * 13, u * 9, u * 2.5, sign);
    _rect(canvas, x - u * 4, y - u * 12.6, u * 8, u * .3,
        const ui.Color(0xFF4B3822));
    _rect(canvas, x - u * 4, y - u * 11.9, u * 6, u * .3,
        const ui.Color(0xFF4B3822));
  }

  void _drawChaiStall(ui.Canvas canvas, double x, double y, double u) {
    const cart = ui.Color(0xFF7A5638);
    const cartDark = ui.Color(0xFF4C3421);
    const kettle = ui.Color(0xFFC2C7CA);
    const kettleDark = ui.Color(0xFF7D8388);
    const tea = ui.Color(0xFF8E4A22);
    const steam = ui.Color(0x66FFFFFF);
    // Cart.
    _rect(canvas, x - u * 8, y - u * 7, u * 16, u * 5.5, cart);
    _rect(canvas, x - u * 8, y - u * 7.5, u * 16, u * 1, cartDark);
    canvas.drawCircle(ui.Offset(x - u * 5, y - u * 1.4), u * 1.4,
        ui.Paint()..color = cartDark);
    canvas.drawCircle(ui.Offset(x + u * 5, y - u * 1.4), u * 1.4,
        ui.Paint()..color = cartDark);
    // Kettle on top.
    _rect(canvas, x - u * 5, y - u * 11, u * 4, u * 3.5, kettle);
    _rect(canvas, x - u * 5, y - u * 11.5, u * 4, u * .8, kettleDark);
    // Spout.
    canvas.drawLine(
      ui.Offset(x - u * 5, y - u * 9.5),
      ui.Offset(x - u * 6.4, y - u * 8.6),
      ui.Paint()
        ..color = kettle
        ..strokeWidth = u * .6,
    );
    // Handle.
    canvas.drawArc(
      ui.Rect.fromLTWH(x - u * 4.6, y - u * 13.4, u * 3.2, u * 2.6),
      math.pi,
      math.pi,
      false,
      ui.Paint()
        ..color = kettleDark
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = u * .35,
    );
    // Steam above the kettle.
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        ui.Offset(x - u * 3 + i * u * 1.2, y - u * (14 + i * 1.1)),
        u * .9,
        ui.Paint()..color = steam,
      );
    }
    // Three glasses on the counter.
    for (var i = 0; i < 3; i++) {
      _rect(canvas, x - u * 1.5 + i * u * 2, y - u * 6.5, u * 1, u * 1.5,
          kettle);
      _rect(canvas, x - u * 1.5 + i * u * 2, y - u * 5.7, u * 1, u * .7, tea);
    }
  }

  // ── International markers ─────────────────────────────────────────────────

  void _drawCafeTable(ui.Canvas canvas, double x, double y, double u) {
    const metal = ui.Color(0xFF3E3A34);
    const cloth = ui.Color(0xFFF2ECD8);
    const coffee = ui.Color(0xFF5A3419);
    // Table top and leg.
    canvas.drawOval(
      ui.Rect.fromLTWH(x - u * 4, y - u * 6, u * 8, u * 1.6),
      ui.Paint()..color = metal,
    );
    _rect(canvas, x - u * .3, y - u * 5, u * .6, u * 5, metal);
    // Two chairs.
    for (var s = -1; s <= 1; s += 2) {
      final cx = x + s * u * 4.5;
      _rect(canvas, cx - u * 1.2, y - u * 4, u * 2.4, u * .8, metal);
      _rect(canvas, cx - u * .3, y - u * 3.6, u * .6, u * 3.6, metal);
      _rect(canvas, cx - u * 1.2, y - u * 6, u * 2.4, u * .4, metal);
    }
    // Coffee cup and napkin.
    _rect(canvas, x - u * 2, y - u * 7, u * 2, u * 1.2, cloth);
    _rect(canvas, x - u * 1.5, y - u * 7.4, u * 1.2, u * .5, coffee);
    _rect(canvas, x + u * 1, y - u * 6.6, u * 2, u * .4, cloth);
  }

  void _drawVendingMachine(ui.Canvas canvas, double x, double y, double u) {
    const body = ui.Color(0xFFC0443C);
    const panel = ui.Color(0x88B8D8E0);
    const button = ui.Color(0xFFE8C76A);
    const glow = ui.Color(0x33FFE58A);
    // Body.
    _rect(canvas, x - u * 4, y - u * 16, u * 8, u * 16, body);
    _rect(canvas, x - u * 4, y - u * 16, u * 8, u * 1.2,
        const ui.Color(0xFF7C1F1A));
    // Glass front.
    _rect(canvas, x - u * 3, y - u * 14, u * 6, u * 10, panel);
    // Internal glow.
    canvas.drawRect(
      ui.Rect.fromLTWH(x - u * 3, y - u * 14, u * 6, u * 10),
      ui.Paint()..color = glow,
    );
    // Rows of bottles/snacks.
    const items = [
      ui.Color(0xFFE0A84B),
      ui.Color(0xFF5AA85A),
      ui.Color(0xFF4E7FB8),
      ui.Color(0xFFD6564A),
    ];
    for (var r = 0; r < 3; r++) {
      _rect(canvas, x - u * 3, y - u * (13 - r * 3.2), u * 6, u * .3,
          const ui.Color(0xFF3B3B3B));
      for (var i = 0; i < 4; i++) {
        _rect(
          canvas,
          x - u * 2.6 + i * u * 1.4,
          y - u * (12.6 - r * 3.2),
          u * 1,
          u * 2.4,
          items[(r + i) % items.length],
        );
      }
    }
    // Button panel and coin slot.
    _rect(canvas, x - u * 3, y - u * 3.5, u * 6, u * 1.8,
        const ui.Color(0xFF2B2B2B));
    _rect(canvas, x + u * 1.5, y - u * 3.2, u * 1, u * 1.2, button);
    _rect(canvas, x - u * .5, y - u * 3.2, u * 1.4, u * .4, button);
  }

  void _drawPhoneBox(ui.Canvas canvas, double x, double y, double u) {
    const red = ui.Color(0xFFB3312B);
    const redDark = ui.Color(0xFF6E1815);
    const glass = ui.Color(0x99B8D8E0);
    const trim = ui.Color(0xFFF2ECD8);
    // Body.
    _rect(canvas, x - u * 4, y - u * 18, u * 8, u * 18, red);
    // Crown.
    _rect(canvas, x - u * 4.5, y - u * 19, u * 9, u * 1.2, redDark);
    _rect(canvas, x - u * 4, y - u * 21, u * 8, u * 2, red);
    _rect(canvas, x - u * 3, y - u * 22, u * 6, u * 1, redDark);
    // Sign panel.
    _rect(canvas, x - u * 3, y - u * 20.4, u * 6, u * 1.4, trim);
    _rect(canvas, x - u * 2.4, y - u * 20.1, u * 4.8, u * .35, redDark);
    // Glass windows on the upper half.
    _rect(canvas, x - u * 2.8, y - u * 16, u * 5.6, u * 6, glass);
    // Mullions.
    _rect(canvas, x - u * .12, y - u * 16, u * .24, u * 6, red);
    _rect(canvas, x - u * 2.8, y - u * 13.2, u * 5.6, u * .24, red);
    // Lower door.
    _rect(canvas, x - u * 3.6, y - u * 9, u * 7.2, u * 9, red);
    _rect(canvas, x - u * 3.6, y - u * 9, u * .3, u * 9, redDark);
  }

  void _drawHotDogCart(ui.Canvas canvas, double x, double y, double u) {
    const cart = ui.Color(0xFFE8E2D2);
    const cartDark = ui.Color(0xFF7C766C);
    const stripe = ui.Color(0xFFC64A3A);
    const umbrella = ui.Color(0xFFE8C76A);
    // Cart body.
    _rect(canvas, x - u * 7, y - u * 6, u * 14, u * 5, cart);
    _rect(canvas, x - u * 7, y - u * 6.5, u * 14, u * 1, stripe);
    _rect(canvas, x - u * 7, y - u * 3, u * 14, u * .5, cartDark);
    // Wheels.
    canvas.drawCircle(ui.Offset(x - u * 4.5, y - u * 1.4), u * 1.3,
        ui.Paint()..color = cartDark);
    canvas.drawCircle(ui.Offset(x + u * 4.5, y - u * 1.4), u * 1.3,
        ui.Paint()..color = cartDark);
    // Umbrella pole and canopy.
    _rect(canvas, x - u * .15, y - u * 18, u * .3, u * 12, cartDark);
    final canopy = ui.Path()
      ..moveTo(x - u * 8, y - u * 18)
      ..quadraticBezierTo(x, y - u * 22, x + u * 8, y - u * 18)
      ..lineTo(x + u * 7, y - u * 17)
      ..quadraticBezierTo(x, y - u * 20, x - u * 7, y - u * 17)
      ..close();
    canvas.drawPath(canopy, ui.Paint()..color = umbrella);
    // A couple of hot dogs on the counter.
    for (var i = 0; i < 2; i++) {
      final hx = x - u * 3 + i * u * 4;
      _rect(canvas, hx, y - u * 6, u * 3, u * 1, ui.Color(0xFFD9A45A));
      _rect(canvas, hx, y - u * 6.3, u * 3, u * .4, ui.Color(0xFFB34747));
    }
  }

  void _drawScooter(ui.Canvas canvas, double x, double y, double u) {
    const body = ui.Color(0xFFC64A3A);
    const bodyDark = ui.Color(0xFF6E1815);
    const wheel = ui.Color(0xFF26211E);
    const chrome = ui.Color(0xFFC7CDD0);
    // Wheels.
    canvas.drawCircle(ui.Offset(x - u * 4, y - u * 1.4), u * 1.4,
        ui.Paint()..color = wheel);
    canvas.drawCircle(ui.Offset(x + u * 4, y - u * 1.4), u * 1.4,
        ui.Paint()..color = wheel);
    // Body.
    _rect(canvas, x - u * 3, y - u * 6, u * 6, u * 3, body);
    _rect(canvas, x - u * 3, y - u * 6, u * 6, u * .6, bodyDark);
    // Front shield.
    final shield = ui.Path()
      ..moveTo(x + u * 2.4, y - u * 6)
      ..lineTo(x + u * 3.6, y - u * 3)
      ..lineTo(x + u * 4.4, y - u * 1.5)
      ..lineTo(x + u * 4, y - u * 6)
      ..close();
    canvas.drawPath(shield, ui.Paint()..color = body);
    // Handlebar.
    _rect(canvas, x + u * 3.4, y - u * 10, u * .4, u * 4, bodyDark);
    _rect(canvas, x + u * 2, y - u * 10.4, u * 3, u * .4, chrome);
    // Headlight.
    canvas.drawCircle(ui.Offset(x + u * 3.6, y - u * 9.4), u * .6,
        ui.Paint()..color = ui.Color(0xFFFFE58A));
    // Seat.
    _rect(canvas, x - u * 3, y - u * 6.8, u * 3, u * .8, ui.Color(0xFF3B2A1F));
  }

  void _drawHawkerStall(ui.Canvas canvas, double x, double y, double u) {
    const awning = ui.Color(0xFFD64B3C);
    const awningAlt = ui.Color(0xFFF2ECD8);
    const pole = ui.Color(0xFF5A544A);
    const table = ui.Color(0xFF8A6A42);
    const bulb = ui.Color(0xFFF5C252);
    // Poles and awning.
    _rect(canvas, x - u * 6, y - u * 14, u * .5, u * 14, pole);
    _rect(canvas, x + u * 5.5, y - u * 14, u * .5, u * 14, pole);
    // Striped awning.
    for (var i = 0; i < 6; i++) {
      _rect(canvas, x - u * 6.5 + i * u * 2.2, y - u * 15, u * 2.2, u * 1.4,
          i.isEven ? awning : awningAlt);
    }
    _rect(canvas, x - u * 6.5, y - u * 15, u * 13, u * .3, pole);
    // Bulb hanging in the middle.
    _rect(canvas, x - u * .15, y - u * 13.6, u * .3, u * 1, pole);
    canvas.drawCircle(ui.Offset(x, y - u * 12.3), u * .6,
        ui.Paint()..color = bulb);
    canvas.drawCircle(ui.Offset(x, y - u * 12.3), u * 1.6,
        ui.Paint()..color = const ui.Color(0x44F5C252));
    // Table under the awning.
    _rect(canvas, x - u * 5, y - u * 6, u * 10, u * .7, table);
    _rect(canvas, x - u * 4.6, y - u * 5.3, u * .5, u * 5.3, pole);
    _rect(canvas, x + u * 4.1, y - u * 5.3, u * .5, u * 5.3, pole);
    // A couple of items on the table.
    for (var i = 0; i < 3; i++) {
      _rect(canvas, x - u * 3 + i * u * 2.4, y - u * 7, u * 1.6, u * 1,
          i.isEven ? awning : ui.Color(0xFFB58B4A));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Atmospheric distance — far horizons and haze bands
  // ───────────────────────────────────────────────────────────────────────────

  /// Adds a distant hill silhouette and two soft haze bands between the sky
  /// and the existing horizon.
  ///
  /// Two ridge layers at decreasing opacity, and two gradient bands the
  /// colour of the sky, create atmospheric perspective: distant features wash
  /// out toward the sky tone, which is how the human eye reads distance.
  void _drawAtmosphericDistance(ui.Canvas canvas, double w, double h) {
    final skyTone = debugLitSkyColor;
    final farTone = _horizonFarColor;

    // 1. Furthest ridge — 85% blended toward the sky, barely visible.
    final furthestTone = ui.Color.lerp(farTone, skyTone, .85)!;
    canvas.drawPath(_furthestRidgePath(w, h),
        ui.Paint()..color = furthestTone);

    // 2. Distant ridge — 72% blended, more visible than the furthest.
    final distantTone = ui.Color.lerp(farTone, skyTone, .72)!;
    canvas.drawPath(_distantRidgePath(w, h),
        ui.Paint()..color = distantTone);

    // 3. Upper haze band, softening the top edges of the furthest ridge.
    final upperTop = h * .42;
    final upperBottom = h * .50;
    canvas.drawRect(
      ui.Rect.fromLTWH(0, upperTop, w, upperBottom - upperTop),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(0, upperTop),
          ui.Offset(0, upperBottom),
          [
            skyTone.withAlpha(0),
            skyTone.withAlpha((_atmosphericHazeStrength * .55).round()),
          ],
        ),
    );

    // 4. Lower haze band, the "air" between the distant ridge and the near
    //    horizon. Stronger, since this is where depth reads most.
    final lowerTop = h * .50;
    final lowerBottom = h * .585;
    canvas.drawRect(
      ui.Rect.fromLTWH(0, lowerTop, w, lowerBottom - lowerTop),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(0, lowerTop),
          ui.Offset(0, lowerBottom),
          [
            skyTone.withAlpha(0),
            skyTone.withAlpha(_atmosphericHazeStrength),
          ],
        ),
    );
  }

  /// Peak alpha of the atmospheric haze bands, 0–255.
  ///
  /// Hazier in rain, fog, and sandstorm; lighter at night and in clear heat
  /// where the horizon should read as crisp and dry.
  int get _atmosphericHazeStrength {
    if (_fog) return 140;
    if (_sandstorm) return 120;
    if (_storm || _rain) return 90;
    if (_hot) return 55;
    if (!isDay) return 45;
    return 70;
  }

  /// Ridge line for the distant hills, higher on the canvas than the existing
  /// horizon so it reads as further away.
  ///
  /// Biomes get different silhouettes: mountains get angular peaks, cities
  /// get tower blocks, dunes get long shallow curves.
  ui.Path _distantRidgePath(double w, double h) {
    final path = ui.Path();
    switch (_horizonKind) {
      case _HorizonKind.mountain:
        path
          ..moveTo(0, h * .53)
          ..lineTo(w * .08, h * .43)
          ..lineTo(w * .18, h * .49)
          ..lineTo(w * .31, h * .38)
          ..lineTo(w * .45, h * .50)
          ..lineTo(w * .58, h * .42)
          ..lineTo(w * .72, h * .48)
          ..lineTo(w * .86, h * .40)
          ..lineTo(w, h * .50);
      case _HorizonKind.dune:
        path
          ..moveTo(0, h * .51)
          ..quadraticBezierTo(w * .19, h * .44, w * .36, h * .50)
          ..quadraticBezierTo(w * .54, h * .56, w * .71, h * .47)
          ..quadraticBezierTo(w * .88, h * .41, w, h * .49);
      case _HorizonKind.skyline:
        path.moveTo(0, h * .55);
        var x = 0.0;
        var t = 0;
        while (x < w) {
          final tw = w * (.05 + (t % 4) * .018);
          final top = h * (.50 - (t * 11 % 13) / 100);
          path
            ..lineTo(x, top)
            ..lineTo(x + tw, top);
          x += tw;
          t++;
        }
        path.lineTo(w, h * .55);
      case _HorizonKind.coast:
        path
          ..moveTo(0, h * .525)
          ..quadraticBezierTo(w * .24, h * .485, w * .48, h * .515)
          ..quadraticBezierTo(w * .72, h * .545, w, h * .50);
      case _HorizonKind.canopy:
        path.moveTo(0, h * .525);
        for (var i = 0; i < 7; i++) {
          path.quadraticBezierTo(
            w * (i + .5) / 7,
            h * (.44 + (i % 3) * .018),
            w * (i + 1) / 7,
            h * (.515 + (i % 2) * .010),
          );
        }
      case _HorizonKind.riverPlain:
        path
          ..moveTo(0, h * .525)
          ..quadraticBezierTo(w * .32, h * .490, w * .57, h * .515)
          ..quadraticBezierTo(w * .80, h * .535, w, h * .50);
      case _HorizonKind.woodedRidge:
        path
          ..moveTo(0, h * .52)
          ..lineTo(w * .14, h * .44)
          ..lineTo(w * .24, h * .50)
          ..lineTo(w * .40, h * .42)
          ..lineTo(w * .55, h * .50)
          ..lineTo(w * .71, h * .43)
          ..lineTo(w * .84, h * .49)
          ..lineTo(w, h * .42);
    }
    return path
      ..lineTo(w, h * .57)
      ..lineTo(0, h * .57)
      ..close();
  }

  /// Ridge line for the very furthest layer.
  ///
  /// Higher and more angular than [_distantRidgePath] so two overlapping
  /// silhouettes read as two distinct distances.
  ui.Path _furthestRidgePath(double w, double h) {
    final path = ui.Path();
    switch (_horizonKind) {
      case _HorizonKind.mountain:
        path
          ..moveTo(0, h * .47)
          ..lineTo(w * .12, h * .39)
          ..lineTo(w * .26, h * .45)
          ..lineTo(w * .40, h * .36)
          ..lineTo(w * .56, h * .46)
          ..lineTo(w * .70, h * .40)
          ..lineTo(w * .84, h * .44)
          ..lineTo(w, h * .42);
      case _HorizonKind.dune:
        path
          ..moveTo(0, h * .47)
          ..quadraticBezierTo(w * .23, h * .42, w * .44, h * .47)
          ..quadraticBezierTo(w * .68, h * .50, w, h * .45);
      case _HorizonKind.skyline:
        path.moveTo(0, h * .49);
        var x = 0.0;
        var t = 0;
        while (x < w) {
          final tw = w * (.055 + (t % 3) * .020);
          final top = h * (.46 - (t * 9 % 10) / 100);
          path
            ..lineTo(x, top)
            ..lineTo(x + tw, top);
          x += tw;
          t++;
        }
        path.lineTo(w, h * .49);
      case _HorizonKind.coast:
        path
          ..moveTo(0, h * .475)
          ..quadraticBezierTo(w * .28, h * .445, w * .55, h * .470)
          ..quadraticBezierTo(w * .78, h * .488, w, h * .455);
      case _HorizonKind.canopy:
        path.moveTo(0, h * .475);
        for (var i = 0; i < 6; i++) {
          path.quadraticBezierTo(
            w * (i + .5) / 6,
            h * (.41 + (i % 3) * .014),
            w * (i + 1) / 6,
            h * (.470 + (i % 2) * .010),
          );
        }
      case _HorizonKind.riverPlain:
        path
          ..moveTo(0, h * .475)
          ..quadraticBezierTo(w * .35, h * .450, w * .60, h * .470)
          ..quadraticBezierTo(w * .82, h * .482, w, h * .455);
      case _HorizonKind.woodedRidge:
        path
          ..moveTo(0, h * .47)
          ..lineTo(w * .16, h * .40)
          ..lineTo(w * .28, h * .45)
          ..lineTo(w * .44, h * .38)
          ..lineTo(w * .60, h * .455)
          ..lineTo(w * .76, h * .40)
          ..lineTo(w * .88, h * .445)
          ..lineTo(w, h * .40);
    }
    return path
      ..lineTo(w, h * .52)
      ..lineTo(0, h * .52)
      ..close();
  }

    // ───────────────────────────────────────────────────────────────────────────
  // Ground path — a winding road that recedes toward the horizon
  // ───────────────────────────────────────────────────────────────────────────

  /// Draws a winding path from the horizon down to the character's feet.
  ///
  /// The path's shape varies per city via a stable seed, so two cities in the
  /// same biome don't share the same road. Colour and texture vary by biome
  /// and weather.
  void _drawGroundPath(ui.Canvas canvas, double w, double h) {
    // Seed determines the bend direction and the two control points that
    // make the path wind rather than run straight. Same seed per city, so
    // the road is the same road on every visit.
    final seed = worldLocationSeed(location);
    final rng = math.Random(seed ^ 0x3A21);
    final bend = (rng.nextDouble() - .5) * .24; // -0.12 .. +0.12 in w fractions
    final midBend = (rng.nextDouble() - .5) * .16;

    // Path narrows as it recedes: from ~30% of scene width at the feet to
    // ~8% at the horizon. That ratio is what makes a flat surface read as
    // distance.
    final topY = h * .57;
    final botY = h * .92;
    final topHalfW = w * .04;
    final botHalfW = w * .15;
    final topCenterX = w * (.50 + bend * .5);
    final botCenterX = w * (.50 + midBend);

    final leftEdge = ui.Path()
      ..moveTo(topCenterX - topHalfW, topY)
      ..quadraticBezierTo(
        w * (.50 + bend * .25) - topHalfW * 2.6,
        h * .73,
        botCenterX - botHalfW,
        botY,
      );
    final rightEdge = ui.Path()
      ..moveTo(topCenterX + topHalfW, topY)
      ..quadraticBezierTo(
        w * (.50 + bend * .25) + topHalfW * 2.6,
        h * .73,
        botCenterX + botHalfW,
        botY,
      );

    // Fill: sample colours from the biome, then shift for weather.
    final pathTone = _pathColourForBiome();
    final pathFill = ui.Path()
      ..moveTo(topCenterX - topHalfW, topY)
      ..lineTo(topCenterX + topHalfW, topY)
      ..quadraticBezierTo(
        w * (.50 + bend * .25) + topHalfW * 2.6,
        h * .73,
        botCenterX + botHalfW,
        botY,
      )
      ..lineTo(botCenterX - botHalfW, botY)
      ..quadraticBezierTo(
        w * (.50 + bend * .25) - topHalfW * 2.6,
        h * .73,
        topCenterX - topHalfW,
        topY,
      )
      ..close();
    canvas.drawPath(pathFill, ui.Paint()..color = pathTone);

    // Ruts, cobbles, or sand ripples along the path. Detail only matters
    // near the bottom where the pixel size is largest, so this fades toward
    // the horizon and stops mid-path.
    _drawPathTexture(canvas, w, h, topCenterX, botCenterX, topHalfW, botHalfW,
        topY, botY, pathTone);

    // Edges: a darker rim on both sides of the path adds the sense of a
    // cut or curb. On the bottom half only, since the top half is thin.
    final edge = pathTone.withAlpha(190);
    canvas.drawPath(
      leftEdge,
      ui.Paint()
        ..color = edge
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, w * .0035),
    );
    canvas.drawPath(
      rightEdge,
      ui.Paint()
        ..color = edge
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, w * .0035),
    );
  }

  /// Base tone for the path, derived from the current biome and weather.
  ui.Color _pathColourForBiome() {
    // Wet weather darkens everything.
    final wetness = _rain ? .75 : 1.0;
    final snowCover = _snow || _winterWorld;
    if (snowCover) {
      return _storm
          ? const ui.Color(0xFF9AACB0)
          : const ui.Color(0xFFD6E0E4);
    }
    switch (location.biome) {
      case WorldBiome.desert:
      case WorldBiome.coldDesert:
        return (const ui.Color(0xFFB58549)).withValues(
            alpha: wetness);
      case WorldBiome.urban:
        return (const ui.Color(0xFF5E5A57)).withValues(alpha: wetness);
      case WorldBiome.coastal:
        return (const ui.Color(0xFFA07952)).withValues(alpha: wetness);
      case WorldBiome.mountain:
        return (const ui.Color(0xFF6E675E)).withValues(alpha: wetness);
      case WorldBiome.river:
        return (const ui.Color(0xFF8A6B48)).withValues(alpha: wetness);
      case WorldBiome.tropical:
      case WorldBiome.temperate:
        return (const ui.Color(0xFF6B573B)).withValues(alpha: wetness);
    }
  }

  /// Weather-and-biome-aware texture on the path.
  ///
  /// Only draws in the near half of the path — the far half is too compressed
  /// for detail to read, and painting it makes the path look busy rather than
  /// distant.
  void _drawPathTexture(
    ui.Canvas canvas,
    double w,
    double h,
    double topCenterX,
    double botCenterX,
    double topHalfW,
    double botHalfW,
    double topY,
    double botY,
    ui.Color baseTone,
  ) {
    final seed = worldLocationSeed(location);
    final rng = math.Random(seed ^ 0xCAFE);

    // Interpolates along the path from t=0 (horizon) to t=1 (feet).
    double pathCenterAt(double t) =>
        topCenterX + (botCenterX - topCenterX) * t;
    double pathHalfWAt(double t) => topHalfW + (botHalfW - topHalfW) * t;
    double pathYAt(double t) => topY + (botY - topY) * t;

    final isUrban = location.biome == WorldBiome.urban;
    final isDesert = location.biome == WorldBiome.desert ||
        location.biome == WorldBiome.coldDesert;

    if (isUrban) {
      // Cobblestone tiles across the near half of the path.
      final tileCount = 24;
      for (var i = 0; i < tileCount; i++) {
        final t = .35 + rng.nextDouble() * .60;
        final cx = pathCenterAt(t) + (rng.nextDouble() - .5) * pathHalfWAt(t) * 1.8;
        final cy = pathYAt(t);
        final r = math.max(1.0, (1 - t) * 4.5 + 1.0);
        // Slight colour variance per stone.
        final shade = baseTone.withValues(
            alpha: 1.0, red: (baseTone.r * 255 + rng.nextInt(30) - 15).clamp(0, 255).toInt() / 255);
        canvas.drawCircle(
          ui.Offset(cx, cy),
          r,
          ui.Paint()..color = shade.withAlpha(180),
        );
      }
      return;
    }

    if (isDesert) {
      // Faint wind ripples — short horizontal dashes.
      for (var i = 0; i < 20; i++) {
        final t = .35 + rng.nextDouble() * .60;
        final cx = pathCenterAt(t) +
            (rng.nextDouble() - .5) * pathHalfWAt(t) * 1.4;
        final cy = pathYAt(t);
        final length = pathHalfWAt(t) * (.15 + rng.nextDouble() * .20);
        _rect(canvas, cx - length / 2, cy, length, math.max(1.0, (1 - t) * 1.6),
            baseTone.withAlpha(150));
      }
      return;
    }

    // Rural: wheel ruts running along the path plus scattered pebbles.
    final rutCount = 2;
    for (var rut = 0; rut < rutCount; rut++) {
      // Ruts run from ~60% down to the feet, offset from the center.
      final offsetSign = rut == 0 ? -1.0 : 1.0;
      final rutPath = ui.Path();
      for (var step = 0; step <= 20; step++) {
        final t = .55 + (step / 20) * .44;
        final cx = pathCenterAt(t) + offsetSign * pathHalfWAt(t) * .55;
        final cy = pathYAt(t);
        if (step == 0) {
          rutPath.moveTo(cx, cy);
        } else {
          rutPath.lineTo(cx, cy);
        }
      }
      canvas.drawPath(
        rutPath,
        ui.Paint()
          ..color = baseTone.withAlpha(190)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, w * .0035),
      );
    }
    // Pebbles scattered along the near half.
    for (var i = 0; i < 10; i++) {
      final t = .55 + rng.nextDouble() * .40;
      final cx = pathCenterAt(t) + (rng.nextDouble() - .5) * pathHalfWAt(t) * 1.4;
      final cy = pathYAt(t);
      final r = math.max(0.8, (1 - t) * 2.4 + .5);
      canvas.drawCircle(ui.Offset(cx, cy), r,
          ui.Paint()..color = baseTone.withAlpha(150));
    }
  }

  void _drawCyclone(ui.Canvas canvas, double w, double h) {
    // Sea, foamy bands, and a small strip of ground under the goblin.
    _rect(canvas, 0, h * .54, w, h * .46, const ui.Color(0xFF102D50));
    _rect(canvas, 0, h * .59, w, h * .025, const ui.Color(0xFF24496D));
    _rect(canvas, 0, h * .70, w, h * .018, const ui.Color(0xFF193B62));
    _rect(canvas, 0, h * .83, w, h * .025, const ui.Color(0xFF244A70));
    _rect(canvas, 0, h * .85, w * .47, h * .15, const ui.Color(0xFF294A35));
    // Broken jetty boards and foam gather at the shore beside the goblin.
    for (var i = 0; i < 5; i++) {
      final x = w * (.02 + i * .085);
      _rect(canvas, x, h * (.82 + (i % 2) * .025), w * .10, h * .014,
          const ui.Color(0xFF735039));
      _rect(canvas, x + w * .01, h * (.81 + (i % 2) * .025), w * .008, h * .035,
          const ui.Color(0xFF503B2D));
    }
    for (var i = 0; i < 11; i++) {
      final x =
          (i * w / 11 + _elapsed * _wind * 1.1 * _environmentMotionScale) % w;
      final y = h * (.57 + (i * 13 % 35) / 100);
      final wave = ui.Path()
        ..moveTo(x, y)
        ..lineTo(x + w * .035, y - h * .012)
        ..lineTo(x + w * .075, y + h * .006);
      canvas.drawPath(
          wave,
          ui.Paint()
            ..color = const ui.Color(0xFF71AFC1)
            ..strokeWidth = math.max(1.5, w * .004)
            ..style = ui.PaintingStyle.stroke);
      // A broken white cap gives each swell a readable lit edge.
      _rect(canvas, x + w * .026, y - h * .014, w * .023, h * .006,
          const ui.Color(0xFFB9D8D8));
    }

    // Spiral cloud walls rotate around a growing eye as the storm approaches.
    final approach =
        (_elapsed * _environmentMotionScale / 30).clamp(0.0, 1.0).toDouble();
    final center = ui.Offset(w * .74, h * .30);
    final eye = w * (.045 + .09 * approach);
    final cloudPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = h * .052
      ..strokeCap = ui.StrokeCap.square
      ..strokeJoin = ui.StrokeJoin.miter;
    for (var strand = 0; strand < 3; strand++) {
      final spiral = ui.Path();
      for (var step = 0; step <= 180; step++) {
        final t = step / 180;
        final angle = t * math.pi * 4.4 +
            _elapsed * .46 * _environmentMotionScale +
            strand * math.pi * 2 / 3;
        final radius = eye + t * w * .27;
        final point = ui.Offset(
          center.dx + math.cos(angle) * radius * 1.42,
          center.dy + math.sin(angle) * radius * .72,
        );
        if (step == 0) {
          spiral.moveTo(point.dx, point.dy);
        } else {
          spiral.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
          spiral,
          cloudPaint
            ..color = strand.isEven
                ? const ui.Color(0xFF303B55)
                : const ui.Color(0xFF27334C));
    }
    canvas.drawCircle(
        center, eye, ui.Paint()..color = const ui.Color(0xFF56627A));
    canvas.drawCircle(
        center, eye * .48, ui.Paint()..color = const ui.Color(0xFF8291A2));

    // Palm trunks bow farther as the cyclone strengthens.
    final bend = .055 + .095 * (_wind / 160);
    for (var i = 0; i < 3; i++) {
      final bx = w * (.08 + i * .16);
      final top = ui.Offset(bx + w * bend, h * (.31 + i * .035));
      final base = ui.Offset(bx, h * .86);
      final trunkPath = ui.Path()
        ..moveTo(base.dx, base.dy)
        ..lineTo(top.dx, top.dy)
        ..lineTo(top.dx + w * .018, top.dy)
        ..lineTo(base.dx + w * .028, base.dy)
        ..close();
      canvas.drawPath(
          trunkPath, ui.Paint()..color = const ui.Color(0xFF68442A));
      for (var ring = 0; ring < 4; ring++) {
        final t = .25 + ring * .16;
        final rx = base.dx + (top.dx - base.dx) * t;
        final ry = base.dy + (top.dy - base.dy) * t;
        _rect(canvas, rx, ry, w * .023, h * .008, const ui.Color(0xFF94643A));
      }
      for (var nut = -1; nut <= 1; nut++) {
        canvas.drawCircle(ui.Offset(top.dx + nut * w * .014, top.dy + h * .015),
            w * .009, ui.Paint()..color = const ui.Color(0xFF73502D));
      }
      for (var f = -2; f <= 2; f++) {
        final end = ui.Offset(top.dx + w * (f * .075 - bend * .35),
            top.dy - h * (.025 + (2 - f.abs()) * .025));
        final frond = ui.Path()
          ..moveTo(top.dx, top.dy)
          ..lineTo(end.dx, end.dy)
          ..lineTo(end.dx + w * .025, end.dy + h * .015);
        canvas.drawPath(frond, ui.Paint()..color = const ui.Color(0xFF176044));
        _rect(canvas, end.dx, end.dy, w * .027, h * .009,
            const ui.Color(0xFF3A8A54));
      }
    }
    // Flying boards streak by at varying heights.
    for (var i = 0; i < 5; i++) {
      final x = (w * ((i * 23 % 90) / 100) +
              _elapsed * (_wind * 1.5 + i * 9) * _environmentMotionScale) %
          w;
      final y = h * (.42 + (i * 17 % 35) / 100);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(.3 * math.sin(_elapsed * 4 * _environmentMotionScale + i));
      _rect(canvas, 0, 0, w * .055, h * .014, const ui.Color(0xFF966C42));
      canvas.restore();
    }
  }

  void _drawFlood(ui.Canvas canvas, double w, double h) {
    final p = _floodProgress;
    // Two low-angle houses, built from cuboid walls and wedge-shaped roofs.
    _drawFloodHouse(canvas, w * .055, h * .40, w, h, true);
    _drawFloodHouse(canvas, w * .695, h * .36, w, h, false);
    // Flood line climbs from the street toward the roofs over time.
    final waterTop = h * (.90 - .36 * p);
    _rect(canvas, 0, waterTop, w, h - waterTop, const ui.Color(0xCC70472F));
    _rect(canvas, 0, waterTop, w, h * .018, const ui.Color(0xBFAF7950));
    // Dark tide stains remain above the moving waterline on the plaster walls.
    for (final x in [w * .055, w * .695]) {
      _rect(canvas, x + w * .005, h * .62, w * .18, h * .018,
          const ui.Color(0xFF503E39));
    }
    for (var i = 0; i < 7; i++) {
      final x =
          (w * (i / 7) + _elapsed * (24 + i * 4) * _environmentMotionScale) % w;
      final y = waterTop + h * (.045 + (i % 3) * .055);
      _rect(canvas, x, y, w * .11, h * .012,
          i.isEven ? const ui.Color(0xFF785037) : const ui.Color(0xFF5A4836));
      if (i % 2 == 0) {
        _rect(canvas, x + w * .025, y - h * .022, w * .055, h * .022,
            const ui.Color(0xFF9D744C));
      }
      _rect(canvas, x + w * .018, y + h * .018, w * .035, h * .004,
          const ui.Color(0x889DC4C4));
      if (i % 3 == 1) {
        // A floating crate catches a cool reflection from the storm sky.
        _rect(canvas, x + w * .025, y - h * .026, w * .045, h * .025,
            const ui.Color(0xFF76543A));
        _rect(canvas, x + w * .03, y - h * .022, w * .035, h * .004,
            const ui.Color(0xFFB18455));
        _rect(canvas, x + w * .045, y - h * .025, w * .004, h * .022,
            const ui.Color(0xFF483B31));
      }
    }
    final floor = h * math.min(.82, .88 - .38 * p);
    if (p > .18) {
      final raftX = w * .40;
      _rect(canvas, raftX - w * .075, floor + h * .005, w * .15, h * .022,
          const ui.Color(0xFF8C5B34));
      for (var i = 0; i < 4; i++) {
        _rect(canvas, raftX - w * .07 + i * w * .037, floor + h * .006,
            w * .009, h * .02, const ui.Color(0xFFC38A4C));
      }
    }
  }

  void _drawFloodHouse(
      ui.Canvas canvas, double x, double y, double w, double h, bool warm) {
    _rect(canvas, x, y, w * .17, h * .30,
        warm ? const ui.Color(0xFF74594C) : const ui.Color(0xFF62515A));
    final side = ui.Path()
      ..moveTo(x + w * .17, y)
      ..lineTo(x + w * .235, y - h * .035)
      ..lineTo(x + w * .235, y + h * .265)
      ..lineTo(x + w * .17, y + h * .30)
      ..close();
    canvas.drawPath(side, ui.Paint()..color = const ui.Color(0xFF453C45));

    final roofFront = ui.Path()
      ..moveTo(x - w * .025, y + h * .015)
      ..lineTo(x + w * .082, y - h * .095)
      ..lineTo(x + w * .19, y + h * .015)
      ..close();
    final roofSide = ui.Path()
      ..moveTo(x + w * .082, y - h * .095)
      ..lineTo(x + w * .26, y - h * .075)
      ..lineTo(x + w * .235, y + h * .015)
      ..lineTo(x + w * .19, y + h * .015)
      ..close();
    canvas.drawPath(roofFront, ui.Paint()..color = const ui.Color(0xFF383440));
    canvas.drawPath(roofSide, ui.Paint()..color = const ui.Color(0xFF292C3D));
    _rect(canvas, x - w * .015, y + h * .012, w * .21, h * .012,
        const ui.Color(0xFF927052));
    for (var row = 0; row < 3; row++) {
      final yy = y - h * .062 + row * h * .024;
      for (var tile = 0; tile < 4; tile++) {
        _rect(
            canvas,
            x + w * (.006 + tile * .045 + (row.isOdd ? .02 : 0)),
            yy,
            w * .032,
            h * .009,
            (row + tile).isEven
                ? const ui.Color(0xFF574D59)
                : const ui.Color(0xFF413D4B));
      }
    }

    final glow = warm ? const ui.Color(0xFFFFC977) : const ui.Color(0xFFECA86E);
    for (final wx in [x + w * .022, x + w * .105]) {
      _rect(canvas, wx, y + h * .075, w * .046, h * .075, glow);
      _rect(canvas, wx + w * .020, y + h * .075, w * .006, h * .075,
          const ui.Color(0xFF624A43));
      _rect(canvas, wx, y + h * .108, w * .046, h * .007,
          const ui.Color(0xFF624A43));
      _rect(canvas, wx - w * .008, y + h * .065, w * .062, h * .012,
          const ui.Color(0xFF3B3440));
    }
    _rect(canvas, x + w * .073, y + h * .18, w * .042, h * .12,
        const ui.Color(0xFF392C2B));
    _rect(canvas, x + w * .104, y + h * .23, w * .006, h * .006,
        const ui.Color(0xFFFFD083));
    _rect(canvas, x + w * .19, y - h * .12, w * .022, h * .10,
        const ui.Color(0xFF493E43));
    _rect(canvas, x + w * .185, y - h * .125, w * .032, h * .015,
        const ui.Color(0xFF80706B));
    for (var row = 0; row < 4; row++) {
      _rect(canvas, x + w * .012, y + h * (.17 + row * .026), w * .15, h * .005,
          const ui.Color(0x337F6655));
    }
    _rect(canvas, x + w * .183, y + h * .06, w * .008, h * .16,
        const ui.Color(0xFF332F3A));
  }

  void _drawFloodAlert(
      ui.Canvas canvas, double w, double h, double floor, double p) {
    if (p < .35) return;
    final pulse = reduceFlashing || reduceMotion
        ? 1.0
        : .96 + .04 * math.sin(_elapsed * 3.5);
    // Sits above the raft the character is paddling, not over him.
    final x = w * .40;
    _rect(canvas, x + w * .045, floor - h * .43, w * .052 * pulse,
        h * .095 * pulse, const ui.Color(0xFFCF343A));
    _rect(canvas, x + w * .066, floor - h * .412, w * .010, h * .043,
        const ui.Color(0xFFFFFFFF));
    _rect(canvas, x + w * .066, floor - h * .358, w * .010, h * .012,
        const ui.Color(0xFFFFFFFF));
  }

  void _drawSandstorm(ui.Canvas canvas, double w, double h) {
    // The actual local landmark remains behind these moving dust veils.
    final dune = ui.Path()
      ..moveTo(0, h * .68)
      ..quadraticBezierTo(w * .25, h * .48, w * .48, h * .66)
      ..quadraticBezierTo(w * .76, h * .49, w, h * .67)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(dune, ui.Paint()..color = const ui.Color(0xFFD28A4E));
    // Sparse thorn scrub fits regional drylands without suggesting one exact desert.
    for (var i = 0; i < 3; i++) {
      final x = w * (.12 + i * .34);
      final y = h * (.75 + (i % 2) * .035);
      _rect(canvas, x, y - h * .055, w * .012, h * .06,
          const ui.Color(0xFF62563B));
      _rect(canvas, x - w * .03, y - h * .04, w * .075, h * .01,
          const ui.Color(0xFF877043));
    }
    for (var i = 0; i < 7; i++) {
      final sx = w * (.23 + i * .03);
      final sy = h * (.84 + (i % 2) * .018);
      _rect(canvas, sx, sy, w * .016, h * .007, const ui.Color(0xFF9B623A));
    }
    for (var i = 0; i < 6; i++) {
      final y = h * (.30 + i * .09);
      _rect(canvas, 0, y, w, h * .025,
          ui.Color.fromARGB(20 + i * 3, 255, 206, 133));
    }
  }

  void _drawSkyDetails(ui.Canvas canvas, double w, double h) {
    if (!isDay && !_storm && !_rain && !_fog && _cloudCoverage < 35) {
      final starPaint = ui.Paint()..color = const ui.Color(0xCCEDF5FF);
      for (var i = 0; i < 34; i++) {
        final x = w * ((i * 37 % 97) / 100);
        final y = h * (.035 + (i * 19 % 37) / 100);
        final r = i % 7 == 0 ? 1.8 : 1.0;
        // Each star breathes at its own pace; calm when motion is reduced.
        final twinkle = reduceMotion
            ? 1.0
            : .62 + .38 * math.sin(_elapsed * (1.1 + (i % 5) * .35) + i * 1.7);
        starPaint.color =
            ui.Color.fromARGB((0xCC * twinkle).round().clamp(0, 255), 0xED, 0xF5, 0xFF);
        canvas.drawCircle(ui.Offset(x, y), r, starPaint);
      }
    }
    // Soft bands of pixel clouds and distant haze give the sky depth.
    if (!_storm && !_fog && !_overcast) {
      final haze =
          isDay ? const ui.Color(0x223B8FAD) : const ui.Color(0x221B3154);
      _rect(canvas, 0, h * .43, w, h * .045, haze);
      _rect(canvas, w * .08, h * .37, w * .22, h * .018,
          const ui.Color(0x1FFFFFFF));
      _rect(canvas, w * .63, h * .32, w * .26, h * .014,
          const ui.Color(0x1FFFFFFF));
    }
  }

  /// Horizontal shift applied to landmark artwork, as a fraction of width.
  ///
  /// Measured footprints showed every landmark straddling the centre, so the
  /// character always overlapped whatever the landmark exists to show. Nudging
  /// the landmark left frees the right third of the scene as a character lane.
  static const double _landmarkShiftX = -.025;

  /// Base parallax magnification for the mid-ground, in scene-width fractions
  /// per unit of normalised wind. Distant layers use a smaller factor and the
  /// character's own layer stays fixed, so wind reads as depth rather than as a
  /// sliding picture.
  static const double _parallaxMidScale = .022;

  /// Lateral offset for the mid-ground layer, in logical pixels.
  ///
  /// Wind pushes near layers further than far ones. Everything is anchored to
  /// the scene centre so nothing drifts off the left edge on a strong blow.
  double _parallaxMidOffset(double w) {
    final wind = (_wind / 160).clamp(0.0, 1.0).toDouble();
    // The wind bearing decides which way the near layers lean. Only the sign
    // matters: a wind blowing across the scene still pushes it sideways.
    final bearing = math.cos(windDirectionDeg * math.pi / 180);
    final direction = bearing == 0 ? 1.0 : bearing.sign;
    final magnitude = w * _parallaxMidScale * wind;
    return magnitude * direction * _environmentMotionScale;
  }

  /// Landmark selection is stable for a city; weather and season are layered
  /// around it so the location remains recognizable after refreshes.
  void _drawCatalogLandmark(ui.Canvas canvas, double w, double h) {
    canvas.save();
    canvas.translate(w * _landmarkShiftX, 0);
    _drawCatalogLandmarkArt(canvas, w, h);
    canvas.restore();
  }

  void _drawCatalogLandmarkArt(ui.Canvas canvas, double w, double h) {
    final stone = !isDay
        ? const ui.Color(0xFF647283)
        : _winterWorld
            ? const ui.Color(0xFFB9C9CF)
            : _storm || _overcast
                ? const ui.Color(0xFF777E7D)
                : const ui.Color(0xFFC79B69);
    final darkStone = const ui.Color(0xFF54473E);
    final goldStone =
        isDay ? const ui.Color(0xFFE5B850) : const ui.Color(0xFF8B7048);
    final water = !isDay || _storm
        ? const ui.Color(0xFF24465F)
        : const ui.Color(0xFF347F94);
    switch (location.landmark) {
      case WorldLandmark.none:
        _drawRegionalFallback(canvas, w, h, stone, darkStone, water);
      case WorldLandmark.tajMahal:
        _drawTajMahal(canvas, w, h);
      case WorldLandmark.jaisalmerFort:
        _drawJaisalmerFort(canvas, w, h);
      case WorldLandmark.hawaMahal:
        _rect(canvas, w * .24, h * .40, w * .52, h * .19,
            const ui.Color(0xFFC97867));
        _rect(canvas, w * .29, h * .365, w * .42, h * .05,
            const ui.Color(0xFFD78D78));
        for (var row = 0; row < 4; row++) {
          for (var col = 0; col < 7; col++) {
            final x = w * (.285 + col * .061);
            final y = h * (.425 + row * .037);
            _rect(canvas, x, y, w * .027, h * .025, const ui.Color(0xFF543F3D));
            _rect(canvas, x + w * .005, y + h * .005, w * .017, h * .014,
                const ui.Color(0xFFE6B6A2));
          }
        }
        for (var i = 0; i < 5; i++) {
          final x = w * (.30 + i * .10);
          _rect(canvas, x, h * .345, w * .055, h * .026,
              const ui.Color(0xFFB96455));
          canvas.drawCircle(ui.Offset(x + w * .027, h * .344), w * .027,
              ui.Paint()..color = const ui.Color(0xFFD78D78));
        }
      case WorldLandmark.indiaGate:
      case WorldLandmark.gatewayOfIndia:
        final gateway = location.landmark == WorldLandmark.gatewayOfIndia;
        final color = gateway ? const ui.Color(0xFFB78A5B) : stone;
        _rect(canvas, w * .34, h * .43, w * .32, h * .15, color);
        _rect(canvas, w * .29, h * .40, w * .42, h * .035, color);
        _rect(canvas, w * .40, h * .455, w * .20, h * .125, darkStone);
        final arch = ui.Path()
          ..moveTo(w * .405, h * .58)
          ..lineTo(w * .405, h * .485)
          ..quadraticBezierTo(w * .50, h * .39, w * .595, h * .485)
          ..lineTo(w * .595, h * .58)
          ..close();
        canvas.drawPath(arch, ui.Paint()..color = color);
        _rect(canvas, w * .465, h * .48, w * .07, h * .10, darkStone);
        _rect(canvas, w * .28, h * .58, w * .44, h * .018,
            const ui.Color(0xFF7B6048));
        if (gateway) {
          _rect(canvas, 0, h * .68, w, h * .22, water);
          for (var i = 0; i < 5; i++) {
            _rect(canvas, w * (.08 + i * .18), h * (.72 + (i % 2) * .06),
                w * .07, h * .006, const ui.Color(0x887ED9D6));
          }
        } else {
          _rect(canvas, w * .47, h * .61, w * .06, h * .06,
              const ui.Color(0xFFFFD889));
        }
      case WorldLandmark.howrahBridge:
        _rect(canvas, 0, h * .72, w, h * .20, water);
        _rect(canvas, w * .04, h * .55, w * .92, h * .025,
            const ui.Color(0xFF6E6254));
        for (var i = 0; i < 7; i++) {
          final x = w * (.08 + i * .135);
          _rect(canvas, x, h * .38, w * .018, h * .19, stone);
          _rect(canvas, x - w * .018, h * .37, w * .055, h * .018, stone);
          _rect(canvas, x - w * .018, h * .42, w * .055, h * .012, darkStone);
        }
        for (var i = 0; i < 8; i++) {
          final x = w * (.08 + i * .12);
          canvas.drawLine(
              ui.Offset(x, h * .40),
              ui.Offset(x + w * .12, h * .55),
              ui.Paint()
                ..color = const ui.Color(0xFF9D927C)
                ..strokeWidth = 1.4);
          canvas.drawLine(
              ui.Offset(x, h * .55),
              ui.Offset(x + w * .12, h * .40),
              ui.Paint()
                ..color = const ui.Color(0xFF9D927C)
                ..strokeWidth = 1.1);
        }
      case WorldLandmark.varanasiGhats:
      case WorldLandmark.bhopalLake:
        _rect(canvas, 0, h * .65, w, h * .28, water);
        for (var i = 0; i < 8; i++) {
          final x = w * (.04 + i * .12);
          final top = h * (.46 + (i % 3) * .035);
          _rect(canvas, x, top, w * .15, h * .65 - top,
              i.isEven ? stone : const ui.Color(0xFF9C7958));
          _rect(canvas, x - w * .01, top - h * .025, w * .17, h * .025,
              darkStone);
          _rect(canvas, x + w * .04, top + h * .10, w * .018, h * .04,
              const ui.Color(0xFFFFCC73));
        }
        if (location.landmark == WorldLandmark.bhopalLake) {
          _rect(canvas, w * .42, h * .46, w * .16, h * .14, stone);
          _rect(canvas, w * .39, h * .43, w * .22, h * .035, goldStone);
          _rect(canvas, w * .47, h * .40, w * .06, h * .035, stone);
        } else {
          _rect(canvas, w * .46, h * .39, w * .08, h * .26, stone);
          final dome = ui.Path()
            ..moveTo(w * .46, h * .40)
            ..quadraticBezierTo(w * .50, h * .32, w * .54, h * .40)
            ..close();
          canvas.drawPath(dome, ui.Paint()..color = goldStone);
        }
        _rect(canvas, w * .17, h * .82, w * .11, h * .012,
            const ui.Color(0xFF704A34));
        _rect(canvas, w * .21, h * .78, w * .012, h * .045,
            const ui.Color(0xFF704A34));
      case WorldLandmark.goldenTemple:
        _rect(canvas, w * .16, h * .62, w * .68, h * .24,
            const ui.Color(0xFF29485B));
        for (var i = 0; i < 6; i++) {
          _rect(canvas, w * (.20 + i * .115), h * (.69 + (i % 2) * .06),
              w * .075, h * .006, const ui.Color(0x77E7EBC9));
        }
        _rect(canvas, w * .36, h * .46, w * .28, h * .18,
            const ui.Color(0xFFAA772C));
        _rect(canvas, w * .33, h * .44, w * .34, h * .035, goldStone);
        _rect(canvas, w * .43, h * .39, w * .14, h * .07, goldStone);
        canvas.drawOval(ui.Rect.fromLTWH(w * .43, h * .355, w * .14, h * .075),
            ui.Paint()..color = const ui.Color(0xFFFFD35F));
        _rect(canvas, w * .485, h * .335, w * .03, h * .03, goldStone);
      case WorldLandmark.charminar:
        _rect(canvas, w * .36, h * .46, w * .28, h * .14, stone);
        _rect(canvas, w * .32, h * .44, w * .36, h * .035, goldStone);
        for (final x in [w * .25, w * .34, w * .62, w * .71]) {
          _rect(canvas, x, h * .34, w * .035, h * .26, stone);
          _rect(canvas, x - w * .012, h * .39, w * .06, h * .012, goldStone);
          _rect(canvas, x - w * .012, h * .47, w * .06, h * .012, goldStone);
          canvas.drawCircle(ui.Offset(x + w * .017, h * .34), w * .027,
              ui.Paint()..color = goldStone);
          _rect(canvas, x + w * .012, h * .31, w * .01, h * .035, stone);
        }
        _rect(canvas, w * .455, h * .51, w * .09, h * .09, darkStone);
      case WorldLandmark.chennaiLighthouse:
        _rect(canvas, 0, h * .67, w, h * .26, water);
        _rect(canvas, w * .62, h * .38, w * .10, h * .30,
            const ui.Color(0xFFE8D9BC));
        _rect(canvas, w * .59, h * .36, w * .16, h * .035,
            const ui.Color(0xFFC35048));
        _rect(canvas, w * .64, h * .31, w * .06, h * .05,
            const ui.Color(0xFFC35048));
        _rect(canvas, w * .65, h * .28, w * .04, h * .03,
            const ui.Color(0xFFFFE59B));
        for (var i = 0; i < 4; i++) {
          _rect(canvas, w * (.08 + i * .09), h * (.80 + (i % 2) * .05), w * .06,
              h * .006, const ui.Color(0x887ED9D6));
        }
      case WorldLandmark.bengaluruPalace:
        _rect(canvas, w * .22, h * .46, w * .56, h * .16,
            const ui.Color(0xFF886C4C));
        _rect(canvas, w * .18, h * .43, w * .64, h * .035,
            const ui.Color(0xFF513D36));
        for (var i = 0; i < 5; i++) {
          final x = w * (.23 + i * .12);
          _rect(canvas, x, h * .38, w * .035, h * .08,
              const ui.Color(0xFFB17F56));
          _rect(canvas, x - w * .01, h * .37, w * .055, h * .018,
              const ui.Color(0xFF5C4335));
          _rect(canvas, x + w * .012, h * .50, w * .014, h * .045,
              const ui.Color(0xFFFFD58A));
        }
        for (var i = 0; i < 4; i++) {
          _drawPixelTree(canvas, w * (.08 + i * .19), h * .63, w * .13, h * .23,
              const ui.Color(0xFF286844), false);
        }
      case WorldLandmark.kochiFishingNets:
        _rect(canvas, 0, h * .68, w, h * .27, water);
        for (var i = 0; i < 3; i++) {
          final x = w * (.17 + i * .29);
          _rect(canvas, x, h * .36, w * .012, h * .36, darkStone);
          _rect(canvas, x + w * .12, h * .39, w * .012, h * .33, darkStone);
          canvas.drawLine(
              ui.Offset(x, h * .38),
              ui.Offset(x + w * .12, h * .65),
              ui.Paint()
                ..color = stone
                ..strokeWidth = 1.5);
          for (var j = 0; j < 5; j++) {
            canvas.drawLine(
                ui.Offset(x + w * (.015 + j * .022), h * .42),
                ui.Offset(x + w * (.12 - j * .018), h * .64),
                ui.Paint()
                  ..color = const ui.Color(0xFFB4A083)
                  ..strokeWidth = 1);
          }
        }
        _rect(canvas, w * .58, h * .79, w * .18, h * .025,
            const ui.Color(0xFF80543B));
        _rect(canvas, w * .63, h * .75, w * .06, h * .04,
            const ui.Color(0xFFAD7951));
      case WorldLandmark.srinagarLake:
        _drawMountainRange(canvas, w, h, true);
        _rect(canvas, 0, h * .69, w, h * .24, water);
        _rect(canvas, w * .12, h * .62, w * .28, h * .10,
            const ui.Color(0xFF765A43));
        _rect(canvas, w * .09, h * .59, w * .34, h * .035,
            const ui.Color(0xFF503B32));
        _rect(canvas, w * .20, h * .55, w * .12, h * .045,
            const ui.Color(0xFF926D4A));
        _rect(canvas, w * .18, h * .545, w * .16, h * .014,
            const ui.Color(0xFF4A382F));
        for (var i = 0; i < 4; i++) {
          _rect(canvas, w * (.52 + i * .09), h * (.78 + (i % 2) * .04), w * .05,
              h * .004, const ui.Color(0x887ED9D6));
        }
      case WorldLandmark.shimlaHills:
        _drawMountainRange(canvas, w, h, _snow || _winterWorld);
        for (var i = 0; i < 5; i++) {
          final x = w * (.08 + i * .18);
          final y = h * (.48 + (i % 2) * .055);
          _rect(canvas, x, y, w * .13, h * .14, const ui.Color(0xFFB99168));
          _rect(canvas, x - w * .012, y - h * .026, w * .155, h * .035,
              const ui.Color(0xFF573C35));
          _rect(canvas, x + w * .045, y + h * .045, w * .022, h * .055,
              const ui.Color(0xFFFFD58A));
        }
        for (var i = 0; i < 4; i++) {
          _drawPixelTree(canvas, w * (.04 + i * .24), h * .66, w * .12, h * .25,
              const ui.Color(0xFF24533E), _snow || _winterWorld);
        }
      case WorldLandmark.lehMonastery:
        _drawMountainRange(canvas, w, h, _snow || _winterWorld);
        _rect(canvas, w * .26, h * .44, w * .48, h * .18,
            const ui.Color(0xFFB99568));
        _rect(canvas, w * .22, h * .41, w * .56, h * .04,
            const ui.Color(0xFF8E4939));
        _rect(canvas, w * .36, h * .34, w * .28, h * .09,
            const ui.Color(0xFFC9A679));
        _rect(canvas, w * .32, h * .32, w * .36, h * .03,
            const ui.Color(0xFF8E4939));
        _rect(canvas, w * .45, h * .50, w * .10, h * .12, darkStone);
        for (var i = 0; i < 5; i++) {
          _rect(canvas, w * (.31 + i * .085), h * .47, w * .028, h * .035,
              const ui.Color(0xFFFFD58A));
        }
      case WorldLandmark.rishikeshBridge:
        _rect(canvas, 0, h * .66, w, h * .28, water);
        _rect(canvas, w * .08, h * .53, w * .84, h * .024,
            const ui.Color(0xFF7C6349));
        for (final x in [w * .20, w * .78]) {
          _rect(canvas, x, h * .39, w * .025, h * .20,
              const ui.Color(0xFF72583F));
          _rect(canvas, x - w * .018, h * .38, w * .06, h * .025,
              const ui.Color(0xFF8C6C4A));
          canvas.drawLine(
              ui.Offset(x + w * .012, h * .40),
              ui.Offset(w * .50, h * .54),
              ui.Paint()
                ..color = const ui.Color(0xFFD5B887)
                ..strokeWidth = 1.4);
        }
        for (var i = 0; i < 5; i++) {
          _rect(canvas, w * (.29 + i * .09), h * .53, w * .006, h * .08,
              const ui.Color(0xFF9C815D));
        }
      case WorldLandmark.eiffelTower:
        final tower = ui.Path()
          ..moveTo(w * .50, h * .28)
          ..lineTo(w * .39, h * .62)
          ..lineTo(w * .61, h * .62)
          ..close();
        canvas.drawPath(tower, ui.Paint()..color = darkStone);
        _rect(canvas, w * .455, h * .41, w * .09, h * .015, stone);
        _rect(canvas, w * .43, h * .50, w * .14, h * .018, stone);
        _rect(canvas, w * .36, h * .61, w * .28, h * .02, darkStone);
        _rect(canvas, w * .492, h * .23, w * .016, h * .07, stone);
        _rect(canvas, w * .46, h * .62, w * .08, h * .06, darkStone);
        _rect(canvas, w * .44, h * .68, w * .12, h * .22, water);
        break;
      case WorldLandmark.bigBen:
        _rect(canvas, w * .57, h * .30, w * .16, h * .38,
            const ui.Color(0xFF7C775F));
        _rect(canvas, w * .55, h * .27, w * .20, h * .045,
            const ui.Color(0xFF9A916F));
        _rect(canvas, w * .59, h * .23, w * .12, h * .04,
            const ui.Color(0xFF6D6653));
        _rect(canvas, w * .62, h * .19, w * .06, h * .04,
            const ui.Color(0xFF9A916F));
        _rect(canvas, w * .605, h * .35, w * .07, h * .07,
            const ui.Color(0xFFFFE8A6));
        canvas.drawCircle(ui.Offset(w * .64, h * .385), w * .024,
            ui.Paint()..color = const ui.Color(0xFF634E36));
        _rect(canvas, 0, h * .70, w, h * .20, water);
        _rect(canvas, w * .08, h * .66, w * .84, h * .018,
            const ui.Color(0xFF74563C));
      case WorldLandmark.newYorkSkyline:
      case WorldLandmark.singaporeSkyline:
      case WorldLandmark.dubaiTower:
        _rect(
            canvas,
            0,
            h * .69,
            w,
            h * .23,
            location.landmark == WorldLandmark.singaporeSkyline
                ? water
                : const ui.Color(0xFF334E60));
        for (var i = 0; i < 9; i++) {
          final x = w * (.03 + i * .105);
          final buildingH = h * (.13 + (i * 7 % 18) / 100);
          _rect(
              canvas,
              x,
              h * .67 - buildingH,
              w * .085,
              buildingH,
              i.isEven
                  ? const ui.Color(0xFF596779)
                  : const ui.Color(0xFF796B5E));
          for (var row = 0; row < 4; row++) {
            _rect(canvas, x + w * .018, h * .53 + row * h * .025, w * .012,
                h * .010, const ui.Color(0xFFFFD78B));
          }
        }
        if (location.landmark == WorldLandmark.dubaiTower) {
          final tower = ui.Path()
            ..moveTo(w * .53, h * .12)
            ..lineTo(w * .47, h * .68)
            ..lineTo(w * .61, h * .68)
            ..close();
          canvas.drawPath(
              tower, ui.Paint()..color = const ui.Color(0xFF9EAAAE));
          _rect(canvas, w * .525, h * .08, w * .01, h * .06,
              const ui.Color(0xFFCBD4CF));
        } else if (location.landmark == WorldLandmark.newYorkSkyline) {
          _rect(canvas, w * .82, h * .43, w * .045, h * .18,
              const ui.Color(0xFF62899A));
          canvas.drawCircle(ui.Offset(w * .843, h * .40), w * .03,
              ui.Paint()..color = const ui.Color(0xFF62899A));
          _rect(canvas, w * .80, h * .35, w * .085, h * .018,
              const ui.Color(0xFF62899A));
        }
      case WorldLandmark.tokyoFuji:
        _drawMountainRange(canvas, w, h, true);
        final fuji = ui.Path()
          ..moveTo(w * .58, h * .55)
          ..lineTo(w * .78, h * .24)
          ..lineTo(w * .96, h * .55)
          ..close();
        canvas.drawPath(fuji, ui.Paint()..color = const ui.Color(0xFF536778));
        final cap = ui.Path()
          ..moveTo(w * .72, h * .34)
          ..lineTo(w * .78, h * .24)
          ..lineTo(w * .85, h * .36)
          ..lineTo(w * .80, h * .34)
          ..lineTo(w * .77, h * .38)
          ..close();
        canvas.drawPath(cap, ui.Paint()..color = const ui.Color(0xFFE9F1EF));
        _rect(canvas, w * .10, h * .56, w * .25, h * .07,
            const ui.Color(0xFF7C4B40));
        _rect(canvas, w * .08, h * .54, w * .29, h * .025,
            const ui.Color(0xFF47352F));
        for (var i = 0; i < 4; i++) {
          _rect(canvas, w * (.13 + i * .055), h * .575, w * .012, h * .025,
              const ui.Color(0xFFFFD58A));
        }
      case WorldLandmark.colosseum:
        _rect(canvas, w * .20, h * .40, w * .60, h * .22,
            const ui.Color(0xFFB28B62));
        _rect(canvas, w * .17, h * .38, w * .66, h * .035,
            const ui.Color(0xFF806249));
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 7; col++) {
            final x = w * (.235 + col * .077);
            final y = h * (.44 + row * .085);
            _rect(canvas, x, y, w * .038, h * .065, darkStone);
            canvas.drawArc(
                ui.Rect.fromLTWH(x, y - h * .025, w * .038, h * .05),
                math.pi,
                math.pi,
                false,
                ui.Paint()
                  ..color = const ui.Color(0xFFB28B62)
                  ..style = ui.PaintingStyle.stroke
                  ..strokeWidth = 2);
          }
        }
      case WorldLandmark.cairoPyramids:
        _drawPyramids(canvas, w, h);
      case WorldLandmark.sydneyOperaHouse:
        _rect(canvas, 0, h * .69, w, h * .23, water);
        _rect(canvas, w * .15, h * .64, w * .70, h * .04,
            const ui.Color(0xFF74614C));
        for (var i = 0; i < 4; i++) {
          final x = w * (.25 + i * .13);
          final sail = ui.Path()
            ..moveTo(x, h * .63)
            ..quadraticBezierTo(
                x + w * .035, h * (.34 + i % 2 * .035), x + w * .09, h * .63)
            ..close();
          canvas.drawPath(sail, ui.Paint()..color = const ui.Color(0xFFE8E0CB));
          canvas.drawLine(
              ui.Offset(x + w * .045, h * .39),
              ui.Offset(x + w * .045, h * .63),
              ui.Paint()
                ..color = const ui.Color(0xFFAAA797)
                ..strokeWidth = 1);
        }
      case WorldLandmark.rioMountain:
        _drawMountainRange(canvas, w, h, false);
        final hill = ui.Path()
          ..moveTo(w * .20, h * .67)
          ..quadraticBezierTo(w * .28, h * .42, w * .48, h * .51)
          ..quadraticBezierTo(w * .63, h * .39, w * .83, h * .67)
          ..close();
        canvas.drawPath(hill, ui.Paint()..color = const ui.Color(0xFF446C59));
        canvas.drawLine(
            ui.Offset(w * .56, h * .35),
            ui.Offset(w * .56, h * .55),
            ui.Paint()
              ..color = const ui.Color(0xFFE8E2D5)
              ..strokeWidth = 3);
        canvas.drawLine(
            ui.Offset(w * .51, h * .41),
            ui.Offset(w * .61, h * .41),
            ui.Paint()
              ..color = const ui.Color(0xFFE8E2D5)
              ..strokeWidth = 3);
        _rect(canvas, 0, h * .73, w, h * .18, water);
    }
  }

  void _drawMountainRange(ui.Canvas canvas, double w, double h, bool snowy) {
    for (var i = 0; i < 4; i++) {
      final left = w * (.02 + i * .24);
      final peak = left + w * (.14 + (i % 2) * .04);
      final right = left + w * .30;
      final baseY = h * (.59 + (i % 2) * .035);
      final peakY = h * (.25 + (i % 3) * .045);
      final mountain = ui.Path()
        ..moveTo(left, baseY)
        ..lineTo(peak, peakY)
        ..lineTo(right, baseY)
        ..close();
      canvas.drawPath(mountain,
          ui.Paint()..color = const ui.Color(0xFF596D72).withValues(alpha: .72));
      if (snowy) {
        final cap = ui.Path()
          ..moveTo(peak - w * .055, peakY + h * .095)
          ..lineTo(peak, peakY)
          ..lineTo(peak + w * .055, peakY + h * .095)
          ..lineTo(peak + w * .018, peakY + h * .075)
          ..lineTo(peak, peakY + h * .09)
          ..lineTo(peak - w * .018, peakY + h * .07)
          ..close();
        canvas.drawPath(cap, ui.Paint()..color = const ui.Color(0xFFDCEAF0));
      }
    }
  }

  void _drawPyramids(ui.Canvas canvas, double w, double h) {
    final sand = const ui.Color(0xFFD4A461);
    for (var i = 0; i < 3; i++) {
      final left = w * (.15 + i * .24);
      final peakX = left + w * (.12 + (i % 2) * .03);
      final baseY = h * (.63 + (i % 2) * .02);
      final peakY = h * (.35 + (i % 2) * .035);
      final pyramid = ui.Path()
        ..moveTo(left, baseY)
        ..lineTo(peakX, peakY)
        ..lineTo(left + w * .24, baseY)
        ..close();
      canvas.drawPath(pyramid, ui.Paint()..color = sand);
      canvas.drawLine(
          ui.Offset(peakX, peakY),
          ui.Offset(peakX, baseY),
          ui.Paint()
            ..color = const ui.Color(0x6684513A)
            ..strokeWidth = 1.2);
    }
  }

  /// Regional fallback scene for cities without a catalogued landmark.
  ///
  /// Every biome now varies by city: the climate zone selects the tree
  /// species, and a per-location seed varies how many trees are drawn, how
  /// tall they are, and the exact tint of the skyline or canopy. Two temperate
  /// towns no longer render as the same field of identical trees.
  void _drawRegionalFallback(ui.Canvas canvas, double w, double h,
      ui.Color stone, ui.Color darkStone, ui.Color water) {
    final climate = location.climate;
    final tree = location.defaultTree;
    final seed = worldLocationSeed(location);
    final rng = math.Random(seed);
    final treeCount = 5 + rng.nextInt(4);
    final spanW = 0.94 / treeCount;

    switch (location.biome) {
      case WorldBiome.desert:
        final dune = ui.Path()
          ..moveTo(0, h * .72)
          ..quadraticBezierTo(w * .28, h * .61, w * .53, h * .72)
          ..quadraticBezierTo(w * .80, h * .82, w, h * .66)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(dune, ui.Paint()..color = const ui.Color(0xFFD6A157));
        for (var i = 0; i < treeCount; i++) {
          final x = w * (0.05 + i * spanW + rng.nextDouble() * 0.02);
          final treeW = w * (.08 + rng.nextDouble() * .05);
          final treeH = h * (.14 + rng.nextDouble() * .06);
          _drawClimateTree(canvas, x, h * .72, treeW, treeH, tree);
        }
      case WorldBiome.coldDesert:
      case WorldBiome.mountain:
        _drawMountainRange(canvas, w, h, _snow || _winterWorld);
        for (var i = 0; i < treeCount; i++) {
          final x = w * (0.05 + i * spanW + rng.nextDouble() * 0.02);
          final treeW = w * (.10 + rng.nextDouble() * .06);
          final treeH = h * (.20 + rng.nextDouble() * .10);
          _drawClimateTree(canvas, x, h * .70, treeW, treeH,
              climate == ClimateZone.alpine ? TreeSpecies.pine : tree,
              snowy: _snow || _winterWorld);
        }
      case WorldBiome.coastal:
        _rect(canvas, 0, h * .65, w, h * .30, water);
        for (var i = 0; i < 5; i++) {
          _rect(canvas, w * (.05 + i * .10), h * (.72 + (i % 2) * .05),
              w * .09, h * .005, const ui.Color(0x887ED9D6));
        }
        for (var i = 0; i < treeCount; i++) {
          final x = w * (0.06 + i * spanW + rng.nextDouble() * 0.02);
          final treeW = w * (.09 + rng.nextDouble() * .05);
          final treeH = h * (.16 + rng.nextDouble() * .07);
          _drawClimateTree(canvas, x, h * .66, treeW, treeH, tree,
              autumn: _autumnWorld, spring: _springWorld);
        }
      case WorldBiome.river:
        _rect(canvas, 0, h * .68, w, h * .27, water);
        _rect(canvas, w * .06, h * .56, w * .88, h * .018, stone);
        for (var i = 0; i < treeCount; i++) {
          final x = w * (0.06 + i * spanW + rng.nextDouble() * 0.02);
          final treeW = w * (.09 + rng.nextDouble() * .05);
          final treeH = h * (.18 + rng.nextDouble() * .08);
          _drawClimateTree(canvas, x, h * .68, treeW, treeH, tree,
              autumn: _autumnWorld, spring: _springWorld,
              snowy: _snow || _winterWorld);
        }
      case WorldBiome.urban:
        // A skyline that varies in height, massing, and colour by city seed.
        final baseHue = 0xFF596779 + (rng.nextInt(0x18) << 8) - 0x0C00;
        for (var i = 0; i < 8; i++) {
          final x = w * (.02 + i * .12);
          final buildingH = h * (.13 + ((i * 5 + rng.nextInt(11)) % 18) / 100);
          final color = ui.Color(baseHue).withValues(
              alpha: 1.0 - (i % 3) * 0.08);
          _rect(canvas, x, h * .66 - buildingH, w * .10, buildingH,
              i.isEven ? color : stone);
          for (var row = 0; row < 3; row++) {
            _rect(canvas, x + w * .025, h * .53 + row * h * .035,
                w * .018, h * .014, const ui.Color(0xFFFFD58A));
          }
        }
      case WorldBiome.tropical:
        // Palms along a shore, varying count and height per city.
        _rect(canvas, 0, h * .78, w, h * .22, water);
        _rect(canvas, 0, h * .78, w, h * .008, const ui.Color(0xFF9FBFB3));
        for (var i = 0; i < treeCount; i++) {
          final x = w * (0.05 + i * spanW + rng.nextDouble() * 0.02);
          final treeW = w * (.09 + rng.nextDouble() * .05);
          final treeH = h * (.20 + rng.nextDouble() * .08);
          _drawClimateTree(canvas, x, h * .78, treeW, treeH,
              TreeSpecies.palm);
        }
      case WorldBiome.temperate:
        // The one the user complained about. Now varies by species, count,
        // height, and colour so two temperate cities do not look the same.
        for (var i = 0; i < treeCount; i++) {
          final x = w * (0.04 + i * spanW + rng.nextDouble() * 0.02);
          final treeW = w * (.10 + rng.nextDouble() * .06);
          final treeH = h * (.18 + rng.nextDouble() * .10);
          _drawClimateTree(canvas, x, h * .70, treeW, treeH, tree,
              autumn: _autumnWorld, spring: _springWorld,
              snowy: _snow || _winterWorld);
        }
    }
  }

  void _drawTajMahal(ui.Canvas canvas, double w, double h) {
    final marble = !isDay
        ? const ui.Color(0xFF718093)
        : _storm
            ? const ui.Color(0xFFBCC9CC)
            : _winterWorld
                ? const ui.Color(0xFFE7F0EE)
                : const ui.Color(0xFFF0E7D4);
    final shade = !isDay
        ? const ui.Color(0xFF46566D)
        : _storm
            ? const ui.Color(0xFF7B929A)
            : const ui.Color(0xFFB9B4A6);
    final dark =
        !isDay ? const ui.Color(0xFF18253B) : const ui.Color(0xFF354357);

    // Long marble plinth and its dark water channel establish the symmetry.
    _rect(canvas, w * .25, h * .565, w * .50, h * .018, dark);
    _rect(canvas, w * .30, h * .535, w * .40, h * .038, marble);
    _rect(canvas, w * .28, h * .525, w * .44, h * .014, shade);
    _rect(canvas, w * .34, h * .548, w * .32, h * .010, shade);

    // Main mausoleum body, central pointed arch, and onion dome.
    _rect(canvas, w * .385, h * .415, w * .23, h * .12, marble);
    _rect(canvas, w * .37, h * .405, w * .26, h * .018, shade);
    final dome = ui.Path()
      ..moveTo(w * .435, h * .415)
      ..quadraticBezierTo(w * .435, h * .335, w * .50, h * .315)
      ..quadraticBezierTo(w * .565, h * .335, w * .565, h * .415)
      ..close();
    canvas.drawPath(dome, ui.Paint()..color = marble);
    _rect(canvas, w * .493, h * .295, w * .014, h * .025, shade);
    _rect(canvas, w * .486, h * .289, w * .028, h * .008,
        const ui.Color(0xFFD8B765));

    final arch = ui.Path()
      ..moveTo(w * .465, h * .535)
      ..lineTo(w * .465, h * .465)
      ..quadraticBezierTo(w * .50, h * .425, w * .535, h * .465)
      ..lineTo(w * .535, h * .535)
      ..close();
    canvas.drawPath(arch, ui.Paint()..color = dark);
    _rect(canvas, w * .425, h * .445, w * .018, h * .025, shade);
    _rect(canvas, w * .557, h * .445, w * .018, h * .025, shade);

    // Four minarets with balcony bands and tiny domed caps.
    for (final x in [w * .315, w * .355, w * .645, w * .685]) {
      _rect(canvas, x, h * .345, w * .014, h * .19, marble);
      _rect(canvas, x - w * .006, h * .385, w * .026, h * .008, shade);
      _rect(canvas, x - w * .006, h * .455, w * .026, h * .008, shade);
      _rect(canvas, x - w * .006, h * .337, w * .026, h * .012, marble);
      _rect(canvas, x + w * .004, h * .322, w * .006, h * .016, shade);
    }
    // Small chhatris, corner inlay, and a broken reflection in the channel.
    for (final x in [w * .405, w * .57]) {
      _rect(canvas, x, h * .375, w * .025, h * .03, marble);
      canvas.drawOval(
        ui.Rect.fromLTWH(x, h * .365, w * .025, h * .018),
        ui.Paint()..color = shade,
      );
    }
    for (var i = 0; i < 5; i++) {
      _rect(canvas, w * (.39 + i * .045), h * .43, w * .008, h * .008,
          const ui.Color(0xFFC77962));
      _rect(canvas, w * (.37 + i * .06), h * .59, w * .03, h * .006,
          const ui.Color(0xFF85AAB0));
    }
  }

  void _drawJaisalmerFort(ui.Canvas canvas, double w, double h) {
    final sandstone =
        _storm ? const ui.Color(0xFF9C7657) : const ui.Color(0xFFD29A52);
    final light = const ui.Color(0xFFE6B96F);
    final shadow = const ui.Color(0xFF815334);
    final dark = const ui.Color(0xFF493629);

    // The fort sits on a stepped sandstone hill above the desert town.
    final hill = ui.Path()
      ..moveTo(w * .17, h * .59)
      ..lineTo(w * .24, h * .535)
      ..lineTo(w * .77, h * .535)
      ..lineTo(w * .84, h * .59)
      ..close();
    canvas.drawPath(hill, ui.Paint()..color = shadow);

    final wall = ui.Path()
      ..moveTo(w * .22, h * .545)
      ..lineTo(w * .22, h * .425)
      ..lineTo(w * .27, h * .425)
      ..lineTo(w * .27, h * .395)
      ..lineTo(w * .32, h * .395)
      ..lineTo(w * .32, h * .42)
      ..lineTo(w * .40, h * .42)
      ..lineTo(w * .40, h * .375)
      ..lineTo(w * .46, h * .375)
      ..lineTo(w * .46, h * .405)
      ..lineTo(w * .55, h * .405)
      ..lineTo(w * .55, h * .37)
      ..lineTo(w * .62, h * .37)
      ..lineTo(w * .62, h * .41)
      ..lineTo(w * .70, h * .41)
      ..lineTo(w * .70, h * .39)
      ..lineTo(w * .76, h * .39)
      ..lineTo(w * .76, h * .545)
      ..close();
    canvas.drawPath(wall, ui.Paint()..color = sandstone);
    _rect(canvas, w * .235, h * .45, w * .50, h * .018, light);
    _rect(canvas, w * .22, h * .535, w * .54, h * .012, shadow);

    // Rounded bastions, crenellations, and inset slit windows.
    for (final x in [w * .20, w * .37, w * .53, w * .72]) {
      _rect(canvas, x, h * .435, w * .075, h * .11, sandstone);
      canvas.drawOval(
        ui.Rect.fromLTWH(x, h * .405, w * .075, h * .065),
        ui.Paint()..color = light,
      );
      _rect(canvas, x + w * .014, h * .47, w * .008, h * .025, dark);
      _rect(canvas, x + w * .052, h * .47, w * .008, h * .025, dark);
      _rect(canvas, x + w * .006, h * .445, w * .012, h * .01, light);
      _rect(canvas, x + w * .031, h * .445, w * .012, h * .01, light);
      _rect(canvas, x + w * .056, h * .445, w * .012, h * .01, light);
    }

    // A recessed arched gate and tiny clustered havelis inside the walls.
    _rect(canvas, w * .455, h * .475, w * .09, h * .07, shadow);
    final gate = ui.Path()
      ..moveTo(w * .475, h * .545)
      ..lineTo(w * .475, h * .51)
      ..quadraticBezierTo(w * .50, h * .475, w * .525, h * .51)
      ..lineTo(w * .525, h * .545)
      ..close();
    canvas.drawPath(gate, ui.Paint()..color = dark);
    for (var i = 0; i < 3; i++) {
      final x = w * (.31 + i * .16);
      _rect(canvas, x, h * .455, w * .055, h * .035, light);
      _rect(canvas, x + w * .015, h * .44, w * .025, h * .015, sandstone);
      _rect(canvas, x + w * .022, h * .467, w * .012, h * .023, dark);
    }
  }

  /// Distant silhouette family, chosen from the location's biome so an urban
  /// city does not sit in front of green hills and a desert does not sit in
  /// front of a forest ridge.
  _HorizonKind get _horizonKind => switch (location.biome) {
        WorldBiome.desert || WorldBiome.coldDesert => _HorizonKind.dune,
        WorldBiome.mountain => _HorizonKind.mountain,
        WorldBiome.urban => _HorizonKind.skyline,
        WorldBiome.coastal => _HorizonKind.coast,
        WorldBiome.river => _HorizonKind.riverPlain,
        WorldBiome.tropical => _HorizonKind.canopy,
        WorldBiome.temperate => _HorizonKind.woodedRidge,
      };

  /// Far horizon colour: biome-tinted, then shifted by weather and season.
  ui.Color get _horizonFarColor {
    final base = switch (location.biome) {
      WorldBiome.desert || WorldBiome.coldDesert => const ui.Color(0xFFC79A5E),
      WorldBiome.mountain => const ui.Color(0xFF6E8290),
      WorldBiome.urban => const ui.Color(0xFF5C6472),
      WorldBiome.coastal => const ui.Color(0xFF4E7E92),
      WorldBiome.river => const ui.Color(0xFF4F7A6C),
      WorldBiome.tropical => const ui.Color(0xFF2F6B52),
      WorldBiome.temperate => const ui.Color(0xFF3B6B57),
    };
    if (_winterWorld) return ui.Color.lerp(base, const ui.Color(0xFF9FBACD), .72)!;
    if (_storm) return ui.Color.lerp(base, const ui.Color(0xFF1B2E38), .68)!;
    if (_hot) return ui.Color.lerp(base, const ui.Color(0xFFC9853F), .42)!;
    if (_autumnWorld) return ui.Color.lerp(base, const ui.Color(0xFF8A5B3A), .45)!;
    if (_winterSeason) return ui.Color.lerp(base, const ui.Color(0xFF7A746A), .55)!;
    return base;
  }

  /// Near horizon colour, kept a shade lighter than [_horizonFarColor].
  ui.Color get _horizonNearColor {
    final base = switch (location.biome) {
      WorldBiome.desert || WorldBiome.coldDesert => const ui.Color(0xFFDCB073),
      WorldBiome.mountain => const ui.Color(0xFF87999F),
      WorldBiome.urban => const ui.Color(0xFF78808E),
      WorldBiome.coastal => const ui.Color(0xFF6E9CAA),
      WorldBiome.river => const ui.Color(0xFF639381),
      WorldBiome.tropical => const ui.Color(0xFF3F8663),
      WorldBiome.temperate => const ui.Color(0xFF4B8465),
    };
    if (_winterWorld) return ui.Color.lerp(base, const ui.Color(0xFFD6E6EE), .66)!;
    if (_storm) return ui.Color.lerp(base, const ui.Color(0xFF2C4A4C), .55)!;
    if (_hot) return ui.Color.lerp(base, const ui.Color(0xFFE3AC66), .38)!;
    if (_autumnWorld) return ui.Color.lerp(base, const ui.Color(0xFFA4713F), .40)!;
    if (_winterSeason) return ui.Color.lerp(base, const ui.Color(0xFF918A7C), .45)!;
    return base;
  }

  /// Sea tone for coastal and river horizons, reflected off the current sky.
  ui.Color get _horizonWaterColor => ui.Color.lerp(
        !isDay || _storm
            ? const ui.Color(0xFF22475F)
            : const ui.Color(0xFF2F6E88),
        _skyColor,
        .18,
      )!;

  ui.Path _horizonRidgePath(double w, double h) {
    final path = ui.Path();
    switch (_horizonKind) {
      case _HorizonKind.mountain:
        path
          ..moveTo(0, h * .58)
          ..lineTo(w * .10, h * .44)
          ..lineTo(w * .17, h * .52)
          ..lineTo(w * .30, h * .40)
          ..lineTo(w * .43, h * .53)
          ..lineTo(w * .57, h * .42)
          ..lineTo(w * .70, h * .52)
          ..lineTo(w * .84, h * .45)
          ..lineTo(w, h * .55);
      case _HorizonKind.dune:
        path
          ..moveTo(0, h * .56)
          ..quadraticBezierTo(w * .17, h * .47, w * .35, h * .545)
          ..quadraticBezierTo(w * .52, h * .60, w * .68, h * .495)
          ..quadraticBezierTo(w * .86, h * .43, w, h * .53);
      case _HorizonKind.skyline:
        // Blocky distant towers: vertical steps read as a city edge.
        path.moveTo(0, h * .60);
        var skylineX = 0.0;
        var tower = 0;
        while (skylineX < w) {
          final towerW = w * (.045 + (tower % 3) * .022);
          final towerTop = h * (.545 - (tower * 7 % 11) / 100);
          path
            ..lineTo(skylineX, towerTop)
            ..lineTo(skylineX + towerW, towerTop);
          skylineX += towerW;
          tower++;
        }
        path.lineTo(w, h * .60);
      case _HorizonKind.coast:
        path
          ..moveTo(0, h * .575)
          ..quadraticBezierTo(w * .22, h * .525, w * .45, h * .565)
          ..quadraticBezierTo(w * .70, h * .605, w, h * .545);
      case _HorizonKind.canopy:
        // Rounded canopy humps instead of a sawtooth ridge.
        path.moveTo(0, h * .575);
        for (var i = 0; i < 7; i++) {
          path.quadraticBezierTo(
            w * (i + .5) / 7,
            h * (.47 + (i % 3) * .022),
            w * (i + 1) / 7,
            h * (.565 + (i % 2) * .012),
          );
        }
      case _HorizonKind.riverPlain:
        path
          ..moveTo(0, h * .575)
          ..quadraticBezierTo(w * .30, h * .535, w * .55, h * .565)
          ..quadraticBezierTo(w * .78, h * .59, w, h * .55);
      case _HorizonKind.woodedRidge:
        path
          ..moveTo(0, h * .57)
          ..lineTo(w * .12, h * .49)
          ..lineTo(w * .22, h * .54)
          ..lineTo(w * .38, h * .465)
          ..lineTo(w * .53, h * .55)
          ..lineTo(w * .69, h * .48)
          ..lineTo(w * .82, h * .53)
          ..lineTo(w, h * .46);
    }
    return path
      ..lineTo(w, h * .62)
      ..lineTo(0, h * .62)
      ..close();
  }

  void _drawHorizon(ui.Canvas canvas, double w, double h) {
    final far = _horizonFarColor;
    final near = _horizonNearColor;
    canvas.drawPath(
        _horizonRidgePath(w, h), ui.Paint()..color = far);
    final lowland = ui.Path()
      ..moveTo(0, h * .59)
      ..lineTo(w * .18, h * .545)
      ..lineTo(w * .33, h * .58)
      ..lineTo(w * .52, h * .535)
      ..lineTo(w * .71, h * .585)
      ..lineTo(w * .88, h * .54)
      ..lineTo(w, h * .57)
      ..lineTo(w, h * .62)
      ..lineTo(0, h * .62)
      ..close();
    canvas.drawPath(lowland, ui.Paint()..color = near);
    if (_winterWorld) {
      // A snow line traces the ridge instead of floating rectangles.
      final snowLine = ui.Paint()
        ..color = const ui.Color(0xCCECF8FC)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, h * .012);
      canvas.drawPath(_horizonRidgePath(w, h), snowLine);
    }
  }

  /// Sea band drawn behind the ground so a coastal or river city reads as a
  /// waterfront rather than a field.
  void _drawHorizonWater(ui.Canvas canvas, double w, double h) {
    if (_horizonKind != _HorizonKind.coast &&
        _horizonKind != _HorizonKind.riverPlain) {
      return;
    }
    final water = _horizonWaterColor;
    final top = h * .585;
    _rect(canvas, 0, top, w, h * .60 - top, water);
    // Bright horizon edge where the sea meets the sky.
    _rect(canvas, 0, top, w, math.max(1.5, h * .004),
        ui.Color.lerp(water, const ui.Color(0xFFFFFFFF), .22)!);
    for (var i = 0; i < 6; i++) {
      final x = w * ((i * 37 % 91) / 100);
      _rect(canvas, x, h * (.592 + (i % 3) * .004), w * .06,
          math.max(1.0, h * .0035), const ui.Color(0x55DCEFF4));
    }
  }

  void _drawTerrainDetails(ui.Canvas canvas, double w, double h) {
    if (_hot) {
      final crack = ui.Paint()
        ..color = const ui.Color(0x886E452F)
        ..strokeWidth = math.max(1.0, w * .003)
        ..style = ui.PaintingStyle.stroke;
      for (var i = 0; i < 9; i++) {
        final x = w * (.04 + (i * 29 % 91) / 100);
        final y = h * (.68 + (i * 17 % 24) / 100);
        final path = ui.Path()
          ..moveTo(x, y)
          ..lineTo(x + w * .018, y + h * .018)
          ..lineTo(x + w * .009, y + h * .038)
          ..lineTo(x + w * .034, y + h * .054);
        canvas.drawPath(path, crack);
      }
    } else if (_winterWorld) {
      for (var i = 0; i < 14; i++) {
        final x = w * ((i * 31 % 96) / 100);
        final y = h * (.72 + (i * 13 % 23) / 100);
        _rect(canvas, x, y, w * (.025 + (i % 3) * .009), h * .008,
            const ui.Color(0xAAEFFAFF));
      }
    } else {
      final grass = _storm
          ? const ui.Color(0xFF375651)
          : _autumnWorld
              ? const ui.Color(0xFFB27A45)
              : _springWorld
                  ? const ui.Color(0xFF78AE62)
                  : _summerWorld
                      ? const ui.Color(0xFF5A904F)
                      : const ui.Color(0xFF6C9B5E);
      for (var i = 0; i < 24; i++) {
        final x = w * ((i * 23 % 99) / 100);
        final y = h * (.67 + (i * 11 % 28) / 100);
        _rect(canvas, x, y, w * .004, h * (.014 + (i % 3) * .005), grass);
      }
      if (_autumnWorld || _springWorld) {
        for (var i = 0; i < 11; i++) {
          final x = w * (.04 + (i * 17 % 92) / 100);
          final y = h * (.73 + (i * 11 % 20) / 100);
          if (_autumnWorld) {
            _rect(
                canvas,
                x,
                y,
                w * .014,
                h * .009,
                i.isEven
                    ? const ui.Color(0xFFD69542)
                    : const ui.Color(0xFFB65F38));
            _rect(canvas, x + w * .006, y - h * .004, w * .006, h * .008,
                const ui.Color(0xFFDFAB58));
          } else {
            _rect(canvas, x + w * .005, y, w * .004, h * .025,
                const ui.Color(0xFF3C8450));
            _rect(
                canvas,
                x,
                y - h * .006,
                w * .014,
                h * .012,
                i.isEven
                    ? const ui.Color(0xFFE9B7D2)
                    : const ui.Color(0xFFFFD58A));
          }
        }
      }
      // Small stones catch a different shade from the meadow floor.
      for (var i = 0; i < 8; i++) {
        final x = w * (.06 + (i * 19 % 90) / 100);
        final y = h * (.76 + (i * 7 % 18) / 100);
        _rect(canvas, x, y, w * .018, h * .009,
            _storm ? const ui.Color(0xFF526A67) : const ui.Color(0xFF52745E));
      }
    }
  }

  /// Detailed, layered rainy-night scene drawn entirely with Flame's canvas.
  void _drawRainyForest(ui.Canvas canvas, double w, double h) {
    final unit = math.max(2.0, math.min(w, h) * .018).toDouble();
    final trunk = isDay && !_storm
        ? const ui.Color(0xFF69432B)
        : const ui.Color(0xFF3A241B);
    final bark = isDay && !_storm
        ? const ui.Color(0xFF8B5A35)
        : const ui.Color(0xFF583421);
    final deepLeaf = _storm
        ? const ui.Color(0xFF092D2B)
        : isDay
            ? const ui.Color(0xFF15523C)
            : const ui.Color(0xFF104138);
    final leaf = _storm
        ? const ui.Color(0xFF10443D)
        : isDay
            ? const ui.Color(0xFF24704A)
            : const ui.Color(0xFF175344);

    // Dark distant tree line and a few scattered canopy gaps.
    _rect(canvas, 0, h * .60, w, h * .07, const ui.Color(0xFF102C2A));
    for (var i = 0; i < 10; i++) {
      final x = w * (i / 10);
      final treetop = h * (.49 + (i % 3) * .025);
      _rect(canvas, x, treetop, w * .055, h * .13, deepLeaf);
      _rect(canvas, x + w * .012, treetop - h * .035, w * .032, h * .055, leaf);
    }

    // Large foreground tree: blocky trunk, roots, bark cuts, and canopy.
    _rect(canvas, 0, h * .20, w * .18, h * .66, trunk);
    _rect(canvas, w * .035, h * .23, w * .018, h * .42, bark);
    _rect(canvas, w * .105, h * .19, w * .012, h * .51, bark);
    _rect(canvas, w * .145, h * .31, w * .012, h * .32,
        const ui.Color(0xFF2C1D18));
    // A few dark bark knots break the trunk's long flat bands.
    for (var i = 0; i < 4; i++) {
      final bx = w * (.045 + (i % 2) * .075);
      final by = h * (.34 + i * .12);
      _rect(canvas, bx, by, w * .018, h * .012, const ui.Color(0xFF2A1B16));
      _rect(canvas, bx + w * .006, by + h * .004, w * .006, h * .004,
          const ui.Color(0xFF7A4A2E));
    }
    _rect(canvas, 0, h * .83, w * .20, h * .045, trunk);
    _rect(canvas, w * .12, h * .79, w * .10, h * .035, trunk);
    _rect(canvas, w * .01, h * .17, w * .45, h * .085, deepLeaf);
    _rect(canvas, w * .055, h * .12, w * .34, h * .065, leaf);
    _rect(canvas, w * .16, h * .09, w * .28, h * .055, deepLeaf);
    _rect(canvas, w * .32, h * .14, w * .18, h * .045, leaf);
    for (var i = 0; i < 13; i++) {
      final x = w * (.045 + (i * 17 % 46) / 100);
      final y = h * (.105 + (i * 11 % 11) / 100);
      _rect(canvas, x, y, unit * (1.4 + (i % 3)), unit * .65,
          i.isEven ? const ui.Color(0xFF247052) : const ui.Color(0xFF1B604A));
    }

    // A warm square lantern hangs from the branch and lights nearby rain.
    final lanternCenter = ui.Offset(w * .407, h * .325);
    final glowRadius = w * .19;
    final forestLanternLit = !isDay || _storm;
    if (forestLanternLit) {
      canvas.drawCircle(
        lanternCenter,
        glowRadius,
        ui.Paint()
          ..shader = ui.Gradient.radial(
            lanternCenter,
            glowRadius,
            const [ui.Color(0x55FFCB67), ui.Color(0x00FFCB67)],
          ),
      );
      _rect(canvas, w * .30, h * .51, w * .23, h * .018,
          const ui.Color(0x229F9A63));
    }
    _rect(canvas, w * .405, h * .18, unit * .8, h * .09,
        const ui.Color(0xFF32251E));
    _rect(canvas, w * .375, h * .265, w * .065, h * .12,
        const ui.Color(0xFF30251F));
    _rect(
        canvas,
        w * .39,
        h * .28,
        w * .035,
        h * .085,
        forestLanternLit
            ? const ui.Color(0xFFFFB83F)
            : const ui.Color(0xFF79543A));
    _rect(
        canvas,
        w * .398,
        h * .294,
        w * .018,
        h * .052,
        forestLanternLit
            ? const ui.Color(0xFFFFE48A)
            : const ui.Color(0xFF9C7545));
    _rect(canvas, w * .388, h * .278, w * .04, h * .008,
        const ui.Color(0xFFFFD77B));
    _rect(canvas, w * .367, h * .37, w * .082, h * .015,
        const ui.Color(0x664D596D));
    _rect(canvas, w * .35, h * .39, w * .12, h * .012,
        const ui.Color(0x553C4B65));
    // Tiny fireflies around the lantern.
    for (var i = 0; forestLanternLit && i < 5; i++) {
      final fx = w * (.28 + i * .11);
      final fy = h * (.34 + (i % 3) * .12);
      _rect(canvas, fx, fy, unit * .48, unit * .48, const ui.Color(0xFFFFD96A));
    }

    // Rustic fence behind the character, with square posts and rails.
    final fence = const ui.Color(0xFF573A27);
    for (var i = 0; i < 5; i++) {
      final x = w * (.62 + i * .085);
      _rect(canvas, x, h * .66, w * .022, h * .19, fence);
      _rect(canvas, x + w * .004, h * .66, w * .014, h * .012,
          const ui.Color(0xFF795338));
    }
    _rect(canvas, w * .60, h * .70, w * .40, h * .035, fence);
    _rect(canvas, w * .60, h * .79, w * .40, h * .035, fence);
    _rect(canvas, w * .60, h * .70, w * .40, h * .009,
        const ui.Color(0xFF80583A));

    // Pond in the near foreground, with stepped bank and animated rain rings.
    _rect(canvas, w * .40, h * .845, w * .60, h * .155,
        isDay ? const ui.Color(0xFF245A80) : const ui.Color(0xFF173A68));
    _rect(canvas, w * .40, h * .845, w * .60, h * .015,
        const ui.Color(0xFF437B9B));
    _rect(canvas, w * .40, h * .86, w * .60, h * .012,
        const ui.Color(0xFF285487));
    for (var i = 0; i < 5; i++) {
      final x = w * (.45 + i * .105);
      final y = h * (.90 + (i % 3) * .027);
      final ring = ui.Rect.fromCenter(
        center: ui.Offset(x, y),
        width: w * (.055 + .018 * math.sin(_elapsed * 2 + i)),
        height: h * .012,
      );
      canvas.drawOval(
          ring,
          ui.Paint()
            ..color = const ui.Color(0x884F9BD0)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }
    for (var i = 0; i < 8; i++) {
      _rect(
          canvas,
          w * (.44 + (i * 13 % 53) / 100),
          h * (.88 + (i * 7 % 10) / 100),
          w * .055,
          unit * .45,
          i.isEven ? const ui.Color(0xFF35699A) : const ui.Color(0xFF284F83));
    }

    // Flowers and a tiny red mushroom add foreground color and scale.
    for (var i = 0; i < 3; i++) {
      final x = w * (.20 + i * .035);
      final y = h * .88;
      _rect(
          canvas, x + unit, y, unit * .55, h * .07, const ui.Color(0xFF28784E));
      _rect(canvas, x, y - unit, unit * 1.2, unit * 1.1,
          i == 1 ? const ui.Color(0xFFB77CFF) : const ui.Color(0xFFD17DFF));
      _rect(canvas, x + unit * .3, y - unit * .7, unit * .35, unit * .4,
          const ui.Color(0xFFEBCBFF));
    }
    final mx = w * .75;
    final my = h * .82;
    _rect(canvas, mx + unit * .7, my, unit * 1.1, unit * 2.3,
        const ui.Color(0xFFFFE7C5));
    _rect(canvas, mx, my - unit, unit * 2.6, unit * 1.2,
        const ui.Color(0xFFD84445));
    _rect(canvas, mx + unit * .55, my - unit * .55, unit * .45, unit * .35,
        const ui.Color(0xFFFFF0DB));
  }

  void _drawWeatherParticles(ui.Canvas canvas, double w, double h) {
    if (_sandstorm) {
      final sand = ui.Paint()
        ..color = const ui.Color(0xD8F0B36F)
        ..strokeWidth = 1.4;
      final flowX = -math.sin(windDirectionDeg * math.pi / 180);
      final count = reduceMotion ? 54 : 90;
      for (var i = 0; i < count; i++) {
        final x = (i * 31.0 +
                _elapsed *
                    _environmentMotionScale *
                    (flowX * 95 + 90 + i % 5 * 18)) %
            w;
        final y =
            (i * 17.0 + _elapsed * _environmentMotionScale * (22 + i % 7 * 5)) %
                h;
        canvas.drawLine(
            ui.Offset(x, y), ui.Offset(x - w * .025, y + h * .004), sand);
      }
      return;
    }
    if (_heatStress || _sunBeamActive) {
      for (var i = 0; i < 9; i++) {
        final x = w * (.30 + i * .075);
        final y = h *
            (.63 + .025 * math.sin(_elapsed * _environmentMotionScale * 2 + i));
        canvas.drawLine(
            ui.Offset(x, y),
            ui.Offset(x + 3, y - h * .08),
            ui.Paint()
              ..color = const ui.Color(0x55FFF0B0)
              ..strokeWidth = 2);
      }
    }
    if (_windy) {
      final p = ui.Paint()
        ..color =
            _sandstorm ? const ui.Color(0x99EBC08A) : const ui.Color(0x99E2F5FF)
        ..strokeWidth = 1.5;
      final direction = math.cos(windDirectionDeg * math.pi / 180);
      final count = reduceMotion ? 7 : 13;
      for (var i = 0; i < count; i++) {
        final x = (i * w / count +
                _elapsed * _environmentMotionScale * _wind * 1.5 * direction) %
            w;
        final y = h * (.28 + (i % 6) * .085);
        canvas.drawLine(
            ui.Offset(x, y),
            ui.Offset(x + w * .075 * (direction.sign == 0 ? 1 : direction.sign),
                y - 2),
            p);
      }
    }
    if (_rain || _snow) {
      final rainAlpha = (115 + 105 * _rainIntensity).round().clamp(0, 220);
      final p = ui.Paint()
        ..color = _snow
            ? const ui.Color(0xFFEAF9FF)
            : ui.Color.fromARGB(rainAlpha, 126, 223, 255)
        ..strokeWidth = _snow ? 1.1 : 1 + _rainIntensity * .7;
      final particleCount = _snow
          ? ([75, 86].contains(weatherCode) ? 56 : 30)
          : _lightRain
              ? (14 + (_rainIntensity * 30).round()).clamp(14, 40)
              : (24 + (_rainIntensity * 48).round()).clamp(24, 72);
      final reducedCount =
          reduceMotion ? (particleCount * .62).round() : particleCount;
      final fallSpeed =
          (_snow ? 34.0 : 85 + _rainIntensity * 115) * _environmentMotionScale;
      final windSlant = -math.sin(windDirectionDeg * math.pi / 180) *
          (_wind / 160).clamp(0.0, .9) *
          w *
          .035;
      for (var i = 0; i < reducedCount; i++) {
        final x = (i * 41.0 +
                _elapsed * _environmentMotionScale * (windSlant * 12 + 12)) %
            w;
        final y = (i * 29.0 + _elapsed * fallSpeed) % h;
        if (_snow) {
          _rect(canvas, x, y, 2.5, 2.5, const ui.Color(0xFFEAF9FF));
        } else {
          canvas.drawLine(ui.Offset(x, y),
              ui.Offset(x + windSlant, y + 6 + _rainIntensity * 5), p);
        }
      }
    }
    if (_fog) {
      for (var i = 0; i < 5; i++) {
        final y = h * (.25 + i * .13);
        final x =
            ((_elapsed * _environmentMotionScale * 12 + i * 71) % (w + 100)) -
                100;
        _rect(canvas, x, y, w * .62, h * .035, const ui.Color(0x44E5F0F4));
      }
    }
  }

  void _drawWetGround(ui.Canvas canvas, double w, double h) {
    final sheen = 18 + (_rainIntensity * 30).round();
    _rect(
        canvas, 0, h * .91, w, h * .09, ui.Color.fromARGB(sheen, 84, 152, 176));
    for (var i = 0; i < 9; i++) {
      final x = w * ((i * 23 % 97) / 100);
      final y = h * (.77 + (i * 13 % 16) / 100);
      final radius = w * (.008 + (i % 3) * .003);
      final age = (_elapsed * _environmentMotionScale * (1.2 + _rainIntensity) +
              i * .37) %
          1;
      canvas.drawOval(
        ui.Rect.fromCenter(
            center: ui.Offset(x, y),
            width: radius * (1 + age * 2),
            height: radius * (.35 + age * .3)),
        ui.Paint()
          ..color = const ui.Color(0x885DB8CE).withValues(alpha: (1 - age) * .42)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }
  }

  void _drawGoblin(ui.Canvas canvas, double w, double h,
      {required double x, required double floor}) {
    final sprites = _sprites;
    if (sprites != null && !sprites.isEmpty) {
      _drawGoblinSprite(canvas, w, h, x: x, floor: floor, sprites: sprites);
      return;
    }
    _drawGoblinProcedural(canvas, w, h, x: x, floor: floor);
  }

  /// Draws the loaded sprite frames with the same weather effects the
  /// procedural character used, so the reactions survive the art change.
  void _drawGoblinSprite(ui.Canvas canvas, double w, double h,
      {required double x,
      required double floor,
      required GoblinSprites sprites}) {
    final hit = _hitRecovery > 0 && _directHit;
    final chatting = _dialogueAge > 0;
    final behavior = _behavior.state;
    final poseState = behavior == GoblinBehaviorState.recover
        ? _behavior.previousState
        : behavior;
    final rawActionBlend = behavior == GoblinBehaviorState.recover
        ? 1 - _behavior.actionProgress
        : behavior == GoblinBehaviorState.idle
            ? 0.0
            : (_behavior.stateAge / .28).clamp(0.0, 1.0).toDouble();
    final actionBlend =
        rawActionBlend * rawActionBlend * (3 - 2 * rawActionBlend);
    final resting = poseState == GoblinBehaviorState.rest;
    final sleeping = poseState == GoblinBehaviorState.sleep;
    final sitBlend =
        (resting || sleeping) ? actionBlend : 0.0;
    final nearMiss = _strikeAge < .42 && !_directHit && _thunderstorm;
    final unit = math.max(2.0, math.min(w, h) * .014).toDouble();
    final motionScale = reduceFlashing || reduceMotion ? .55 : 1.0;
    final shiver = _cold ? math.sin(_elapsed * 7.5) * .65 * motionScale : 0.0;
    final gustLean =
        _windy ? (math.min(_wind / 160, .22) * 18).toDouble() : 0.0;
    x += shiver + gustLean;

    // The sprite stands 31 scene units tall in the procedural scale, which
    // keeps every effect offset below aligned with the drawn character.
    const spriteHeightUnits = 31.0;
    final spriteWidth = unit *
        (spriteHeightUnits * sprites.frameWidth / sprites.frameHeight) *
        (1 - .18 * sitBlend);
    final spriteHeight = unit * spriteHeightUnits * (1 - .18 * sitBlend);
    final spriteLeft = x - spriteWidth / 2;
    // Seat the frame's feet row on the scene floor.
    final feetOffset =
        unit * spriteHeightUnits * (sprites.frameHeight - sprites.feetY) /
            sprites.frameHeight;
    final spriteTop = floor + feetOffset - spriteHeight;

    // Ground shadow, matching the procedural contact shadow.
    canvas.drawOval(
      ui.Rect.fromCenter(
          center: ui.Offset(x, floor + unit * .8),
          width: hit ? unit * 8 : unit * 11,
          height: unit * 1.5),
      ui.Paint()..color = const ui.Color(0x88030A0B),
    );

    final sprite = _walking
        ? sprites.walkFrameAt(_behavior.stateAge * _strideSpeed / 7)
        : sprites.idleFrameAt(_elapsed);
    final dest = ui.Rect.fromLTWH(
        spriteLeft, spriteTop, spriteWidth, spriteHeight);

    // Draws the current frame, mirrored when he walks left. Used for the body
    // and for every mask layer below so tints and light always line up.
    void renderSprite(ui.Paint paint) {
      canvas.save();
      if (_walkingLeft) {
        canvas.translate(x, floor);
        canvas.scale(-1, 1);
        canvas.translate(-x, -floor);
      }
      sprite.render(
        canvas,
        position: Vector2(dest.left, dest.top),
        size: Vector2(dest.width, dest.height),
        overridePaint: paint,
      );
      canvas.restore();
    }

    renderSprite(ui.Paint()..filterQuality = ui.FilterQuality.none);

    // Weather tinting replaces the procedural body recolouring. It is applied
    // inside a layer with srcATop so the wash lands on the character's pixels
    // only, instead of reading as a coloured box around him.
    final tint = hit
        ? const ui.Color(0xCC20262A)
        : _cold
            ? const ui.Color(0x4D86C5E7)
            : (_sunBeamActive || _heatStress)
                ? ui.Color.lerp(const ui.Color(0x00C94E43),
                    const ui.Color(0x80C94E43), _sunHeatProgress)
                : null;
    if (tint != null && tint.a > 0) {
      final bounds = dest.inflate(unit * 2);
      canvas.saveLayer(bounds, ui.Paint());
      renderSprite(ui.Paint()..filterQuality = ui.FilterQuality.none);
      // The sprite drawn a second time with plain srcIn supplies the alpha mask,
      // so the wash lands on the character's pixels only.
      renderSprite(ui.Paint()
        ..color = tint
        ..blendMode = ui.BlendMode.srcIn);
      canvas.restore();
    }

    // Dynamic light on the character: a warm lantern glow along his left side
    // (the lantern hangs there) and a brief cool flash while lightning
    // strikes. Each light is a gradient masked to the sprite's own pixels, so
    // it never spills past his outline or hides the heat/cold tint beneath.
    void lightWash(ui.Shader shader) {
      final bounds = dest.inflate(unit * 2);
      canvas.saveLayer(bounds, ui.Paint());
      renderSprite(ui.Paint()..filterQuality = ui.FilterQuality.none);
      canvas.drawRect(
        bounds,
        ui.Paint()
          ..shader = shader
          ..blendMode = ui.BlendMode.srcIn,
      );
      canvas.restore();
    }

    final lanternGlow = !_desertHeat &&
        !_sandstorm &&
        (!isDay || _storm || _fog || nearMiss);
    if (lanternGlow && !hit) {
      final flicker = .85 + .15 * math.sin(_elapsed * 4);
      final strength = (nearMiss ? 150 : 105) * flicker;
      final lit = ui.Color.fromARGB(
          strength.round().clamp(0, 255).toInt(), 255, 176, 74);
      final bounds = dest.inflate(unit * 2);
      lightWash(ui.Gradient.linear(
        ui.Offset(bounds.left, 0),
        ui.Offset(bounds.right, 0),
        [lit, lit.withAlpha(0)],
        const [0.0, .62],
      ));
    }
    if (_thunderstorm && _strikeAge < .34) {
      final fade = (1 - _strikeAge / .34).clamp(0.0, 1.0).toDouble() *
          (reduceFlashing ? .35 : 1.0);
      final bounds = dest.inflate(unit * 2);
      lightWash(ui.Gradient.linear(
        ui.Offset(0, bounds.top),
        ui.Offset(0, bounds.bottom),
        [
          ui.Color.fromARGB((210 * fade).round().clamp(0, 255).toInt(), 232,
              243, 255),
          ui.Color.fromARGB((90 * fade).round().clamp(0, 255).toInt(), 150,
              190, 255),
        ],
      ));
    }

    _drawGoblinEffects(canvas, w, h,
        x: x,
        floor: floor,
        unit: unit,
        hit: hit,
        chatting: chatting,
        sleeping: sleeping || resting,
        yawning: poseState == GoblinBehaviorState.yawn,
        scratching: poseState == GoblinBehaviorState.lookAround &&
            _behavior.actionTarget == 'scratch',
        nearMiss: nearMiss,
        wipingBrow:
            (_heatStress || _sunBeamActive) && !_walking && _elapsed % 3 < .7,
        paddling: _flood && _elapsed >= 4.5,
        motionScale: motionScale);
  }

  /// Shared weather and prop overlays drawn on top of the character.
  void _drawGoblinEffects(ui.Canvas canvas, double w, double h,
      {required double x,
      required double floor,
      required double unit,
      required bool hit,
      required bool chatting,
      required bool sleeping,
      required bool yawning,
      required bool scratching,
      required bool nearMiss,
      required bool wipingBrow,
      required bool paddling,
      required double motionScale}) {
    // Matches the sprite's green skin so the overlay hands read as his own.
    const skin = ui.Color(0xFF9BC96B);
    if (chatting) {
      final wave = .5 + .5 * math.sin(_elapsed * 12);
      _rect(canvas, x + unit * 4.5, floor - unit * 15, unit * 2, unit * 4, skin);
      _rect(canvas, x + unit * 5, floor - unit * (18 + wave), unit * 2.5,
          unit * 2, skin);
    }
    if (wipingBrow) {
      _rect(canvas, x + unit * 2, floor - unit * 19, unit * 5, unit * 2, skin);
      _rect(canvas, x + unit * 5, floor - unit * 18, unit * 2, unit * 2,
          const ui.Color(0xFF73E4FF));
    }
    if (scratching) {
      _rect(canvas, x + unit * 2.2, floor - unit * 20, unit * 3.2, unit * 2,
          skin);
    }
    if (_behavior.state == GoblinBehaviorState.weatherReact &&
        _behavior.actionTarget == 'snow') {
      _rect(canvas, x + unit * 6, floor - unit * 18, unit * 4.5, unit, skin);
      final flakeX = x + unit * (9 + math.sin(_elapsed * 1.3) * 1.5);
      final flakeY = floor - unit * (20 + math.sin(_elapsed * 1.6) * .8);
      _rect(canvas, flakeX, flakeY, unit, unit, const ui.Color(0xFFE8FAFF));
    }
    if (_rain && _walking) {
      final splashY = floor - unit * .5;
      _rect(canvas, x - unit * 7, splashY, unit * 2, unit,
          const ui.Color(0xAA9BC9D7));
      _rect(canvas, x + unit * 5, splashY - unit, unit * 2, unit,
          const ui.Color(0xAA9BC9D7));
    }
    if (paddling) {
      final paddleAngle = math.sin(_elapsed * 3.2) * .48;
      canvas.save();
      canvas.translate(x + unit * 6, floor - unit * 9);
      canvas.rotate(paddleAngle);
      canvas.drawLine(
          const ui.Offset(0, 0),
          ui.Offset(unit * 11, unit * 8),
          ui.Paint()
            ..color = const ui.Color(0xFF79543A)
            ..strokeWidth = unit * 1.3);
      _rect(canvas, unit * 8, unit * 6, unit * 4, unit * 2,
          const ui.Color(0xFFB07A42));
      canvas.restore();
    }

    // Lantern on the goblin's left side; its glow warms the nearby ground.
    final lantern = ui.Offset(x - unit * 7, floor - unit * 9);
    final lanternLit =
        !_desertHeat && !_sandstorm && (!isDay || _storm || _fog || nearMiss);
    if (lanternLit) {
      final glowR =
          unit * (nearMiss ? 10 : 7) * (0.92 + .08 * math.sin(_elapsed * 4));
      canvas.drawCircle(
          lantern,
          glowR,
          ui.Paint()
            ..shader = ui.Gradient.radial(
              lantern,
              glowR,
              const [ui.Color(0x66FFD16B), ui.Color(0x00FF9D36)],
            ));
    }
    _rect(
        canvas,
        lantern.dx - unit,
        lantern.dy - unit * 1.5,
        unit * 2,
        unit * 3,
        lanternLit ? const ui.Color(0xFFFFC857) : const ui.Color(0xFF79543A));
    _rect(canvas, lantern.dx - unit * .5, lantern.dy - unit, unit, unit * 2,
        lanternLit ? const ui.Color(0xFFFFF1A8) : const ui.Color(0xFFB08A56));
    if (lanternLit &&
        !_rain &&
        !_windy &&
        !_fog &&
        !_winterWorld &&
        !_cyclone &&
        !_flood) {
      paintLanternMoths(
          canvas, lantern, unit, _elapsed * _environmentMotionScale, _detailSeed);
    }

    if (_heatStress || _sunBeamActive) {
      final heatProgress = _sunHeatProgress;
      final sweatCount = heatProgress > .35 ? 4 : 2;
      for (var i = 0; i < sweatCount; i++) {
        final sx = x + unit * (4 + i * 1.4);
        final sy = floor - unit * (18 - ((_elapsed * 5 + i * 3) % 8));
        _rect(
            canvas, sx, sy, unit * .8, unit * 1.4, const ui.Color(0xFF73E4FF));
      }
    }
    if (_cold) {
      // Scarf wrapped at the neck, mittens over the hands, pink cheeks and
      // visible breath. Offsets are aligned to the sprite's own proportions
      // (hood down to about 18 units, hands near 13 units).
      _rect(canvas, x - unit * 3.6, floor - unit * 15.4, unit * 7.2, unit * 1.7,
          const ui.Color(0xFF8A5362));
      _rect(canvas, x + unit * 2.4, floor - unit * 15.2, unit * 1.6, unit * 2.8,
          const ui.Color(0xFF6B4852));
      _rect(canvas, x - unit * 4, floor - unit * 14.6, unit * 1.7, unit * 2.6,
          const ui.Color(0xFF6B4852));
      final breathPhase = _elapsed % 2.8;
      if (breathPhase < 1.5) {
        final opacity = ((1 - breathPhase / 1.5) * 90).round().clamp(0, 90);
        final breathColor = ui.Color.fromARGB(opacity, 227, 245, 250);
        final bx = x + unit * (7 + breathPhase * 2.5);
        final by = floor - unit * (17 + breathPhase * 2.2);
        canvas.drawCircle(
            ui.Offset(bx, by), unit * 1.8, ui.Paint()..color = breathColor);
        canvas.drawCircle(ui.Offset(bx + unit * 2.1, by - unit * .8),
            unit * 1.2, ui.Paint()..color = breathColor);
      }
    }
    if (_windy) {
      // Hood tail points away from the wind direction.
      _rect(
          canvas,
          x - unit * (7 + math.min(_wind / 15, 7).toDouble()),
          floor - unit * 19,
          unit * math.min(_wind / 15, 7).toDouble(),
          unit * 2,
          _sandstorm ? const ui.Color(0xFFB94F2D) : const ui.Color(0xFFE6A34A));
    }
    if (_sandstorm) {
      // Goggles and wrapped scarf protect him from blowing sand.
      _rect(canvas, x - unit * 3.2, floor - unit * 17.5, unit * 6.8, unit * 2.4,
          const ui.Color(0xFF342D2A));
      _rect(canvas, x - unit * 2.6, floor - unit * 17.1, unit * 2.1,
          unit * 1.35, const ui.Color(0xFF8AD4D4));
      _rect(canvas, x + unit * .4, floor - unit * 17.1, unit * 2.1, unit * 1.35,
          const ui.Color(0xFF8AD4D4));
      _rect(canvas, x - unit * 4.4, floor - unit * 11, unit * 8.8, unit * 2.2,
          const ui.Color(0xFFC65B32));
    }
    if ((_desertHeat && _elapsed >= 8) ||
        (_sunBeamActive && _sunExposure >= 8 && temperatureC >= 36)) {
      final dizzy = .5 + .5 * math.sin(_elapsed * 5);
      for (var i = 0; i < 3; i++) {
        final angle = _elapsed * 2 + i * math.pi * 2 / 3;
        _rect(
            canvas,
            x + math.cos(angle) * unit * 8,
            floor - unit * 29 + math.sin(angle) * unit * 2,
            unit * dizzy,
            unit * dizzy,
            const ui.Color(0xFFFFF1A8));
      }
    }
    if (sleeping && !hit) {
      // No dedicated sleeping frame exists, so a slow bob plus closed-eye marks
      // reads as dozing without pretending to be a real animation.
      final zzz = (_elapsed % 2.4) / 2.4;
      final opacity = ((1 - zzz) * 200).round().clamp(0, 200);
      for (var i = 0; i < 2; i++) {
        final size = unit * (1.1 + i * .5);
        _rect(
            canvas,
            x + unit * (5 + i * 2.4),
            floor - unit * (24 + i * 3 + zzz * 3),
            size,
            size * .35,
            ui.Color.fromARGB(opacity, 232, 244, 255));
      }
    }
    if (yawning) {
      final open = (unit * 1.6 * motionScale).clamp(unit * .4, unit * 2.2);
      canvas.drawOval(
          ui.Rect.fromCenter(
              center: ui.Offset(x, floor - unit * 13.5),
              width: open,
              height: open * 1.1),
          ui.Paint()..color = const ui.Color(0xFF263238));
    }
    if (hit) {
      // Smoke puffs rise briefly after impact.
      for (var i = 0; i < 4; i++) {
        final sy = floor - unit * (29 + ((_elapsed * 8 + i * 5) % 12));
        canvas.drawCircle(
            ui.Offset(x + unit * (i - 2) * 2, sy),
            unit * (1.3 + i * .15),
            ui.Paint()..color = const ui.Color(0x557C858B));
      }
    }
  }

  /// Unused while sprite assets are present; kept as the fallback when the
  /// frames cannot be loaded.
  void _drawGoblinProcedural(ui.Canvas canvas, double w, double h,
      {required double x, required double floor}) {
    final hit = _hitRecovery > 0 && _directHit;
    final chatting = _dialogueAge > 0;
    final behavior = _behavior.state;
    final poseState = behavior == GoblinBehaviorState.recover
        ? _behavior.previousState
        : behavior;
    final poseTarget = behavior == GoblinBehaviorState.recover
        ? _behavior.previousTarget
        : _behavior.actionTarget;
    final rawActionBlend = behavior == GoblinBehaviorState.recover
        ? 1 - _behavior.actionProgress
        : behavior == GoblinBehaviorState.idle
            ? 0.0
            : (_behavior.stateAge / .28).clamp(0.0, 1.0).toDouble();
    final actionBlend =
        rawActionBlend * rawActionBlend * (3 - 2 * rawActionBlend);
    final sleeping =
        poseState == GoblinBehaviorState.sleep && actionBlend > .72;
    final resting = poseState == GoblinBehaviorState.rest;
    final stretching = resting && poseTarget == 'stretch';
    final scratching =
        poseState == GoblinBehaviorState.lookAround && poseTarget == 'scratch';
    final yawning = poseState == GoblinBehaviorState.yawn;
    final waving = poseState == GoblinBehaviorState.interact ||
        poseState == GoblinBehaviorState.play;
    final sitBlend =
        (resting || poseState == GoblinBehaviorState.sleep) ? actionBlend : 0.0;
    final nearMiss = _strikeAge < .42 && !_directHit && _thunderstorm;
    final unit = math.max(2.0, math.min(w, h) * .014).toDouble();
    final motionScale = reduceFlashing || reduceMotion ? .55 : 1.0;
    final stride = _walking && !hit
        ? math.sin(_behavior.stateAge * _strideSpeed) * motionScale
        : 0.0;
    final shiver = _cold ? math.sin(_elapsed * 7.5) * .65 * motionScale : 0.0;
    final gustLean =
        _windy ? (math.min(_wind / 160, .22) * 18).toDouble() : 0.0;
    x += shiver + gustLean;
    final breathing = math.sin(_elapsed * 2.1) * unit * .22;
    // The body stays mostly level; alternating feet and arm swings carry the walk.
    final leftLegSwing = stride * unit * 1.2;
    final rightLegSwing = -stride * unit * 1.2;
    final leftFootLift = math.max(0.0, stride) * unit * 1.2;
    final rightFootLift = math.max(0.0, -stride) * unit * 1.2;
    final paddling = _flood && _elapsed >= 4.5;
    final wipingBrow =
        (_heatStress || _sunBeamActive) && !_walking && _elapsed % 3 < .7;
    final heatProgress = _sunBeamActive
        ? _sunHeatProgress
        : _heatStress
            ? ((temperatureC - strongHeatThresholdC) /
                    (extremeHeatThresholdC - strongHeatThresholdC) *
                    .42)
                .clamp(0.0, .42)
                .toDouble()
            : 0.0;
    final bodyColor = hit
        ? const ui.Color(0xFF34363B)
        : (_sunBeamActive || _heatStress)
            ? ui.Color.lerp(const ui.Color(0xFF315C48),
                const ui.Color(0xFFC94E43), heatProgress)!
            : const ui.Color(0xFF315C48);
    final hoodColor = hit
        ? const ui.Color(0xFF292C32)
        : (_sunBeamActive || _heatStress)
            ? ui.Color.lerp(const ui.Color(0xFF247D61),
                const ui.Color(0xFFB9413B), heatProgress)!
            : const ui.Color(0xFF247D61);
    final skin = hit
        ? const ui.Color(0xFF9AA18B)
        : (_heatStress || _sunBeamActive)
            ? ui.Color.lerp(const ui.Color(0xFF83C879),
                const ui.Color(0xFFE77C68), heatProgress)!
            : _cold
                ? const ui.Color(0xFF86C5E7)
                : const ui.Color(0xFF83C879);

    // Ground shadow moves and tightens on a direct lightning hit.
    canvas.drawOval(
      ui.Rect.fromCenter(
          center: ui.Offset(x, floor + unit * .8),
          width: hit ? unit * 8 : unit * 11,
          height: unit * 1.5),
      ui.Paint()..color = const ui.Color(0x88030A0B),
    );

    // Blend standing and seated leg placements to avoid a pose snap.
    _rect(
        canvas,
        x + unit * ui.lerpDouble(-3.2 + leftLegSwing / unit, -3.5, sitBlend)!,
        floor - unit * ui.lerpDouble(7, 5.5, sitBlend)!,
        unit * ui.lerpDouble(2.4, 3, sitBlend)!,
        unit * 4.5,
        const ui.Color(0xFF28483D));
    _rect(
        canvas,
        x + unit * ui.lerpDouble(.8 + rightLegSwing / unit, .5, sitBlend)!,
        floor - unit * ui.lerpDouble(7, 5.5, sitBlend)!,
        unit * ui.lerpDouble(2.4, 3, sitBlend)!,
        unit * 4.5,
        const ui.Color(0xFF28483D));
    _rect(
        canvas,
        x + unit * ui.lerpDouble(-4 + leftLegSwing / unit, -5.5, sitBlend)!,
        floor - unit * ui.lerpDouble(3 + leftFootLift / unit, 2, sitBlend)!,
        unit * ui.lerpDouble(3, 4.5, sitBlend)!,
        unit * ui.lerpDouble(3, 2, sitBlend)!,
        const ui.Color(0xFF513C34));
    _rect(
        canvas,
        x + unit * ui.lerpDouble(1 + rightLegSwing / unit, 1, sitBlend)!,
        floor - unit * ui.lerpDouble(3 + rightFootLift / unit, 2, sitBlend)!,
        unit * ui.lerpDouble(3, 4.5, sitBlend)!,
        unit * ui.lerpDouble(3, 2, sitBlend)!,
        const ui.Color(0xFF513C34));
    _rect(canvas, x - unit * 4, floor - unit * 12 - breathing, unit * 8,
        unit * 9, bodyColor);
    final armSwing = stride * unit * 1.4;
    final leftArmY = floor - unit * (11 + (stretching ? 8 * actionBlend : 0));
    final rightRaise = scratching || waving || yawning ? actionBlend : 0.0;
    final rightArmY =
        floor - unit * (11 + (stretching ? 8 * actionBlend : 7 * rightRaise));
    _rect(canvas, x - unit * 6 - armSwing, leftArmY, unit * 2,
        unit * (6 + (stretching ? 2 * actionBlend : 0)), skin);
    _rect(canvas, x + unit * 4 + armSwing, rightArmY, unit * 2,
        unit * (6 + 2 * rightRaise + (stretching ? 2 * actionBlend : 0)), skin);

    // Hood silhouette and pointed tips.
    final headPivot = ui.Offset(x, floor - unit * 17.5);
    canvas.save();
    canvas.translate(headPivot.dx, headPivot.dy);
    canvas.rotate(_behavior.headTurn *
        actionBlend *
        (reduceFlashing ? .55 : 1) *
        (reduceMotion ? .45 : 1));
    canvas.translate(-headPivot.dx, -headPivot.dy);
    _rect(canvas, x - unit * 5, floor - unit * 23, unit * 10, unit * 11,
        hoodColor);
    _rect(canvas, x - unit * 6, floor - unit * 21, unit * 12, unit * 7,
        hoodColor);
    _rect(
        canvas, x - unit * 5, floor - unit * 25, unit * 3, unit * 5, hoodColor);
    _rect(
        canvas, x + unit * 2, floor - unit * 25, unit * 3, unit * 5, hoodColor);
    _rect(canvas, x - unit * 3, floor - unit * 20 + breathing, unit * 6,
        unit * 7, skin);

    // Face, expressive eyes and mouth.
    final eyeY = floor - unit * (hit || sleeping ? 17 : 16);
    final eyeHeight =
        sleeping || _behavior.blinkAmount > .5 ? unit * .42 : unit * 2.2;
    final eyeShiftX = _behavior.gazeX * actionBlend * unit * .42;
    final eyeShiftY = _behavior.gazeY * actionBlend * unit * .30;
    _rect(canvas, x - unit * 2.5, eyeY, unit * 1.6, eyeHeight,
        const ui.Color(0xFFF7F5D9));
    _rect(canvas, x + unit * .8, eyeY, unit * 1.6, eyeHeight,
        const ui.Color(0xFFF7F5D9));
    if (!sleeping && _behavior.blinkAmount <= .5) {
      _rect(canvas, x - unit * 1.8 + eyeShiftX, eyeY + unit * .5 + eyeShiftY,
          unit * .8, unit * 1.4, const ui.Color(0xFF202B2B));
      _rect(canvas, x + unit * 1.5 + eyeShiftX, eyeY + unit * .5 + eyeShiftY,
          unit * .8, unit * 1.4, const ui.Color(0xFF202B2B));
    }
    final mouthY = floor - unit * 13.5;
    final openMouth = yawning ||
        _behavior.mood == GoblinMood.surprised ||
        (_behavior.mood == GoblinMood.worried &&
            _behavior.state == GoblinBehaviorState.weatherReact);
    if (openMouth) {
      canvas.drawOval(
          ui.Rect.fromCenter(
              center: ui.Offset(x, mouthY),
              width: unit * (yawning ? 2.5 : 2),
              height: unit * (yawning ? 2.8 : 2)),
          ui.Paint()..color = const ui.Color(0xFF263238));
      if (yawning) {
        _rect(canvas, x + unit * 4.2, floor - unit * 17, unit * 1.8, unit * 2,
            const ui.Color(0xFFFFF1A8));
      }
    } else if (_behavior.mood == GoblinMood.happy ||
        _behavior.mood == GoblinMood.playful) {
      final smile = ui.Path()
        ..moveTo(x - unit, mouthY)
        ..quadraticBezierTo(x, mouthY + unit * 1.5, x + unit * 1.7, mouthY);
      canvas.drawPath(
          smile,
          ui.Paint()
            ..color = const ui.Color(0xFF263238)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = unit * .55);
    } else {
      _rect(canvas, x - unit, mouthY, unit * (chatting ? 3 : 2), unit * .8,
          hit ? const ui.Color(0xFF171717) : const ui.Color(0xFF356044));
    }
    canvas.restore();
    _drawGoblinEffects(canvas, w, h,
        x: x,
        floor: floor,
        unit: unit,
        hit: hit,
        chatting: chatting,
        sleeping: sleeping || resting,
        yawning: yawning,
        scratching: scratching,
        nearMiss: nearMiss,
        wipingBrow: wipingBrow,
        paddling: paddling,
        motionScale: motionScale);
  }

  void _drawLightning(ui.Canvas canvas, double w, double h) {
    if (!_thunderstorm || _strikeAge >= .34) return;
    final flashStrength = (1 - _strikeAge / .34).clamp(0.0, 1.0);
    final flashAlpha = reduceFlashing
        ? (flashStrength * (_directHit ? 24 : 12)).round()
        : (flashStrength * (_directHit ? 100 : 38)).round();
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h),
        ui.Paint()..color = ui.Color.fromARGB(flashAlpha, 238, 249, 255));
    if (_boltPoints.isEmpty) return;
    final path = ui.Path()..moveTo(_boltStartX, 0);
    for (final p in _boltPoints) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        ui.Paint()
          ..color = _boltColor
          ..strokeWidth = math.max(2.0, w * .008).toDouble()
          ..style = ui.PaintingStyle.stroke
          ..strokeJoin = ui.StrokeJoin.miter);
    // Each strike keeps its own randomized branches throughout the flash.
    final branchPaint = ui.Paint()
      ..color = const ui.Color(0xFFDDF9FF)
      ..strokeWidth = math.max(1.0, w * .0035).toDouble()
      ..style = ui.PaintingStyle.stroke;
    for (var i = 0; i < _branchStarts.length; i++) {
      final branch = ui.Path()
        ..moveTo(_branchStarts[i].dx, _branchStarts[i].dy)
        ..lineTo(_branchKnees[i].dx, _branchKnees[i].dy)
        ..lineTo(_branchTips[i].dx, _branchTips[i].dy);
      canvas.drawPath(branch, branchPaint);
    }
    if (_directHit) {
      canvas.drawCircle(
          ui.Offset(_boltTargetX, _boltTargetY),
          w * .12,
          ui.Paint()
            ..color =
                ui.Color.fromARGB((flashStrength * 45).round(), 255, 255, 255));
    }
  }

  void _rect(ui.Canvas canvas, double x, double y, double width, double height,
      ui.Color color) {
    canvas.drawRect(
        ui.Rect.fromLTWH(x, y, width, height), ui.Paint()..color = color);
  }

  void _cloud(
      ui.Canvas canvas, double x, double y, double width, ui.Color color) {
    final unit = width / 6;
    _rect(canvas, x + unit, y, unit * 3, unit, color);
    _rect(canvas, x, y + unit, unit * 6, unit * 1.25, color);
    _rect(canvas, x + unit, y + unit * 2, unit * 4, unit * .6, color);
  }
}