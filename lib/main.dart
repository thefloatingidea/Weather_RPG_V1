import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/weather_error_view.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_scene.dart';
import 'goblin_sprites.dart';
import 'weather_models.dart';
import 'world_catalog.dart';
import 'weather_rules.dart';
import 'character_behavior.dart';
import 'weather_api.dart';
import 'goblin_scenarios.dart';

void main() => runApp(const ProviderScope(child: WeatherRpgApp()));
const Color night = Color(0xFF17121A);
const Color panel = Color(0xFF2B2027);
const Color panel2 = Color(0xFF3A2926);
const Color cyan = Color(0xFFA8B876);
const Color pale = Color(0xFFF2E2C3);
const Color muted = Color(0xFFC2A98A);
const Color gold = Color(0xFFFFB94D);
const Color danger = Color(0xFFD96B4C);
const Color iron = Color(0xFF74543F);
const Color parchment = Color(0xFFE8D0A4);

class _WeatherMenuPalette {
  const _WeatherMenuPalette({
    required this.mood,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.frameTop,
    required this.frameBottom,
    required this.edge,
    required this.surface,
    required this.surfaceAlt,
    required this.paper,
    required this.accent,
    required this.highlight,
    required this.text,
    required this.muted,
    required this.botanical,
    required this.grid,
    required this.danger,
  });

  final String mood;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color frameTop;
  final Color frameBottom;
  final Color edge;
  final Color surface;
  final Color surfaceAlt;
  final Color paper;
  final Color accent;
  final Color highlight;
  final Color text;
  final Color muted;
  final Color botanical;
  final Color grid;
  final Color danger;

  factory _WeatherMenuPalette.fromWeather({
    required bool isDark,
    required SceneEnvironment environment,
    required int weatherCode,
    required double temperatureC,
    required double windSpeedKmh,
    required bool aridRegion,
    required bool seasonalFoliage,
    required bool southernHemisphere,
    required int month,
    required bool isDay,
  }) {
    final season = worldSeasonForMonth(month, southernHemisphere ? -1 : 1);
    final snow = const [71, 73, 75, 77, 85, 86].contains(weatherCode);
    final rain = const [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82]
        .contains(weatherCode);
    final storm = const [95, 96, 99].contains(weatherCode);
    final fog = const [3, 45, 48].contains(weatherCode);
    final mood = switch (environment) {
      SceneEnvironment.cyclone => 'storm',
      SceneEnvironment.flood => 'flood',
      SceneEnvironment.desertHeat => 'heat',
      SceneEnvironment.sandstorm => 'sandstorm',
      SceneEnvironment.live
          when aridRegion &&
              const [30, 31, 32, 33, 34, 35].contains(weatherCode) =>
        'sandstorm',
      SceneEnvironment.live when snow || temperatureC <= 5 => 'cold',
      SceneEnvironment.live when storm => 'storm',
      SceneEnvironment.live when rain => 'rain',
      SceneEnvironment.live when fog => 'fog',
      SceneEnvironment.live when windSpeedKmh >= strongWindThresholdKmh =>
        'wind',
      SceneEnvironment.live
          when aridRegion && temperatureC >= strongHeatThresholdC =>
        'heat',
      SceneEnvironment.live
          when seasonalFoliage && season == WorldSeason.autumn =>
        'autumn',
      SceneEnvironment.live
          when seasonalFoliage && season == WorldSeason.spring =>
        'spring',
      SceneEnvironment.live when !isDay => 'night',
      _ => 'clear',
    };

    late Color bgTop;
    late Color bgBottom;
    late Color frameTop;
    late Color frameBottom;
    late Color edge;
    late Color darkSurface;
    late Color darkSurfaceAlt;
    late Color paper;
    late Color accent;
    late Color highlight;
    late Color botanical;
    late Color grid;
    late Color danger;
    switch (mood) {
      case 'rain':
        bgTop = const Color(0xFF142127);
        bgBottom = const Color(0xFF1E3030);
        frameTop = const Color(0xFF49635E);
        frameBottom = const Color(0xFF263B3E);
        edge = const Color(0xFF8CA99A);
        darkSurface = const Color(0xFF263A3A);
        darkSurfaceAlt = const Color(0xFF344A47);
        paper = const Color(0xFFD6DDC8);
        accent = const Color(0xFF8FC4B1);
        highlight = const Color(0xFFE6D7AA);
        botanical = const Color(0xFF45644C);
        grid = const Color(0xFF58736D);
        danger = const Color(0xFFD67D60);
      case 'storm':
        bgTop = const Color(0xFF171727);
        bgBottom = const Color(0xFF241F31);
        frameTop = const Color(0xFF51445E);
        frameBottom = const Color(0xFF2C2639);
        edge = const Color(0xFF9882A5);
        darkSurface = const Color(0xFF2E293C);
        darkSurfaceAlt = const Color(0xFF3D3548);
        paper = const Color(0xFFE0D5C9);
        accent = const Color(0xFFB6A1D0);
        highlight = const Color(0xFFFFC879);
        botanical = const Color(0xFF485742);
        grid = const Color(0xFF625874);
        danger = const Color(0xFFF0806B);
      case 'cold':
        bgTop = const Color(0xFF14212A);
        bgBottom = const Color(0xFF1E303B);
        frameTop = const Color(0xFF526C78);
        frameBottom = const Color(0xFF2B414B);
        edge = const Color(0xFFA8C8D0);
        darkSurface = const Color(0xFF2D4149);
        darkSurfaceAlt = const Color(0xFF3B535B);
        paper = const Color(0xFFDCE8E5);
        accent = const Color(0xFFA8D6DE);
        highlight = const Color(0xFFF1F7E9);
        botanical = const Color(0xFF607F83);
        grid = const Color(0xFF607A83);
        danger = const Color(0xFFD78378);
      case 'heat':
        bgTop = const Color(0xFF2A1C1B);
        bgBottom = const Color(0xFF402820);
        frameTop = const Color(0xFF805135);
        frameBottom = const Color(0xFF4A3028);
        edge = const Color(0xFFD59850);
        darkSurface = const Color(0xFF503524);
        darkSurfaceAlt = const Color(0xFF65452C);
        paper = const Color(0xFFE9D0A0);
        accent = const Color(0xFFE7A751);
        highlight = const Color(0xFFFFE19B);
        botanical = const Color(0xFF667342);
        grid = const Color(0xFF86603B);
        danger = const Color(0xFFE17A53);
      case 'sandstorm':
        bgTop = const Color(0xFF3A201A);
        bgBottom = const Color(0xFF5A3020);
        frameTop = const Color(0xFFA25C32);
        frameBottom = const Color(0xFF63351F);
        edge = const Color(0xFFE1A35C);
        darkSurface = const Color(0xFF613921);
        darkSurfaceAlt = const Color(0xFF794729);
        paper = const Color(0xFFE7C28C);
        accent = const Color(0xFFEDAA58);
        highlight = const Color(0xFFFFD58B);
        botanical = const Color(0xFF8A6538);
        grid = const Color(0xFFA36B3D);
        danger = const Color(0xFFE4774D);
      case 'flood':
        bgTop = const Color(0xFF172226);
        bgBottom = const Color(0xFF282F2B);
        frameTop = const Color(0xFF53604F);
        frameBottom = const Color(0xFF343A31);
        edge = const Color(0xFF9B9A70);
        darkSurface = const Color(0xFF343D35);
        darkSurfaceAlt = const Color(0xFF45483A);
        paper = const Color(0xFFD8D0B5);
        accent = const Color(0xFFB5A36C);
        highlight = const Color(0xFFD6C37E);
        botanical = const Color(0xFF59634A);
        grid = const Color(0xFF69705A);
        danger = const Color(0xFFE47758);
      case 'wind':
        bgTop = const Color(0xFF1D222B);
        bgBottom = const Color(0xFF34343A);
        frameTop = const Color(0xFF72705F);
        frameBottom = const Color(0xFF414047);
        edge = const Color(0xFFB6AC8D);
        darkSurface = const Color(0xFF3C3D40);
        darkSurfaceAlt = const Color(0xFF4C4B49);
        paper = const Color(0xFFE0D9C6);
        accent = const Color(0xFFC4B58D);
        highlight = const Color(0xFFE8D5A5);
        botanical = const Color(0xFF6D7057);
        grid = const Color(0xFF77766A);
        danger = const Color(0xFFDA8066);
      case 'fog':
        bgTop = const Color(0xFF202528);
        bgBottom = const Color(0xFF303435);
        frameTop = const Color(0xFF68726C);
        frameBottom = const Color(0xFF3A403F);
        edge = const Color(0xFFAAB5A8);
        darkSurface = const Color(0xFF3A4140);
        darkSurfaceAlt = const Color(0xFF4A514D);
        paper = const Color(0xFFE0E1D2);
        accent = const Color(0xFFB2C3A0);
        highlight = const Color(0xFFE9D9AC);
        botanical = const Color(0xFF67745B);
        grid = const Color(0xFF737D74);
        danger = const Color(0xFFD47D67);
      case 'autumn':
        bgTop = const Color(0xFF241B1B);
        bgBottom = const Color(0xFF38251F);
        frameTop = const Color(0xFF76503A);
        frameBottom = const Color(0xFF432D28);
        edge = const Color(0xFFC18B50);
        darkSurface = const Color(0xFF49332A);
        darkSurfaceAlt = const Color(0xFF5A4030);
        paper = const Color(0xFFE8D1A7);
        accent = const Color(0xFFD18A48);
        highlight = const Color(0xFFF4C36C);
        botanical = const Color(0xFF9C5C35);
        grid = const Color(0xFF76563B);
        danger = const Color(0xFFD96B4C);
      case 'spring':
        bgTop = const Color(0xFF1B2420);
        bgBottom = const Color(0xFF293329);
        frameTop = const Color(0xFF526440);
        frameBottom = const Color(0xFF344032);
        edge = const Color(0xFF9DAD6B);
        darkSurface = const Color(0xFF344034);
        darkSurfaceAlt = const Color(0xFF43513C);
        paper = const Color(0xFFE4DAB6);
        accent = const Color(0xFFB6C779);
        highlight = const Color(0xFFF2C9B2);
        botanical = const Color(0xFF59824B);
        grid = const Color(0xFF61714D);
        danger = const Color(0xFFD97460);
      case 'night':
        bgTop = const Color(0xFF11182A);
        bgBottom = const Color(0xFF20243A);
        frameTop = const Color(0xFF46506A);
        frameBottom = const Color(0xFF28283B);
        edge = const Color(0xFF8895B4);
        darkSurface = const Color(0xFF292C40);
        darkSurfaceAlt = const Color(0xFF37384D);
        paper = const Color(0xFFDDD6C0);
        accent = const Color(0xFFA6B8D9);
        highlight = const Color(0xFFFFCF79);
        botanical = const Color(0xFF435846);
        grid = const Color(0xFF535D78);
        danger = const Color(0xFFD87968);
      default:
        bgTop = const Color(0xFF1D221C);
        bgBottom = const Color(0xFF2E3023);
        frameTop = const Color(0xFF62603D);
        frameBottom = const Color(0xFF373126);
        edge = const Color(0xFFA69A5E);
        darkSurface = const Color(0xFF39382A);
        darkSurfaceAlt = const Color(0xFF4B4933);
        paper = const Color(0xFFE8D8AF);
        accent = const Color(0xFFC2C17A);
        highlight = const Color(0xFFFFD27D);
        botanical = const Color(0xFF62794C);
        grid = const Color(0xFF6B6847);
        danger = const Color(0xFFD96B4C);
    }

    if (isDark) {
      return _WeatherMenuPalette(
        mood: mood,
        backgroundTop: bgTop,
        backgroundBottom: bgBottom,
        frameTop: frameTop,
        frameBottom: frameBottom,
        edge: edge,
        surface: darkSurface,
        surfaceAlt: darkSurfaceAlt,
        paper: paper,
        accent: accent,
        highlight: highlight,
        text: const Color(0xFFF0E6D2),
        muted: const Color(0xFFC4B9A3),
        botanical: botanical,
        grid: grid,
        danger: danger,
      );
    }

    final lightBackground = Color.lerp(paper, Colors.white, .58)!;
    final lightSurface = Color.lerp(paper, Colors.white, .36)!;
    return _WeatherMenuPalette(
      mood: mood,
      backgroundTop: lightBackground,
      backgroundBottom: Color.lerp(lightBackground, bgBottom, .10)!,
      frameTop: Color.lerp(frameTop, paper, .35)!,
      frameBottom: Color.lerp(frameBottom, bgBottom, .22)!,
      edge: Color.lerp(edge, Colors.white, .12)!,
      surface: lightSurface,
      surfaceAlt: Color.lerp(lightSurface, paper, .35)!,
      paper: Color.lerp(paper, Colors.white, .18)!,
      accent: Color.lerp(accent, bgBottom, .16)!,
      highlight: accent,
      text: const Color(0xFF33271F),
      muted: const Color(0xFF695744),
      botanical: Color.lerp(botanical, bgBottom, .12)!,
      grid: Color.lerp(grid, bgBottom, .18)!,
      danger: danger,
    );
  }
}

/// Owns the nickname text controller, so it is disposed with the widget rather
/// than when `showDialog` resolves. Disposing earlier leaves the closing
/// TextField holding a disposed controller during the route's exit animation.
class _NicknameDialog extends StatefulWidget {
  const _NicknameDialog({required this.city, this.initial});

  final String city;
  final String? initial;

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void close([String? value]) => Navigator.of(context).pop(value);

    return AlertDialog(
      title: Text('Nickname for ${widget.city}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'e.g. Home, Office',
          labelText: 'Nickname',
        ),
        onSubmitted: close,
      ),
      actions: [
        TextButton(onPressed: () => close(), child: const Text('Cancel')),
        TextButton(onPressed: () => close(''), child: const Text('Clear')),
        FilledButton(
          onPressed: () => close(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class WeatherRpgApp extends ConsumerStatefulWidget {
  const WeatherRpgApp({super.key});
  @override
  ConsumerState<WeatherRpgApp> createState() => _WeatherRpgAppState();
}

class _WeatherRpgAppState extends ConsumerState<WeatherRpgApp> {
  ThemeMode themeMode = ThemeMode.dark;
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final stored = await _prefs.getString('theme_mode');
    if (!mounted || stored == null) return;
    setState(() => themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == stored,
          orElse: () => ThemeMode.dark,
        ));
  }

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => themeMode = mode);
    try {
      await _prefs.setString('theme_mode', mode.name);
    } catch (_) {
      // Keep the selected theme active for this session if storage is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather RPG',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF687A49),
          surface: const Color(0xFFE8DCC4),
        ),
        scaffoldBackgroundColor: const Color(0xFFE1D0B1),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF2E5CC),
          labelStyle: TextStyle(color: Color(0xFF66513D)),
          hintStyle: TextStyle(color: Color(0xFF8B745D)),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: night,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF87975E),
          brightness: Brightness.dark,
          surface: panel,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF34262A),
          labelStyle: TextStyle(color: muted),
          hintStyle: TextStyle(color: muted),
        ),
        useMaterial3: true,
      ),
      home: WeatherHome(
        onThemeChanged: _setTheme,
        themeMode: themeMode,
      ),
    );
  }
}

class WeatherHome extends ConsumerStatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode themeMode;
  const WeatherHome({
    super.key,
    required this.onThemeChanged,
    required this.themeMode,
  });
  @override
  ConsumerState<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends ConsumerState<WeatherHome>
    with TickerProviderStateMixin {
  late final AnimationController _weatherAnimation;
  WeatherBundle? _weather;
  bool _loading = true;
  Object? _error;
  int _tab = 0;
  String _city = 'Mumbai';
  String _region = 'Maharashtra, India';
  double _lat = 19.0760;
  double _lon = 72.8777;
  String _unit = '°C';
  bool _fahrenheit = false;
  bool _reduceFlashing = false;
  bool _extremeScenarios = true;
  final List<SavedPlace> _savedPlaces = [
    const SavedPlace(
      city: 'Mumbai',
      region: 'Maharashtra, India',
      latitude: 19.0760,
      longitude: 72.8777,
    ),
  ];
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  
final WeatherApiClient _weatherApi = const WeatherApiClient();
  static const _weatherCacheKey = 'weatherapi_cache_v1';
  DateTime? _lastUpdated;
  bool _usingCachedWeather = false;
  bool _gettingLocation = false;
  int _weatherRequestId = 0;
  CharacterProfile _characterProfile = const CharacterProfile();
  String _sceneWeatherPreviousKey = '';

  WorldLocation get _worldLocation => resolveWorldLocation(
        city: _city,
        region: _region,
        latitude: _lat,
        longitude: _lon,
      );

  @override
  void initState() {
    super.initState();
    _weatherAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    unawaited(_initializeApp());
  }

  @override
  void dispose() {
    _weatherAnimation.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Warm the character sprite cache up front so the first scene renders with
    // the sprite character instead of briefly falling back to the procedural one.
    unawaited(GoblinSprites.warmCache());
    try {
      final values = await Future.wait<Object?>([
        _prefs.getString('selected_place'),
        _prefs.getStringList('saved_cities'),
        _prefs.getBool('fahrenheit'),
        _prefs.getBool('reduce_flashing'),
        _prefs.getBool('extreme_scenarios'),
        _prefs.getString(_weatherCacheKey),
        _prefs.getString('character_profile_v1'),
      ]);
      if (!mounted) return;
      final selectedPlace = values[0] as String?;
      final savedCities = values[1] as List<String>?;
      final fahrenheit = values[2] as bool?;
      final reduceFlashing = values[3] as bool?;
      final extremeScenarios = values[4] as bool?;
      if (selectedPlace != null) {
        final place = jsonDecode(selectedPlace) as Map<String, dynamic>;
        _city = place['city'] as String? ?? _city;
        _region = place['region'] as String? ?? _region;
        _lat = (place['latitude'] as num?)?.toDouble() ?? _lat;
        _lon = (place['longitude'] as num?)?.toDouble() ?? _lon;
      }
      if (savedCities != null && savedCities.isNotEmpty) {
        final restored = <SavedPlace>[];
        for (final entry in savedCities) {
          final place = SavedPlace.parse(entry);
          if (place != null && !restored.any((p) => p.samePlace(place))) {
            restored.add(place);
          }
        }
        if (restored.isNotEmpty) {
          _savedPlaces
            ..clear()
            ..addAll(restored);
        }
      }
      if (fahrenheit != null) {
        _fahrenheit = fahrenheit;
        _unit = _fahrenheit ? '°F' : '°C';
      }
      if (reduceFlashing != null) _reduceFlashing = reduceFlashing;
      if (extremeScenarios != null) _extremeScenarios = extremeScenarios;

      final cacheJson = values[5] as String?;
      final profileJson = values[6] as String?;
      if (profileJson != null) {
        _characterProfile = CharacterProfile.fromJson(
            jsonDecode(profileJson) as Map<String, dynamic>);
      }
      if (cacheJson != null) {
        final cache = jsonDecode(cacheJson) as Map<String, dynamic>;
        final cacheLat = (cache['latitude'] as num).toDouble();
        final cacheLon = (cache['longitude'] as num).toDouble();
        if ((cacheLat - _lat).abs() < .001 && (cacheLon - _lon).abs() < .001) {
          _weather =
              WeatherBundle.fromJson(cache['weather'] as Map<String, dynamic>);
          _lastUpdated = DateTime.tryParse(cache['savedAt'] as String? ?? '');
          _usingCachedWeather = true;
        }
      }
      setState(() {});
    } catch (_) {
      // A malformed or older preference should not prevent live weather loading.
    }
    if (mounted) await _fetchWeather();
  }

  Future<void> _savePreferences() async {
    try {
      await Future.wait([
        _prefs.setString(
            'selected_place',
            jsonEncode({
              'city': _city,
              'region': _region,
              'latitude': _lat,
              'longitude': _lon,
            })),
        _prefs.setStringList(
            'saved_cities', _savedPlaces.map((p) => p.toJsonString()).toList()),
        _prefs.setBool('fahrenheit', _fahrenheit),
        _prefs.setBool('reduce_flashing', _reduceFlashing),
        _prefs.setBool('extreme_scenarios', _extremeScenarios),
      ]);
    } catch (_) {
      // Preferences remain usable in memory for the current session.
    }
  }

  void _recordCharacterContext({
    required String weatherKey,
    required String season,
    required bool enteredLocation,
  }) {
    final place = _worldLocation;
    final previousLocationId = _characterProfile.currentLocationId;
    final update = _characterProfile.recordContext(
      locationId: place.id,
      locationName: place.name,
      landmarkId: place.landmark.name,
      landmarkName: place.landmark == WorldLandmark.none
          ? place.name
          : _landmarkName(place.landmark),
      weatherKey: weatherKey,
      season: season,
      enteredLocation: enteredLocation,
    );
    _characterProfile = update.profile;
    if (update.addedEvents.isNotEmpty ||
        previousLocationId != update.profile.currentLocationId) {
      unawaited(_persistCharacterProfile());
    }
  }

  Future<void> _persistCharacterProfile() async {
    try {
      await _prefs.setString(
        'character_profile_v1',
        jsonEncode(_characterProfile.toJson()),
      );
    } catch (_) {
      // Character memories remain available for this session.
    }
  }

  /// The set-piece scene the current reading calls for, or
  /// [SceneEnvironment.live] when the user has switched extreme scenarios off.
  ///
  /// This is what makes the cyclone, flood, sandstorm and desert-heat scenes
  /// reachable: they were previously only addressable by constructing a config
  /// by hand, so nothing in the app ever showed them.
  SceneEnvironment get _sceneEnvironment {
    if (!_extremeScenarios) return SceneEnvironment.live;
    final current = _weather?.current;
    if (current == null) return SceneEnvironment.live;
    // Rain accumulated today is a far better flood signal than one reading, and
    // it is already in the normalized bundle as `rain_sum`.
    final daily = _weather?.daily;
    final rainSums = daily?['rain_sum'];
    final dailyRain = rainSums is List && rainSums.isNotEmpty
        ? (rainSums.first as num?)?.toDouble()
        : null;
    return resolveSceneEnvironment(
      conditions: WeatherConditions(
        code: (current['weather_code'] as num?)?.toInt() ?? 0,
        temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 20,
        precipitationMm: (current['precipitation'] as num?)?.toDouble() ?? 0,
        windKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
        cloudCover: (current['cloud_cover'] as num?)?.toDouble(),
        visibilityM: (current['visibility'] as num?)?.toDouble(),
      ),
      aridRegion: _worldLocation.isArid,
      isDay: (current['is_day'] as num?)?.toInt() == 1,
      dailyPrecipitationMm: dailyRain,
      latitude: _lat,
    );
  }

  String _weatherMemoryKey(WeatherBundle? weather) {
    final current = weather?.current;
    final code = (current?['weather_code'] as num?)?.toInt() ?? 0;
    if (const {30, 31, 32, 33, 34, 35}.contains(code)) return 'dust';
    if (const [95, 96, 99].contains(code)) return 'storm';
    if (const [71, 73, 75, 77, 85, 86].contains(code)) return 'snow';
    if (const [51, 53, 55, 56, 57].contains(code)) return 'drizzle';
    if (const [61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return 'rain';
    return 'clear';
  }

  String _sceneWeatherKey(WeatherBundle? weather) {
    final current = weather?.current;
    if (current == null) return '';
    final conditions = WeatherConditions(
      code: (current['weather_code'] as num?)?.toInt() ?? 0,
      temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 20,
      precipitationMm: (current['precipitation'] as num?)?.toDouble() ?? 0,
      windKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      cloudCover: (current['cloud_cover'] as num?)?.toDouble(),
      visibilityM: (current['visibility'] as num?)?.toDouble(),
    );
    if (conditions.thunderstorm) return 'storm';
    if (conditions.snowing) return 'snow';
    if (conditions.raining) {
      return conditions.rainIntensity >= .65 ? 'heavy rain' : 'drizzle';
    }
    if (conditions.dusty) return 'sand';
    final isDay = (current['is_day'] as num?)?.toInt() == 1;
    if (conditions.temperatureC >= strongHeatThresholdC && isDay) return 'heat';
    if (conditions.foggy) return 'fog';
    if (conditions.temperatureC <= 5) return 'cold';
    if (conditions.windKmh >= windyThresholdKmh) return 'wind';
    return 'clear';
  }

  String _landmarkName(WorldLandmark landmark) => switch (landmark) {
        WorldLandmark.none => 'the landscape',
        WorldLandmark.tajMahal => 'the Taj Mahal',
        WorldLandmark.jaisalmerFort => 'Jaisalmer Fort',
        WorldLandmark.hawaMahal => 'Hawa Mahal',
        WorldLandmark.indiaGate => 'India Gate',
        WorldLandmark.gatewayOfIndia => 'the Gateway of India',
        WorldLandmark.howrahBridge => 'Howrah Bridge',
        WorldLandmark.varanasiGhats => 'the Varanasi ghats',
        WorldLandmark.goldenTemple => 'the Golden Temple',
        WorldLandmark.charminar => 'Charminar',
        WorldLandmark.chennaiLighthouse => 'the Chennai lighthouse',
        WorldLandmark.bengaluruPalace => 'Bengaluru Palace',
        WorldLandmark.kochiFishingNets => 'Kochi’s fishing nets',
        WorldLandmark.srinagarLake => 'Dal Lake',
        WorldLandmark.shimlaHills => 'the Shimla hills',
        WorldLandmark.lehMonastery => 'the Leh monastery',
        WorldLandmark.rishikeshBridge => 'the Rishikesh bridge',
        WorldLandmark.bhopalLake => 'Bhopal Lake',
        WorldLandmark.eiffelTower => 'the Eiffel Tower',
        WorldLandmark.bigBen => 'Big Ben',
        WorldLandmark.newYorkSkyline => 'the New York skyline',
        WorldLandmark.tokyoFuji => 'Mount Fuji',
        WorldLandmark.colosseum => 'the Colosseum',
        WorldLandmark.cairoPyramids => 'the Pyramids of Giza',
        WorldLandmark.sydneyOperaHouse => 'the Sydney Opera House',
        WorldLandmark.rioMountain => 'Sugarloaf Mountain',
        WorldLandmark.dubaiTower => 'the Burj Khalifa',
        WorldLandmark.singaporeSkyline => 'the Singapore skyline',
      };

  Future<void> _fetchWeather() async {
    final requestId = ++_weatherRequestId;
    final requestedCity = _city;
    final requestedRegion = _region;
    final requestedLat = _lat;
    final requestedLon = _lon;
    final previousWeatherKey = _sceneWeatherKey(_weather);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _weatherApi.fetchForecast(
        latitude: requestedLat,
        longitude: requestedLon,
      );
      if (!mounted || requestId != _weatherRequestId) return;
      final savedAt = DateTime.now();
      setState(() {
        _weather = result;
        _sceneWeatherPreviousKey = previousWeatherKey;
        _lastUpdated = savedAt;
        _usingCachedWeather = false;
        _loading = false;
      });
      final sceneDate =
          DateTime.tryParse(result.current['time']?.toString() ?? '');
      _recordCharacterContext(
        weatherKey: _weatherMemoryKey(result),
        season:
            worldSeasonForMonth(sceneDate?.month ?? DateTime.now().month, _lat)
                .name,
        enteredLocation:
            _characterProfile.currentLocationId != _worldLocation.id,
      );
      try {
        await _prefs.setString(
            _weatherCacheKey,
            jsonEncode({
              'city': requestedCity,
              'region': requestedRegion,
              'latitude': requestedLat,
              'longitude': requestedLon,
              'savedAt': savedAt.toIso8601String(),
              'weather': result.toJson(),
            }));
      } catch (_) {
        // Live data is already visible; a storage failure should not mask it.
      }
    } catch (error) {
      if (!mounted || requestId != _weatherRequestId) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _useMyLocation() async {
    if (_gettingLocation) return;
    setState(() => _gettingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on device location services and try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Allow location access in your device settings.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final lat = position.latitude;
      final lon = position.longitude;
      const city = 'My Location';
      setState(() {
        _city = city;
        // Coordinates live in their own fields now; the region no longer has to
        // double as a coordinate string.
        _region = city;
        _lat = lat;
        _lon = lon;
        _tab = 0;
        _weather = null;
        _loading = true;
        _lastUpdated = null;
        _usingCachedWeather = false;
        _sceneWeatherPreviousKey = '';
        _rememberPlace(SavedPlace(
          city: city,
          region: city,
          latitude: lat,
          longitude: lon,
        ));
      });
      await _savePreferences();
      await _fetchWeather();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<PlaceResult?> _geocode(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final results = await _weatherApi.search(query);
      return results.isEmpty ? null : results.first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _chooseCity() async {
    // Use a dedicated route instead of a dialog. This avoids the focus /
    // inherited-widget teardown path that can trigger framework assertions
    // on some Flutter/Android combinations when the keyboard is open.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _menuPalette(isDark);
    final result = await Navigator.of(context).push<PlaceResult>(
      MaterialPageRoute<PlaceResult>(
        builder: (_) => CitySearchPage(
          searchCity: _geocode,
          backgroundTop: palette.backgroundTop,
          backgroundBottom: palette.backgroundBottom,
          frameTop: palette.frameTop,
          frameBottom: palette.frameBottom,
          surface: palette.surface,
          surfaceAlt: palette.surfaceAlt,
          edge: palette.edge,
          accent: palette.accent,
          highlight: palette.highlight,
          text: palette.text,
          muted: palette.muted,
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _city = result.city;
      _region = result.region;
      _lat = result.latitude;
      _lon = result.longitude;
      _tab = 0;
      _weather = null;
      _loading = true;
      _lastUpdated = null;
      _usingCachedWeather = false;
      _sceneWeatherPreviousKey = '';
      _rememberPlace(SavedPlace(
        city: result.city,
        region: result.region,
        latitude: result.latitude,
        longitude: result.longitude,
      ));
    });
    await _savePreferences();
    await _fetchWeather();
  }

  /// Adds a place to the saved list, preserving any nickname already given to
  /// the same location and never storing duplicates.
  void _rememberPlace(SavedPlace place) {
    final index = _savedPlaces.indexWhere((p) => p.samePlace(place));
    if (index >= 0) {
      final existing = _savedPlaces[index];
      if (existing.label != null && place.label == null) {
        _savedPlaces[index] = place.copyWith(label: existing.label);
      }
      return;
    }
    _savedPlaces.add(place);
  }

  void _removePlace(SavedPlace place) {
    setState(() {
      _savedPlaces.removeWhere((p) => p.samePlace(place));
    });
    unawaited(_savePreferences());
  }

  /// Prompts for a nickname. Returns the new label, an empty string to clear it,
  /// or null when the user cancels.
  Future<String?> _promptForNickname(SavedPlace place) => showDialog<String>(
        context: context,
        builder: (_) => _NicknameDialog(city: place.city, initial: place.label),
      );

  Future<void> _renamePlace(SavedPlace place) async {
    final label = await _promptForNickname(place);
    if (!mounted || label == null) return;
    final trimmed = label.trim();
    setState(() {
      final index = _savedPlaces.indexWhere((p) => p.samePlace(place));
      if (index < 0) return;
      _savedPlaces[index] = trimmed.isEmpty
          ? _savedPlaces[index].copyWith(clearLabel: true)
          : _savedPlaces[index].copyWith(label: trimmed);
    });
    unawaited(_savePreferences());
  }

  void _openSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _menuPalette(isDark);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              const Text('Appearance'),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {widget.themeMode},
                onSelectionChanged: (value) {
                  widget.onThemeChanged(value.first);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 18),
              const Text('Temperature units'),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Celsius °C')),
                  ButtonSegment(value: true, label: Text('Fahrenheit °F')),
                ],
                selected: {_fahrenheit},
                onSelectionChanged: (value) {
                  setState(() {
                    _fahrenheit = value.first;
                    _unit = _fahrenheit ? '°F' : '°C';
                  });
                  unawaited(_savePreferences());
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _extremeScenarios,
                title: const Text('Extreme weather scenes'),
                subtitle: const Text(
                    'Switch to the cyclone, flood, sandstorm or desert-heat '
                    'scene when the weather calls for it.'),
                onChanged: (value) {
                  setState(() => _extremeScenarios = value);
                  unawaited(_savePreferences());
                  setSheetState(() {});
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _reduceFlashing,
                title: const Text('Reduce flashing effects'),
                subtitle: const Text(
                    'Soften lightning flashes and disable impact vibration.'),
                onChanged: (value) {
                  setState(() => _reduceFlashing = value);
                  unawaited(_savePreferences());
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Weather data by WeatherAPI.com. Scene effects are decorative; alerts are not official emergency warnings.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _menuPalette(isDark);
    final baseTheme = Theme.of(context);
    final adaptiveTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: palette.accent,
        secondary: palette.highlight,
        surface: palette.surface,
        onSurface: palette.text,
        error: palette.danger,
      ),
      scaffoldBackgroundColor: palette.backgroundBottom,
    );
    return Theme(
      data: adaptiveTheme,
      child: Scaffold(
        backgroundColor: palette.backgroundBottom,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ForestBackdropPainter(palette: palette),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MenuParticlePainter(
                    animation: _weatherAnimation,
                    environment: _sceneEnvironment,
                    aridRegion: _worldLocation.isArid,
                    seasonalFoliage: _worldLocation.seasonalFoliage,
                    latitude: _lat,
                    weatherCode:
                        (_weather?.current['weather_code'] as num?)?.toInt() ??
                            0,
                    precipitationMm:
                        (_weather?.current['precipitation'] as num?)
                                ?.toDouble() ??
                            0,
                    temperatureC: (_weather?.current['temperature_2m'] as num?)
                            ?.toDouble() ??
                        20,
                    month: DateTime.tryParse(
                                _weather?.current['time']?.toString() ?? '')
                            ?.month ??
                        DateTime.now().month,
                    isDay: (_weather?.current['is_day'] as num?)?.toInt() == 1,
                    palette: palette,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _topBar(palette),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchWeather,
                      color: palette.highlight,
                      child: _loading && _weather == null
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 220),
                                Center(child: CircularProgressIndicator()),
                                SizedBox(height: 220),
                              ],
                            )
                          : _error != null && _weather == null
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height *
                                          0.6,
                                      child: WeatherErrorView(
                                        error: _error!,
                                        onRetry: _fetchWeather,
                                      ),
                                    ),
                                  ],
                                )
                              : _buildTab(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _bottomNav(isDark, palette),
      ),
    );
  }

  _WeatherMenuPalette _menuPalette(bool isDark) {
    final current = _weather?.current;
    final sceneDate = DateTime.tryParse(current?['time']?.toString() ?? '');
    return _WeatherMenuPalette.fromWeather(
      isDark: isDark,
      environment: _sceneEnvironment,
      weatherCode: (current?['weather_code'] as num?)?.toInt() ?? 0,
      temperatureC: (current?['temperature_2m'] as num?)?.toDouble() ?? 20,
      windSpeedKmh: (current?['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      aridRegion: _worldLocation.isArid,
      seasonalFoliage: _worldLocation.seasonalFoliage,
      southernHemisphere: _lat < 0,
      month: sceneDate?.month ?? DateTime.now().month,
      isDay: current == null || (current['is_day'] as num?)?.toInt() == 1,
    );
  }

  Widget _topBar(_WeatherMenuPalette palette) => Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.frameTop, palette.frameBottom],
          ),
          border: Border.all(color: palette.edge, width: 1.5),
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
                color: palette.backgroundTop.withOpacity(.72),
                offset: Offset(0, 4),
                blurRadius: 8),
            BoxShadow(
                color: palette.botanical.withOpacity(.22),
                offset: Offset(-3, 0),
                blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    palette.highlight,
                    palette.accent,
                    palette.frameBottom
                  ],
                ),
                border: Border.all(color: palette.edge, width: 2),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                      color: palette.highlight.withOpacity(.36),
                      blurRadius: 12),
                ],
              ),
              child: Icon(Icons.local_fire_department,
                  color: palette.text, size: 25),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WEATHER RPG',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: palette.text,
                      )),
                  Text('FIELD NOTES FROM A LIVING WORLD',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 9,
                        letterSpacing: 1.15,
                      )),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Search city',
              onPressed: _chooseCity,
              icon: Icon(Icons.location_on_outlined, color: palette.highlight),
            ),
            IconButton(
              tooltip: 'Use my location',
              onPressed: _gettingLocation ? null : _useMyLocation,
              icon: _gettingLocation
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.my_location, color: palette.highlight),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
      );

  Widget _buildTab(bool isDark) {
    final weather = _weather!;
    switch (_tab) {
      case 1:
        return _hourlyScreen(weather, isDark);
      case 2:
        return _weeklyScreen(weather, isDark);
      case 3:
        return _placesScreen(isDark);
      case 4:
        return _journalScreen(isDark);
      default:
        return _homeScreen(weather, isDark);
    }
  }

  Widget _homeScreen(WeatherBundle w, bool isDark) {
    final palette = _menuPalette(isDark);
    final c = w.current;
    final code = (c['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = (c['is_day'] as num?)?.toInt() == 1;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final sceneDate = DateTime.tryParse(c['time']?.toString() ?? '');
    final sceneMonth = sceneDate?.month ?? DateTime.now().month;
    final temp = _temp(c['temperature_2m'] ?? 20);
    final temperatureC = (c['temperature_2m'] as num?)?.toDouble() ?? 20;
    final windKmh = (c['wind_speed_10m'] as num?)?.toDouble() ?? 0;
    final precipitationMm = (c['precipitation'] as num?)?.toDouble() ?? 0;
    final season = worldSeasonForMonth(sceneMonth, _lat);
   final scenario = pickScenario(
  ctx: ScenarioContext(
    weatherCode: code,
    isDay: isDay,
    temperatureC: temperatureC,
    windKmh: windKmh,
    precipitationMm: precipitationMm,
    biome: _worldLocation.biome,
    landmark: _worldLocation.landmark,
    season: season,
    visitCount: _characterProfile.visitCounts[_worldLocation.id] ?? 1,
    hourOfDay: sceneDate?.hour ?? DateTime.now().hour,
    isFirstRainHere:
        !_characterProfile.weatherExperiences.contains('rain'),
    isFirstSnowHere:
        !_characterProfile.weatherExperiences.contains('snow'),
    isFirstStormHere:
        !_characterProfile.weatherExperiences.contains('thunderstorm'),
  ),
  temperament: _characterProfile.temperament,
   seed: Object.hash(
    _worldLocation.id,
    code,
    isDay,
    (temperatureC * 10).round(),
    (windKmh / 5).round(),
    (precipitationMm * 10).round(),
    sceneDate?.hour ?? DateTime.now().hour,
    _characterProfile.weatherExperiences.length,
  ),
);
    // Use the tropical ocean scene on warm, clear daytime conditions.
    // Normalized clear codes represent clear / mostly clear skies.
    final summerClear = isDay && [0, 1].contains(code) && temperatureC >= 25.0;
    final feels = _temp(c['apparent_temperature']);
    final condition = weatherLabel(code);
    final rainProb = _currentRainProbability(w);
    // The HUD names the set-piece scene when one is active, so the label always
    // describes what is actually on screen.
    final environment = _sceneEnvironment;
    final environmentLabel = environment == SceneEnvironment.live
        ? _sceneName(
            code,
            isDay,
            summerClear: summerClear,
            windKmh: windKmh,
          )
        : sceneEnvironmentLabel(environment);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      children: [
        _locationStrip(isDark, palette),
        if (_lastUpdated != null || _error != null) ...[
          const SizedBox(height: 8),
          _weatherStatusBanner(palette),
        ],
        const SizedBox(height: 12),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'WORLD  //  ${_worldLocation.name.toUpperCase()}',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: .7,
              fontWeight: FontWeight.w800,
              color: palette.highlight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _pixelPanel(
          isDark: isDark,
          borderColor: palette.highlight,
          parchmentPage: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scenario.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GOBLIN'S WEATHER MINI-SCENE",
                      style: TextStyle(
                        color: palette.frameBottom.withOpacity(.72),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
  children: [
    Text(scenario.emoji, style: const TextStyle(fontSize: 14)),
    const SizedBox(width: 6),
    Expanded(
      child: Text(
        scenario.title.toUpperCase(),
        style: TextStyle(
          color: palette.frameBottom,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
    ),
  ],
),
const SizedBox(height: 3),
Text(
  scenario.body,
  style: TextStyle(
    color: palette.frameBottom.withValues(alpha: .84),
    fontSize: 12,
    height: 1.25,
  ),
),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.frameTop, palette.frameBottom],
            ),
            border: Border.all(color: palette.edge, width: 1.5),
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                  color: palette.backgroundTop.withOpacity(.75),
                  offset: Offset(0, 5),
                  blurRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 350,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WeatherSceneHost(
                    key: ValueKey(
                        'scene-${_city.toLowerCase()}-${_worldLocation.id}'),
                    config: WeatherSceneConfig(
                      weatherCode: code,
                      isDay: isDay,
                      temperatureC: temperatureC,
                      windKmh: windKmh,
                      precipitationMm: precipitationMm,
                      month: sceneMonth,
                      latitude: _lat,
                      longitude: _lon,
                      city: _city,
                      region: _region,
                      cloudCover: (c['cloud_cover'] as num?)?.toDouble(),
                      visibilityM: (c['visibility'] as num?)?.toDouble(),
                      windDirectionDeg:
                          (c['wind_direction_10m'] as num?)?.toDouble() ?? 0,
                      localHour:
                          DateTime.tryParse(c['time']?.toString() ?? '')?.hour,
                      profile: _characterProfile,
                      previousWeatherKey: _sceneWeatherPreviousKey,
                      reduceMotion: reduceMotion,
                      location: _worldLocation,
                      environment: _sceneEnvironment,
                      reduceFlashing: _reduceFlashing,
                      scenario: scenario, 
                    ),
                  ),
                  // Lightweight HUD stays in Flutter; the entire animated world
                  // and its character sprites are rendered by Flame.
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _hudTag(
                        environmentLabel, Icons.explore_outlined, palette),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _hudTag(
                        isDay ? 'DAYTIME' : 'NIGHTFALL',
                        isDay
                            ? Icons.wb_sunny_outlined
                            : Icons.nightlight_outlined,
                        palette),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _hudTag("PIXEL WORLD", Icons.bolt, palette),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _hudTag('TAP TO CHAT · HOLD TO PLAY',
                        Icons.touch_app_outlined, palette),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _SceneFrameEtchingPainter(palette: palette),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _pixelPanel(
          isDark: isDark,
          borderColor: palette.accent,
          parchmentPage: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(weatherEmoji(code, isDay),
                  style: const TextStyle(fontSize: 45)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$temp$_unit',
                        style: TextStyle(
                          fontSize: 39,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.6,
                          color: palette.frameBottom,
                        )),
                    const SizedBox(height: 5),
                    Text(condition.toUpperCase(),
                        style: TextStyle(
                          color: palette.frameBottom,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          fontSize: 12,
                        )),
                    Text('Feels like $feels$_unit',
                        style: TextStyle(
                            color: palette.frameBottom.withOpacity(.78),
                            fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('H ${_temp(w.daily['temperature_2m_max'][0])}°',
                      style: TextStyle(
                          color: palette.danger, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('L ${_temp(w.daily['temperature_2m_min'][0])}°',
                      style: TextStyle(
                          color: palette.accent, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.water_drop,
                value: '${c['relative_humidity_2m']}%',
                label: 'HUMIDITY',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                icon: Icons.air,
                value: '${(c['wind_speed_10m'] as num).round()} km/h',
                label: 'WIND',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricCard(
                icon: Icons.umbrella,
                value: '${_number(c['precipitation'])} mm',
                label: 'RAIN NOW',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _alertPanel(code: code, rainProbability: rainProb, isDark: isDark),
        const SizedBox(height: 20),
        _sectionHeader(
            'HOURLY FORECAST', 'VIEW ALL', () => setState(() => _tab = 1)),
        const SizedBox(height: 9),
        _hourlyStrip(w, isDark, count: 6),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Weather data by WeatherAPI.com • Pull down to refresh',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 10),
          ),
        ),
      ],
    );
  }

  

  String _sceneName(
    int code,
    bool isDay, {
    bool summerClear = false,
    double windKmh = 0,
  }) {
    if (summerClear) return 'SUNLIT LANDSCAPE';
    if ([95, 96, 99].contains(code)) return 'THUNDERSTORM SKY';
    if (const [30, 31, 32, 33, 34, 35].contains(code) && _worldLocation.isArid)
      return 'DUSTY DESERT';
    if ([71, 73, 75, 77, 85, 86].contains(code)) return 'SNOWY LANDSCAPE';
    if ([45, 48].contains(code)) return 'FOGGY LANDSCAPE';
    if (code == 3) return 'OVERCAST LANDSCAPE';
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99]
        .contains(code)) return 'RAINY LANDSCAPE';
    if (windKmh >= strongWindThresholdKmh) return 'WIND-SWEPT LANDSCAPE';
    if ([0, 1, 2].contains(code)) {
      return isDay ? 'SUNLIT LANDSCAPE' : 'MOONLIT LANDSCAPE';
    }
    return isDay ? 'LOCAL LANDSCAPE' : 'NIGHTFALL LANDSCAPE';
  }

  Widget _locationStrip(bool isDark, _WeatherMenuPalette palette) => InkWell(
        onTap: _chooseCity,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.surfaceAlt, palette.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: palette.edge, width: 1.4),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                  color: palette.backgroundTop.withOpacity(.65),
                  offset: Offset(0, 3),
                  blurRadius: 5),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: palette.highlight, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_city.toUpperCase(),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: palette.text)),
                    Text(_region,
                        style: TextStyle(color: palette.muted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: palette.highlight),
            ],
          ),
        ),
      );

  Widget _weatherStatusBanner(_WeatherMenuPalette palette) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: palette.surface.withOpacity(.94),
          border: Border.all(
            color: _error == null ? palette.edge : palette.danger,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              _error == null ? Icons.cloud_done_outlined : Icons.cloud_off,
              size: 16,
              color: _error == null ? palette.accent : palette.danger,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _error != null
                    ? 'OFFLINE · LAST UPDATED ${_formatUpdatedAt(_lastUpdated)}'
                    : '${_usingCachedWeather ? 'SAVED WEATHER' : 'LAST UPDATED'} · ${_formatUpdatedAt(_lastUpdated)}',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .35,
                ),
              ),
            ),
            if (_error != null || !_loading)
              TextButton.icon(
                onPressed: _loading ? null : _fetchWeather,
                icon: const Icon(Icons.refresh, size: 15),
                label: Text(_error == null ? 'UPDATE' : 'RETRY'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                ),
              ),
          ],
        ),
      );

  String _formatUpdatedAt(DateTime? time) {
    if (time == null) return 'TIME UNKNOWN';
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month} $hour:$minute $period';
  }

  Widget _hudTag(String text, IconData icon, _WeatherMenuPalette palette) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: palette.backgroundTop.withOpacity(.92),
          border: Border.all(color: palette.edge),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.highlight, size: 13),
            const SizedBox(width: 5),
            Text(text,
                style: TextStyle(
                    color: palette.text,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6)),
          ],
        ),
      );

  Widget _pixelPanel({
    required Widget child,
    required bool isDark,
    Color borderColor = const Color(0xFF9A7147),
    bool parchmentPage = false,
  }) {
    final palette = _menuPalette(isDark);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: parchmentPage
              ? [palette.paper, palette.surfaceAlt]
              : [palette.surfaceAlt, palette.surface],
        ),
        border: Border.all(
            color: parchmentPage ? palette.edge : borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: palette.backgroundTop.withOpacity(.72),
            blurRadius: 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    final palette = _menuPalette(isDark);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 11, 7, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.surfaceAlt, palette.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: palette.edge),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
              color: palette.backgroundTop.withOpacity(.60),
              offset: Offset(0, 3),
              blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: palette.accent, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: palette.text)),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: palette.muted,
                  fontSize: 8,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _alertPanel({
    required int code,
    required int rainProbability,
    required bool isDark,
  }) {
    final palette = _menuPalette(isDark);
    final storm = [95, 96, 99].contains(code);
    final rainy = [51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code);
    final title = storm
        ? 'THUNDERSTORM CONDITIONS'
        : rainy
            ? 'RAIN IN THE REGION'
            : 'WEATHER QUEST';
    final message = storm
        ? 'Thunderstorm indicated by the forecast. Check official local alerts.'
        : rainy
            ? 'Rain is in the forecast. Keep your travel plans flexible.'
            : 'Clear skies ahead. Your next adventure awaits.';
    final color = storm ? palette.danger : palette.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.surfaceAlt, palette.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
              color: palette.backgroundTop.withOpacity(.64),
              offset: Offset(0, 3),
              blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Icon(
              storm
                  ? Icons.warning_amber_rounded
                  : rainy
                      ? Icons.umbrella
                      : Icons.auto_awesome,
              color: color,
              size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    )),
                const SizedBox(height: 4),
                Text(message,
                    style: TextStyle(
                        fontSize: 11, color: palette.muted, height: 1.3)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: palette.highlight),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    final palette =
        _menuPalette(Theme.of(context).brightness == Brightness.dark);
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: palette.text,
              )),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 30),
          ),
          child: Text(action,
              style: TextStyle(
                  color: palette.frameBottom,
                  fontSize: 10,
                  fontWeight: FontWeight.w900)),
        ),
        Icon(Icons.chevron_right, color: palette.highlight, size: 18),
      ],
    );
  }

  Widget _hourlyStrip(WeatherBundle w, bool isDark, {int count = 24}) {
    final palette = _menuPalette(isDark);
    final times = w.hourly['time'] as List<dynamic>;
    final temps = w.hourly['temperature_2m'] as List<dynamic>;
    final probs = w.hourly['precipitation_probability'] as List<dynamic>;
    final codes = w.hourly['weather_code'] as List<dynamic>;
    final start = _firstFutureHour(times);
    final end = math.min(start + count, times.length);
    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: end - start,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, offset) {
          final i = start + offset;
          final date = DateTime.tryParse(times[i].toString());
          return Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.surfaceAlt, palette.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: offset == 0 ? palette.accent : palette.edge,
                  width: offset == 0 ? 1.5 : 1),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                    color: palette.backgroundTop.withOpacity(.45),
                    offset: Offset(0, 2),
                    blurRadius: 4),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(offset == 0 ? 'NOW' : _hourLabel(date),
                    style: TextStyle(
                        color: palette.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
                Text(weatherEmoji((codes[i] as num).toInt(), true),
                    style: const TextStyle(fontSize: 23)),
                Text('${_temp(temps[i])}$_unit',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop, size: 10, color: palette.accent),
                    Text('${probs[i]}%',
                        style: TextStyle(color: palette.accent, fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _weeklyCompact(WeatherBundle w, bool isDark) {
    final palette = _menuPalette(isDark);
    final d = w.daily;
    final dates = d['time'] as List<dynamic>;
    final codes = d['weather_code'] as List<dynamic>;
    final highs = d['temperature_2m_max'] as List<dynamic>;
    final lows = d['temperature_2m_min'] as List<dynamic>;
    final rain = d['precipitation_probability_max'] as List<dynamic>;
    return _pixelPanel(
      isDark: isDark,
      child: Column(
        children: List.generate(dates.length, (i) {
          final date = DateTime.tryParse(dates[i].toString());
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 45,
                  child: Text(i == 0 ? 'Today' : _weekday(date),
                      style: TextStyle(color: palette.muted, fontSize: 11)),
                ),
                const SizedBox(width: 5),
                Text(weatherEmoji((codes[i] as num).toInt(), true),
                    style: const TextStyle(fontSize: 21)),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.water_drop, color: palette.accent, size: 11),
                      Text('${rain[i]}%',
                          style:
                              TextStyle(color: palette.accent, fontSize: 10)),
                    ],
                  ),
                ),
                Text('${_temp(lows[i])}°',
                    style: TextStyle(color: palette.muted, fontSize: 12)),
                const SizedBox(width: 13),
                SizedBox(
                  width: 34,
                  child: Text('${_temp(highs[i])}°',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _hourlyScreen(WeatherBundle w, bool isDark) {
    final palette = _menuPalette(isDark);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
      children: [
        _screenTitle('HOURLY FORECAST', 'Your next 24 hours'),
        const SizedBox(height: 16),
        _hourlyStrip(w, isDark, count: 24),
        const SizedBox(height: 18),
        _pixelPanel(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RAIN CHANCE BY HOUR',
                  style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12)),
              const SizedBox(height: 15),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: RainChartPainter(
                    values: (w.hourly['precipitation_probability']
                            as List<dynamic>)
                        .skip(
                            _firstFutureHour(w.hourly['time'] as List<dynamic>))
                        .take(12)
                        .map((v) => (v as num).toDouble())
                        .toList(),
                    color: palette.accent,
                    grid: palette.grid,
                    pointCenter: palette.frameBottom,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 10),
              Text('Probability of precipitation (%)',
                  style: TextStyle(color: palette.muted, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _sectionHeader('NEXT 24 HOURS', 'REFRESH', _fetchWeather),
        const SizedBox(height: 8),
        _hourlyStrip(w, isDark, count: 24),
      ],
    );
  }

  Widget _weeklyScreen(WeatherBundle w, bool isDark) {
    final palette = _menuPalette(isDark);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
      children: [
        _screenTitle(
            'DAILY FORECAST', 'The next ${w.daily['time'].length} days'),
        const SizedBox(height: 16),
        _weeklyCompact(w, isDark),
        const SizedBox(height: 16),
        _pixelPanel(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DAILY TEMPERATURE RANGE',
                  style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12)),
              const SizedBox(height: 12),
              ...List.generate((w.daily['time'] as List).length, (i) {
                final low =
                    (w.daily['temperature_2m_min'][i] as num).toDouble();
                final high =
                    (w.daily['temperature_2m_max'][i] as num).toDouble();
                final minAll = (w.daily['temperature_2m_min'] as List)
                    .map((v) => (v as num).toDouble())
                    .reduce(math.min);
                final maxAll = (w.daily['temperature_2m_max'] as List)
                    .map((v) => (v as num).toDouble())
                    .reduce(math.max);
                final range =
                    (maxAll - minAll).abs() < 0.1 ? 1.0 : maxAll - minAll;
                final left =
                    ((low - minAll) / range).clamp(0.0, 1.0).toDouble();
                final width =
                    ((high - low) / range).clamp(0.03, 1.0).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          i == 0
                              ? 'Today'
                              : _weekday(DateTime.tryParse(w.daily['time'][i])),
                          style: TextStyle(color: palette.muted, fontSize: 10),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 13,
                          child: LayoutBuilder(
                            builder: (context, constraints) => Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: palette.grid,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Positioned(
                                  left: constraints.maxWidth * left,
                                  width: math.max(
                                      6.0, constraints.maxWidth * width),
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          palette.accent,
                                          palette.highlight
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: Text('${_temp(low)}° / ${_temp(high)}°',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSelectedPlace(SavedPlace place) {
    final sameName = place.city == _city;
    if (place.latitude != 0 || place.longitude != 0) {
      return sameName &&
          (place.latitude - _lat).abs() < .01 &&
          (place.longitude - _lon).abs() < .01;
    }
    return sameName && place.region == _region;
  }

  Future<void> _selectPlace(SavedPlace place) async {
    if (_isSelectedPlace(place)) return;
    final hasCoordinates = place.latitude != 0 || place.longitude != 0;
    setState(() {
      _city = place.city;
      _region = place.region;
      _lat = place.latitude;
      _lon = place.longitude;
      _tab = 0;
      _weather = null;
      _loading = true;
      _lastUpdated = null;
      _usingCachedWeather = false;
      _sceneWeatherPreviousKey = '';
    });
    await _savePreferences();
    // A place saved before coordinates were stored has nothing usable to query,
    // so resolve it through the geocoder once and keep the result.
    if (!hasCoordinates) {
      final result = await _geocode(
          place.subtitle.isEmpty ? place.city : '${place.city}, ${place.region}');
      if (!mounted || result == null) return;
      setState(() {
        _city = result.city;
        _region = result.region;
        _lat = result.latitude;
        _lon = result.longitude;
        _rememberPlace(SavedPlace(
          city: result.city,
          region: result.region,
          latitude: result.latitude,
          longitude: result.longitude,
        ));
      });
      await _savePreferences();
    }
    await _fetchWeather();
  }

  Widget _placesScreen(bool isDark) {
    final palette = _menuPalette(isDark);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
      children: [
        _screenTitle('YOUR PLACES', 'Choose a weather world'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _chooseCity,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('ADD A LOCATION'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _gettingLocation ? null : _useMyLocation,
          icon: _gettingLocation
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label:
              Text(_gettingLocation ? 'FINDING LOCATION…' : 'USE MY LOCATION'),
        ),
        const SizedBox(height: 12),
        if (_savedPlaces.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Text(
              'No saved places yet. Add one above to keep it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          )
        else
          ..._savedPlaces.map((place) {
            final selected = _isSelectedPlace(place);
            final subtitle = place.subtitle;
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _pixelPanel(
                isDark: isDark,
                borderColor: selected ? palette.accent : palette.edge,
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.my_location : Icons.location_on,
                      color: palette.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectPlace(place),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.displayName.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            if (subtitle.isNotEmpty)
                              Text(subtitle,
                                  style: TextStyle(
                                      color: palette.muted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Nickname',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _renamePlace(place),
                      icon: Icon(Icons.edit_outlined,
                          size: 19, color: palette.muted),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _removePlace(place),
                      icon: Icon(Icons.delete_outline,
                          size: 19, color: palette.muted),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        Text(
          "Your places stay on this device. Location access is used only when you tap 'Use my location'.",
          style: TextStyle(color: palette.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _journalScreen(bool isDark) {
    final palette = _menuPalette(isDark);
    final profile = _characterProfile;
    final progress = profile.progress;
    final collectedLandmarks = progress.landmarkIds.length;
    final collectedWeather = progress.weatherKeys.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
      children: [
        _screenTitle('GOBLIN JOURNAL', 'A little weather, a lot of memories'),
        const SizedBox(height: 14),
        if (!progress.hasAnyProgress) ...[
          _pixelPanel(
            isDark: isDark,
            borderColor: palette.edge,
            child: Text(
              'The journal is empty. Visit a place and explore its weather to '
              'start the goblin’s collection.',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _pixelPanel(
          isDark: isDark,
          borderColor: palette.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COLLECTION',
                  style: TextStyle(
                      color: palette.highlight,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .9)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _progressStat(
                      palette: palette,
                      label: 'LANDMARKS',
                      collected: collectedLandmarks,
                      total: landmarkCatalog.length,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _progressStat(
                      palette: palette,
                      label: 'WEATHER',
                      collected: collectedWeather,
                      total: weatherBadgeCatalog.length,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _progressStat(
                      palette: palette,
                      label: 'WORLDS',
                      collected: progress.locationsVisited,
                      total: worldLocations.length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${progress.totalVisits} total '
                '${progress.totalVisits == 1 ? "visit" : "visits"}',
                style: TextStyle(color: palette.muted, fontSize: 11),
              ),
              if (progress.favouriteLocationId != null)
                Text(
                  'Most revisited: ${_worldNameFor(progress.favouriteLocationId!)}',
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final badge in weatherBadgeCatalog)
                    _badgeChip(
                      palette: palette,
                      emoji: badge.emoji,
                      label: badge.name,
                      unlocked: progress.weatherKeys.contains(badge.key),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _pixelPanel(
          isDark: isDark,
          borderColor: palette.edge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'LANDMARKS  ·  $collectedLandmarks/${landmarkCatalog.length}',
                  style: TextStyle(
                      color: palette.highlight,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in landmarkCatalog)
                    _landmarkTile(
                      palette: palette,
                      emoji: entry.emoji,
                      name: entry.name,
                      visited: progress.landmarkIds.contains(entry.landmark.name),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _pixelPanel(
          isDark: isDark,
          borderColor: palette.edge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RECENT MEMORIES  ·  ${profile.recentEvents.length}',
                  style: TextStyle(
                      color: palette.highlight,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8)),
              const SizedBox(height: 8),
              if (profile.recentEvents.isEmpty)
                Text('Nothing remembered yet.',
                    style: TextStyle(color: palette.muted, fontSize: 12)),
              ...profile.recentEvents.take(24).map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: palette.accent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              Text(event.detail,
                                  style: TextStyle(
                                      color: palette.muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text('${event.at.day}/${event.at.month}',
                            style:
                                TextStyle(color: palette.muted, fontSize: 10)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  String _worldNameFor(String locationId) {
    for (final location in worldLocations) {
      if (location.id == locationId) return location.name;
    }
    // Regional fallbacks use ids like `regional-desert`.
    final words = locationId.replaceAll('-', ' ');
    if (words.isEmpty) return locationId;
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  Widget _progressStat({
    required _WeatherMenuPalette palette,
    required String label,
    required int collected,
    required int total,
  }) {
    final complete = total > 0 && collected >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$collected/$total',
            style: TextStyle(
                color: complete ? palette.accent : palette.highlight,
                fontSize: 17,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: TextStyle(
                color: palette.muted, fontSize: 9, letterSpacing: .8)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : (collected / total).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: palette.edge.withValues(alpha: .35),
            valueColor: AlwaysStoppedAnimation<Color>(
                complete ? palette.accent : palette.highlight),
          ),
        ),
      ],
    );
  }

  Widget _landmarkTile({
    required _WeatherMenuPalette palette,
    required String emoji,
    required String name,
    required bool visited,
  }) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: visited
            ? palette.surfaceAlt
            : palette.surface.withValues(alpha: .45),
        border: Border.all(
          color: visited ? palette.accent : palette.edge.withValues(alpha: .5),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(visited ? emoji : '🔒', style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 3),
          Text(
            visited ? name : '???',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: visited ? palette.text : palette.muted,
              fontSize: 9,
              height: 1.15,
              fontWeight: visited ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeChip({
    required _WeatherMenuPalette palette,
    required String emoji,
    required String label,
    required bool unlocked,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: unlocked
            ? palette.surfaceAlt
            : palette.surface.withValues(alpha: .40),
        border: Border.all(
          color: unlocked ? palette.accent : palette.edge.withValues(alpha: .5),
          width: 1.1,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(unlocked ? emoji : '🔒', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            unlocked ? label : 'Locked',
            style: TextStyle(
              color: unlocked ? palette.text : palette.muted,
              fontSize: 10,
              fontWeight: unlocked ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenTitle(String title, String subtitle) {
    final palette =
        _menuPalette(Theme.of(context).brightness == Brightness.dark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: palette.text)),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(color: palette.muted, fontSize: 12)),
      ],
    );
  }

  Widget _bottomNav(bool isDark, _WeatherMenuPalette palette) {
    const items = [
      (Icons.home_rounded, 'Today'),
      (Icons.schedule_rounded, 'Hourly'),
      (Icons.calendar_month_rounded, 'Forecast'),
      (Icons.place_rounded, 'Places'),
      (Icons.menu_book_rounded, 'Journal'),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.frameBottom, palette.backgroundBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(color: palette.edge, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
              color: palette.backgroundTop.withOpacity(.68),
              offset: Offset(0, -3),
              blurRadius: 7),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = _tab == i;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.fromLTRB(4, 7, 4, 7),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? palette.surfaceAlt : Colors.transparent,
                    border: Border.all(
                      color: active ? palette.highlight : Colors.transparent,
                      width: 1.3,
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: palette.highlight.withOpacity(.18),
                                blurRadius: 9)
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1,
                          color: active ? palette.highlight : palette.muted,
                          size: 22),
                      const SizedBox(height: 3),
                      Text(items[i].$2,
                          style: TextStyle(
                            color: active ? palette.highlight : palette.muted,
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w900 : FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  int _temp(dynamic value) {
    final c = (value as num).toDouble();
    return (_fahrenheit ? c * 9 / 5 + 32 : c).round();
  }

  String _number(dynamic value) =>
      value is num ? value.toStringAsFixed(value.abs() < 10 ? 1 : 0) : '—';

  int _currentRainProbability(WeatherBundle w) {
    final times = w.hourly['time'] as List<dynamic>;
    final probs = w.hourly['precipitation_probability'] as List<dynamic>;
    final i = _firstFutureHour(times);
    if (i >= probs.length) return 0;
    return (probs[i] as num?)?.toInt() ?? 0;
  }

  int _firstFutureHour(List<dynamic> times) {
    final now = DateTime.now();
    final index = times.indexWhere((v) {
      final time = DateTime.tryParse(v.toString());
      return time != null &&
          !time.isBefore(now.subtract(const Duration(hours: 1)));
    });
    return index < 0 ? 0 : index;
  }

  String _hourLabel(DateTime? time) {
    if (time == null) return '--';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour${time.hour >= 12 ? 'p' : 'a'}';
  }

  String _weekday(DateTime? date) {
    if (date == null) return '--';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class _ForestBackdropPainter extends CustomPainter {
  const _ForestBackdropPainter({required this.palette});
  final _WeatherMenuPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.backgroundTop,
            palette.backgroundBottom,
            palette.backgroundTop,
          ],
        ).createShader(rect),
    );

    final motifPaint = Paint()
      ..color = palette.accent.withOpacity(.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    if (palette.mood == 'heat' || palette.mood == 'sandstorm') {
      for (var i = 0; i < 5; i++) {
        final y = size.height * (.28 + i * .13);
        final dune = Path()
          ..moveTo(0, y + 28)
          ..quadraticBezierTo(size.width * .27, y - 22, size.width * .52,
              y + (i.isEven ? 18 : -8))
          ..quadraticBezierTo(size.width * .78, y + 43, size.width, y - 12);
        canvas.drawPath(dune, motifPaint);
      }
      return;
    }
    if (palette.mood == 'flood' || palette.mood == 'rain') {
      for (var i = 0; i < 15; i++) {
        final y = size.height * (.17 + (i * 29 % 75) / 100);
        final x = size.width * ((i * 47 % 100) / 100);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), width: 22 + (i % 4) * 8, height: 4),
          motifPaint,
        );
      }
      return;
    }
    if (palette.mood == 'cold') {
      final frostPaint = Paint()
        ..color = palette.highlight.withOpacity(.10)
        ..strokeWidth = 1;
      for (var i = 0; i < 12; i++) {
        final x = size.width * ((i * 37 % 100) / 100);
        final y = size.height * (.16 + (i * 23 % 72) / 100);
        canvas.drawLine(Offset(x, y), Offset(x + 18, y - 18), frostPaint);
        canvas.drawLine(
            Offset(x + 7, y - 7), Offset(x - 3, y - 15), frostPaint);
        canvas.drawLine(
            Offset(x + 11, y - 11), Offset(x + 21, y - 5), frostPaint);
      }
      return;
    }
    if (palette.mood == 'storm' || palette.mood == 'wind') {
      for (var i = 0; i < 11; i++) {
        final y = size.height * (.16 + (i * 31 % 76) / 100);
        final x = size.width * ((i * 41 % 100) / 100);
        final gust = Path()
          ..moveTo(x, y)
          ..cubicTo(x + 22, y - 7, x + 42, y + 7, x + 64, y);
        canvas.drawPath(gust, motifPaint);
      }
      return;
    }

    final barkColor = palette.frameBottom.withOpacity(.18);
    final branchPaint = Paint()
      ..color = barkColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final leftBranch = Path()
      ..moveTo(-size.width * .04, size.height * .61)
      ..cubicTo(size.width * .11, size.height * .55, size.width * .02,
          size.height * .46, size.width * .12, size.height * .39)
      ..cubicTo(size.width * .17, size.height * .35, size.width * .10,
          size.height * .30, size.width * .17, size.height * .25);
    final rightBranch = Path()
      ..moveTo(size.width * 1.04, size.height * .83)
      ..cubicTo(size.width * .91, size.height * .76, size.width * .99,
          size.height * .67, size.width * .89, size.height * .59)
      ..cubicTo(size.width * .84, size.height * .55, size.width * .94,
          size.height * .48, size.width * .88, size.height * .43);
    canvas.drawPath(leftBranch, branchPaint);
    canvas.drawPath(rightBranch, branchPaint);

    final leafColor = palette.botanical.withOpacity(.20);
    for (var i = 0; i < 18; i++) {
      final left = i.isEven;
      final x =
          size.width * (left ? .035 + (i % 4) * .022 : .965 - (i % 4) * .022);
      final y = size.height * (.18 + (i * 37 % 74) / 100);
      final leaf = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
            x + (left ? 15 : -15), y - 11, x + (left ? 23 : -23), y + 2)
        ..quadraticBezierTo(x + (left ? 12 : -12), y + 9, x, y)
        ..close();
      canvas.drawPath(leaf, Paint()..color = leafColor);
      canvas.drawLine(
          Offset(x, y),
          Offset(x + (left ? 17 : -17), y + 1),
          Paint()
            ..color = barkColor
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant _ForestBackdropPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class _MenuParticlePainter extends CustomPainter {
  _MenuParticlePainter({
    required this.animation,
    required this.environment,
    required this.aridRegion,
    required this.seasonalFoliage,
    required this.latitude,
    required this.weatherCode,
    required this.precipitationMm,
    required this.temperatureC,
    required this.month,
    required this.isDay,
    required this.palette,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final SceneEnvironment environment;
  final bool aridRegion;
  final bool seasonalFoliage;
  final double latitude;
  final int weatherCode;
  final double precipitationMm;
  final double temperatureC;
  final int month;
  final bool isDay;
  final _WeatherMenuPalette palette;

  bool get _snow => const [71, 73, 75, 77, 85, 86].contains(weatherCode);
  bool get _rain => const [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82]
      .contains(weatherCode);
  bool get _storm => const [95, 96, 99].contains(weatherCode);
  bool get _dust =>
      aridRegion && const [30, 31, 32, 33, 34, 35].contains(weatherCode);
  WorldSeason get _season => worldSeasonForMonth(month, latitude);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final phase = animation.value;
    if (_dust || environment == SceneEnvironment.sandstorm) {
      _drawSand(canvas, size, phase);
    } else if (environment == SceneEnvironment.cyclone) {
      _drawCyclone(canvas, size, phase);
    } else if (environment == SceneEnvironment.flood) {
      _drawBubbles(canvas, size, phase);
    } else if (environment == SceneEnvironment.desertHeat) {
      _drawEmbers(canvas, size, phase);
    } else if (_snow) {
      _drawSnow(canvas, size, phase);
    } else if (_rain || _storm) {
      _drawRain(canvas, size, phase, _storm, precipitationMm);
    } else if (seasonalFoliage && _season == WorldSeason.spring) {
      _drawPetals(canvas, size, phase);
    } else if (seasonalFoliage && _season == WorldSeason.autumn) {
      _drawLeaves(canvas, size, phase);
    } else if (aridRegion && temperatureC >= strongHeatThresholdC && isDay) {
      _drawEmbers(canvas, size, phase);
    } else {
      _drawFireflies(canvas, size, phase);
    }
  }

  double _seed(int i, int salt) => ((i * 47 + salt * 29) % 101) / 101;

  void _drawSnow(Canvas canvas, Size size, double phase) {
    for (var i = 0; i < 30; i++) {
      final t = (phase + _seed(i, 2)) % 1;
      final x = size.width * ((_seed(i, 7) + .045 * math.sin(t * 6 + i)) % 1);
      final y = size.height * t;
      final radius = 1.1 + (i % 3) * .45;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = palette.highlight.withOpacity(.62),
      );
    }
  }

  void _drawRain(Canvas canvas, Size size, double phase, bool storm,
      double precipitation) {
    final density = storm
        ? 48
        : precipitation <= 0
            ? 14
            : (14 + precipitation * 5).round().clamp(14, 42);
    final paint = Paint()
      ..color = palette.accent.withOpacity(.34)
      ..strokeWidth = storm
          ? 1.3
          : density > 26
              ? 1.2
              : 1;
    for (var i = 0; i < density; i++) {
      final t = (phase * (storm ? 1.5 : 1) + _seed(i, 4)) % 1;
      final x = size.width * _seed(i, 9);
      final y = size.height * t;
      final slant = storm ? size.width * .025 : size.width * .008;
      canvas.drawLine(
          Offset(x, y), Offset(x - slant, y + size.height * .014), paint);
    }
  }

  void _drawCyclone(Canvas canvas, Size size, double phase) {
    final center = Offset(size.width * .50, size.height * .57);
    final paint = Paint()
      ..color = palette.accent.withOpacity(.34)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final angle = phase * math.pi * 2 + i * .61;
      final radius = .10 + (i % 7) * .027;
      final x = center.dx + math.cos(angle) * size.width * radius;
      final y = center.dy + math.sin(angle) * size.height * radius * .62;
      final tail = Offset(x - math.sin(angle) * size.width * .013,
          y + math.cos(angle) * size.height * .017);
      canvas.drawLine(Offset(x, y), tail, paint);
    }
  }

  void _drawSand(Canvas canvas, Size size, double phase) {
    final paint = Paint()
      ..color = palette.highlight.withOpacity(.40)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 34; i++) {
      final x = size.width * ((_seed(i, 3) + phase * .78) % 1);
      final y = size.height * ((_seed(i, 8) + phase * .18) % 1);
      final length = size.width * (.008 + (i % 4) * .003);
      canvas.drawLine(
          Offset(x, y), Offset(x + length, y - length * .15), paint);
    }
  }

  void _drawBubbles(Canvas canvas, Size size, double phase) {
    for (var i = 0; i < 18; i++) {
      final t = (phase * .35 + _seed(i, 5)) % 1;
      final x = size.width * (.08 + _seed(i, 9) * .84) +
          math.sin(t * math.pi * 2 + i) * size.width * .012;
      final y = size.height * (1 - t);
      final r = 1.4 + (i % 3) * .7;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = palette.accent.withOpacity(.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawEmbers(Canvas canvas, Size size, double phase) {
    for (var i = 0; i < 24; i++) {
      final t = (phase + _seed(i, 6)) % 1;
      final x =
          size.width * _seed(i, 10) + math.sin(t * 5 + i) * size.width * .012;
      final y = size.height * (1 - t);
      final alpha = 35 + (i % 4) * 12;
      canvas.drawCircle(
        Offset(x, y),
        1 + (i % 2) * .5,
        Paint()
          ..color = Color.lerp(palette.accent, palette.highlight, .65)!
              .withOpacity(alpha / 255),
      );
    }
  }

  void _drawPetals(Canvas canvas, Size size, double phase) {
    for (var i = 0; i < 20; i++) {
      final t = (phase + _seed(i, 1)) % 1;
      final x =
          size.width * _seed(i, 4) + math.sin(t * 5 + i) * size.width * .025;
      final y = size.height * t;
      final paint = Paint()
        ..color = i.isEven
            ? palette.highlight.withOpacity(.46)
            : palette.accent.withOpacity(.40);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(t * 6 + i) * .7);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 5, height: 3), paint);
      canvas.restore();
    }
  }

  void _drawLeaves(Canvas canvas, Size size, double phase) {
    for (var i = 0; i < 18; i++) {
      final t = (phase * .72 + _seed(i, 4)) % 1;
      final x =
          size.width * _seed(i, 8) + math.sin(t * 5 + i) * size.width * .035;
      final y = size.height * t;
      final paint = Paint()
        ..color = i.isEven
            ? palette.accent.withOpacity(.54)
            : palette.highlight.withOpacity(.54);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(t * 7 + i) * 1.1);
      final leaf = Path()
        ..moveTo(-3, 0)
        ..quadraticBezierTo(0, -4, 4, -1)
        ..quadraticBezierTo(1, 4, -3, 0)
        ..close();
      canvas.drawPath(leaf, paint);
      canvas.restore();
    }
  }

  void _drawFireflies(Canvas canvas, Size size, double phase) {
    for (var i = 0; i < 18; i++) {
      final pulse =
          (.25 + .75 * math.sin((phase + _seed(i, 5)) * math.pi * 2).abs())
              .clamp(0.0, 1.0);
      final x = size.width * _seed(i, 2);
      final y = size.height * (.16 + _seed(i, 6) * .76);
      final color = palette.highlight.withOpacity(pulse * .4);
      canvas.drawCircle(
          Offset(x, y), 3.3, Paint()..color = color.withOpacity(.22));
      canvas.drawCircle(Offset(x, y), 1.1, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _MenuParticlePainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.environment != environment ||
      oldDelegate.aridRegion != aridRegion ||
      oldDelegate.seasonalFoliage != seasonalFoliage ||
      oldDelegate.latitude != latitude ||
      oldDelegate.weatherCode != weatherCode ||
      oldDelegate.precipitationMm != precipitationMm ||
      oldDelegate.temperatureC != temperatureC ||
      oldDelegate.month != month ||
      oldDelegate.isDay != isDay ||
      oldDelegate.palette != palette;
}

class _SceneFrameEtchingPainter extends CustomPainter {
  const _SceneFrameEtchingPainter({required this.palette});
  final _WeatherMenuPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final screwPaint = Paint()
      ..color = palette.edge.withOpacity(.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final screwFill = Paint()..color = palette.frameBottom.withOpacity(.8);
    for (final point in [
      const Offset(9, 9),
      Offset(size.width - 9, 9),
      Offset(9, size.height - 9),
      Offset(size.width - 9, size.height - 9),
    ]) {
      canvas.drawCircle(point, 3.2, screwFill);
      canvas.drawCircle(point, 3.2, screwPaint);
      canvas.drawLine(point + const Offset(-1.3, 0),
          point + const Offset(1.3, 0), screwPaint..strokeWidth = .8);
    }
    final etch = Paint()
      ..color = palette.accent.withOpacity(.30)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(4, size.height * .32), Offset(8, size.height * .37), etch);
    canvas.drawLine(Offset(size.width - 4, size.height * .63),
        Offset(size.width - 8, size.height * .68), etch);
  }

  @override
  bool shouldRepaint(covariant _SceneFrameEtchingPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class RainChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color grid;
  final Color pointCenter;
  RainChartPainter(
      {required this.values,
      required this.color,
      required this.grid,
      required this.pointCenter});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.isEmpty) return;
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final y = size.height - (values[i].clamp(0, 100) / 100) * size.height;
      points.add(Offset(x, y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(.30), color.withOpacity(.01)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in points) {
      canvas.drawCircle(p, 3.5, Paint()..color = color);
      canvas.drawCircle(p, 1.5, Paint()..color = pointCenter);
    }
  }

  @override
  bool shouldRepaint(covariant RainChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
