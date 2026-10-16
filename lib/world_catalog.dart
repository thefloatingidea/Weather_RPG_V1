import 'dart:convert';

enum WorldBiome {
  tropical,
  coastal,
  river,
  urban,
  temperate,
  desert,
  mountain,
  coldDesert,
}

enum WorldSeason { spring, summer, autumn, winter }

WorldSeason worldSeasonForMonth(int month, double latitude) {
  final normalizedMonth = (month - 1) % 12 + 1;
  final seasonalMonth =
      ((normalizedMonth - 1 + (latitude < 0 ? 6 : 0)) % 12) + 1;
  if (seasonalMonth >= 3 && seasonalMonth <= 5) return WorldSeason.spring;
  if (seasonalMonth >= 6 && seasonalMonth <= 8) return WorldSeason.summer;
  if (seasonalMonth >= 9 && seasonalMonth <= 11) return WorldSeason.autumn;
  return WorldSeason.winter;
}

enum WorldLandmark {
  none,
  tajMahal,
  hawaMahal,
  indiaGate,
  gatewayOfIndia,
  howrahBridge,
  varanasiGhats,
  goldenTemple,
  charminar,
  chennaiLighthouse,
  bengaluruPalace,
  kochiFishingNets,
  srinagarLake,
  shimlaHills,
  lehMonastery,
  jaisalmerFort,
  rishikeshBridge,
  bhopalLake,
  eiffelTower,
  bigBen,
  newYorkSkyline,
  tokyoFuji,
  colosseum,
  cairoPyramids,
  sydneyOperaHouse,
  rioMountain,
  dubaiTower,
  singaporeSkyline,
}

class WorldLocation {
  const WorldLocation({
    required this.id,
    required this.name,
    required this.aliases,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.biome,
    required this.landmark,
    this.seasonalFoliage = false,
  });

  final String id;
  final String name;
  final List<String> aliases;
  final String country;
  final double latitude;
  final double longitude;
  final WorldBiome biome;
  final WorldLandmark landmark;
  final bool seasonalFoliage;

  bool get isTropical => biome == WorldBiome.tropical;
  bool get isArid =>
      biome == WorldBiome.desert || biome == WorldBiome.coldDesert;
}

const worldLocations = <WorldLocation>[
  WorldLocation(
      id: 'agra',
      name: 'Agra',
      aliases: ['agra'],
      country: 'India',
      latitude: 27.1767,
      longitude: 78.0081,
      biome: WorldBiome.urban,
      landmark: WorldLandmark.tajMahal),
  WorldLocation(
      id: 'jaipur',
      name: 'Jaipur',
      aliases: ['jaipur'],
      country: 'India',
      latitude: 26.9124,
      longitude: 75.7873,
      biome: WorldBiome.desert,
      landmark: WorldLandmark.hawaMahal),
  WorldLocation(
      id: 'delhi',
      name: 'Delhi',
      aliases: ['delhi', 'new delhi'],
      country: 'India',
      latitude: 28.6139,
      longitude: 77.2090,
      biome: WorldBiome.urban,
      landmark: WorldLandmark.indiaGate),
  WorldLocation(
      id: 'mumbai',
      name: 'Mumbai',
      aliases: ['mumbai', 'bombay'],
      country: 'India',
      latitude: 19.0760,
      longitude: 72.8777,
      biome: WorldBiome.coastal,
      landmark: WorldLandmark.gatewayOfIndia),
  WorldLocation(
      id: 'kolkata',
      name: 'Kolkata',
      aliases: ['kolkata', 'calcutta'],
      country: 'India',
      latitude: 22.5726,
      longitude: 88.3639,
      biome: WorldBiome.river,
      landmark: WorldLandmark.howrahBridge),
  WorldLocation(
      id: 'varanasi',
      name: 'Varanasi',
      aliases: ['varanasi', 'banaras', 'benares'],
      country: 'India',
      latitude: 25.3176,
      longitude: 82.9739,
      biome: WorldBiome.river,
      landmark: WorldLandmark.varanasiGhats),
  WorldLocation(
      id: 'amritsar',
      name: 'Amritsar',
      aliases: ['amritsar'],
      country: 'India',
      latitude: 31.6340,
      longitude: 74.8723,
      biome: WorldBiome.urban,
      landmark: WorldLandmark.goldenTemple),
  WorldLocation(
      id: 'hyderabad',
      name: 'Hyderabad',
      aliases: ['hyderabad'],
      country: 'India',
      latitude: 17.3850,
      longitude: 78.4867,
      biome: WorldBiome.urban,
      landmark: WorldLandmark.charminar),
  WorldLocation(
      id: 'chennai',
      name: 'Chennai',
      aliases: ['chennai', 'madras'],
      country: 'India',
      latitude: 13.0827,
      longitude: 80.2707,
      biome: WorldBiome.coastal,
      landmark: WorldLandmark.chennaiLighthouse),
  WorldLocation(
      id: 'bengaluru',
      name: 'Bengaluru',
      aliases: ['bengaluru', 'bangalore'],
      country: 'India',
      latitude: 12.9716,
      longitude: 77.5946,
      biome: WorldBiome.tropical,
      landmark: WorldLandmark.bengaluruPalace),
  WorldLocation(
      id: 'kochi',
      name: 'Kochi',
      aliases: ['kochi', 'cochin'],
      country: 'India',
      latitude: 9.9312,
      longitude: 76.2673,
      biome: WorldBiome.coastal,
      landmark: WorldLandmark.kochiFishingNets),
  WorldLocation(
      id: 'srinagar',
      name: 'Srinagar',
      aliases: ['srinagar'],
      country: 'India',
      latitude: 34.0837,
      longitude: 74.7973,
      biome: WorldBiome.mountain,
      landmark: WorldLandmark.srinagarLake,
      seasonalFoliage: true),
  WorldLocation(
      id: 'shimla',
      name: 'Shimla',
      aliases: ['shimla'],
      country: 'India',
      latitude: 31.1048,
      longitude: 77.1734,
      biome: WorldBiome.mountain,
      landmark: WorldLandmark.shimlaHills,
      seasonalFoliage: true),
  WorldLocation(
      id: 'leh',
      name: 'Leh',
      aliases: ['leh'],
      country: 'India',
      latitude: 34.1526,
      longitude: 77.5771,
      biome: WorldBiome.coldDesert,
      landmark: WorldLandmark.lehMonastery),
  WorldLocation(
      id: 'jaisalmer',
      name: 'Jaisalmer',
      aliases: ['jaisalmer'],
      country: 'India',
      latitude: 26.9157,
      longitude: 70.9083,
      biome: WorldBiome.desert,
      landmark: WorldLandmark.jaisalmerFort),
  WorldLocation(
      id: 'rishikesh',
      name: 'Rishikesh',
      aliases: ['rishikesh'],
      country: 'India',
      latitude: 30.0869,
      longitude: 78.2676,
      biome: WorldBiome.river,
      landmark: WorldLandmark.rishikeshBridge,
      seasonalFoliage: true),
  WorldLocation(
      id: 'bhopal',
      name: 'Bhopal',
      aliases: ['bhopal'],
      country: 'India',
      latitude: 23.2599,
      longitude: 77.4126,
      biome: WorldBiome.river,
      landmark: WorldLandmark.bhopalLake),
  WorldLocation(
      id: 'paris',
      name: 'Paris',
      aliases: ['paris'],
      country: 'France',
      latitude: 48.8566,
      longitude: 2.3522,
      biome: WorldBiome.river,
      landmark: WorldLandmark.eiffelTower,
      seasonalFoliage: true),
  WorldLocation(
      id: 'london',
      name: 'London',
      aliases: ['london'],
      country: 'United Kingdom',
      latitude: 51.5072,
      longitude: -0.1276,
      biome: WorldBiome.river,
      landmark: WorldLandmark.bigBen,
      seasonalFoliage: true),
  WorldLocation(
      id: 'new-york',
      name: 'New York',
      aliases: ['new york', 'new york city'],
      country: 'United States',
      latitude: 40.7128,
      longitude: -74.0060,
      biome: WorldBiome.coastal,
      landmark: WorldLandmark.newYorkSkyline,
      seasonalFoliage: true),
  WorldLocation(
      id: 'tokyo',
      name: 'Tokyo',
      aliases: ['tokyo'],
      country: 'Japan',
      latitude: 35.6762,
      longitude: 139.6503,
      biome: WorldBiome.urban,
      landmark: WorldLandmark.tokyoFuji),
  WorldLocation(
      id: 'rome',
      name: 'Rome',
      aliases: ['rome'],
      country: 'Italy',
      latitude: 41.9028,
      longitude: 12.4964,
      biome: WorldBiome.urban,
      landmark: WorldLandmark.colosseum,
      seasonalFoliage: true),
  WorldLocation(
      id: 'cairo',
      name: 'Cairo',
      aliases: ['cairo'],
      country: 'Egypt',
      latitude: 30.0444,
      longitude: 31.2357,
      biome: WorldBiome.desert,
      landmark: WorldLandmark.cairoPyramids),
  WorldLocation(
      id: 'sydney',
      name: 'Sydney',
      aliases: ['sydney'],
      country: 'Australia',
      latitude: -33.8688,
      longitude: 151.2093,
      biome: WorldBiome.coastal,
      landmark: WorldLandmark.sydneyOperaHouse,
      seasonalFoliage: true),
  WorldLocation(
      id: 'rio',
      name: 'Rio de Janeiro',
      aliases: ['rio de janeiro', 'rio'],
      country: 'Brazil',
      latitude: -22.9068,
      longitude: -43.1729,
      biome: WorldBiome.coastal,
      landmark: WorldLandmark.rioMountain),
  WorldLocation(
      id: 'dubai',
      name: 'Dubai',
      aliases: ['dubai'],
      country: 'United Arab Emirates',
      latitude: 25.2048,
      longitude: 55.2708,
      biome: WorldBiome.desert,
      landmark: WorldLandmark.dubaiTower),
  WorldLocation(
      id: 'singapore',
      name: 'Singapore',
      aliases: ['singapore'],
      country: 'Singapore',
      latitude: 1.3521,
      longitude: 103.8198,
      biome: WorldBiome.tropical,
      landmark: WorldLandmark.singaporeSkyline),
];

/// A location the user has saved to their Places list.
///
/// Replaces the earlier `'City|Region'` string key, which conflated a region
/// name with a coordinate pair: entries created from device location stored
/// `"19.076, 72.878"` in the region field, so any consumer that expected a
/// place name got coordinates instead.
class SavedPlace {
  const SavedPlace({
    required this.city,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final String city;
  final String region;
  final double latitude;
  final double longitude;

  /// Optional user-supplied nickname. The underlying place is unchanged, so
  /// forecasts and the world catalogue still resolve normally.
  final String? label;

  /// Stable identity for de-duplication. Coordinates are rounded so that a
  /// repeated search for the same city does not create a second entry.
  String get id => '${normalizePlaceName(city)}|'
      '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';

  /// Name shown in the UI: the nickname when set, otherwise the city.
  String get displayName => (label != null && label!.trim().isNotEmpty)
      ? label!.trim()
      : city;

  bool get hasLabel => label != null && label!.trim().isNotEmpty;

  /// Secondary line. Falls back to the city when [displayName] is a nickname, so
  /// the nickname and the place name are both visible without repeating either.
  String get subtitle {
    if (hasLabel) return city;
    if (region == city || region.trim().isEmpty) return '';
    return region;
  }

  SavedPlace copyWith({String? label, bool clearLabel = false}) => SavedPlace(
        city: city,
        region: region,
        latitude: latitude,
        longitude: longitude,
        label: clearLabel ? null : (label ?? this.label),
      );

  Map<String, Object?> toJson() => {
        'city': city,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
        if (label != null) 'label': label,
      };

  String toJsonString() => jsonEncode(toJson());

  static SavedPlace fromJson(Map<String, dynamic> json) => SavedPlace(
        city: json['city'] as String? ?? '',
        region: json['region'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        label: json['label'] as String?,
      );

  /// Reads a stored entry, accepting the legacy `'City|Region'` string so an
  /// existing Places list survives the upgrade.
  ///
  /// Legacy device-location entries carried `"lat, lon"` in the region field.
  /// That text is kept as the region, preserving the display the user already
  /// had, while the same numbers are also promoted into the coordinate fields.
  static SavedPlace? parse(String stored) {
    final trimmed = stored.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) return fromJson(decoded);
      } catch (_) {
        return null;
      }
    }
    final parts = trimmed.split('|');
    if (parts.isEmpty || parts.first.isEmpty) return null;
    final city = parts.first;
    final region = parts.length > 1 ? parts[1] : '';
    final coordinates = region
        .split(',')
        .map((value) => double.tryParse(value.trim()))
        .toList();
    final isCoordinates =
        coordinates.length == 2 && coordinates.every((value) => value != null);
    return SavedPlace(
      city: city,
      region: region,
      latitude: isCoordinates ? coordinates[0]! : 0,
      longitude: isCoordinates ? coordinates[1]! : 0,
    );
  }
}

/// Equality is identity-based so a saved list can be de-duplicated directly.
extension SavedPlaceEquality on SavedPlace {
  bool samePlace(SavedPlace other) => id == other.id;
}

/// A collectible landmark: the enum value plus how it is presented in the
/// journal's collection grid.
class LandmarkEntry {
  const LandmarkEntry(this.landmark, this.name, this.emoji);

  final WorldLandmark landmark;
  final String name;
  final String emoji;
}

/// Every catalogued landmark, in a stable order, for collection progress.
const landmarkCatalog = <LandmarkEntry>[
  LandmarkEntry(WorldLandmark.tajMahal, 'Taj Mahal', '🕌'),
  LandmarkEntry(WorldLandmark.hawaMahal, 'Hawa Mahal', '🏰'),
  LandmarkEntry(WorldLandmark.indiaGate, 'India Gate', '🏛️'),
  LandmarkEntry(WorldLandmark.gatewayOfIndia, 'Gateway of India', '⛩️'),
  LandmarkEntry(WorldLandmark.howrahBridge, 'Howrah Bridge', '🌉'),
  LandmarkEntry(WorldLandmark.varanasiGhats, 'Varanasi Ghats', '🪔'),
  LandmarkEntry(WorldLandmark.goldenTemple, 'Golden Temple', '🛕'),
  LandmarkEntry(WorldLandmark.charminar, 'Charminar', '🕌'),
  LandmarkEntry(WorldLandmark.chennaiLighthouse, 'Chennai Lighthouse', '🗼'),
  LandmarkEntry(WorldLandmark.bengaluruPalace, 'Bengaluru Palace', '🏯'),
  LandmarkEntry(WorldLandmark.kochiFishingNets, 'Kochi Fishing Nets', '🎣'),
  LandmarkEntry(WorldLandmark.srinagarLake, 'Dal Lake', '🛶'),
  LandmarkEntry(WorldLandmark.shimlaHills, 'Shimla Hills', '⛰️'),
  LandmarkEntry(WorldLandmark.lehMonastery, 'Leh Monastery', '🏔️'),
  LandmarkEntry(WorldLandmark.jaisalmerFort, 'Jaisalmer Fort', '🏜️'),
  LandmarkEntry(WorldLandmark.rishikeshBridge, 'Rishikesh Bridge', '🌁'),
  LandmarkEntry(WorldLandmark.bhopalLake, 'Bhopal Lake', '🌊'),
  LandmarkEntry(WorldLandmark.eiffelTower, 'Eiffel Tower', '🗼'),
  LandmarkEntry(WorldLandmark.bigBen, 'Big Ben', '🕰️'),
  LandmarkEntry(WorldLandmark.newYorkSkyline, 'New York Skyline', '🌆'),
  LandmarkEntry(WorldLandmark.tokyoFuji, 'Mount Fuji', '🗻'),
  LandmarkEntry(WorldLandmark.colosseum, 'Colosseum', '🏟️'),
  LandmarkEntry(WorldLandmark.cairoPyramids, 'Giza Pyramids', '🔺'),
  LandmarkEntry(WorldLandmark.sydneyOperaHouse, 'Sydney Opera House', '🎭'),
  LandmarkEntry(WorldLandmark.rioMountain, 'Sugarloaf Mountain', '⛰️'),
  LandmarkEntry(WorldLandmark.dubaiTower, 'Burj Khalifa', '🌇'),
  LandmarkEntry(WorldLandmark.singaporeSkyline, 'Singapore Skyline', '🏙️'),
];

/// A collectible weather memory, matching the keys `CharacterProfile`
/// records in `weatherExperiences`.
class WeatherBadge {
  const WeatherBadge(this.key, this.name, this.emoji);

  final String key;
  final String name;
  final String emoji;
}

const weatherBadgeCatalog = <WeatherBadge>[
  WeatherBadge('rain', 'First rain', '🌧️'),
  WeatherBadge('thunderstorm', 'First thunderstorm', '⛈️'),
  WeatherBadge('snow', 'First snowfall', '❄️'),
  WeatherBadge('season:spring', 'Spring world', '🌸'),
  WeatherBadge('season:summer', 'Summer world', '☀️'),
  WeatherBadge('season:autumn', 'Autumn world', '🍂'),
  WeatherBadge('season:winter', 'Winter world', '🌨️'),
];

/// Human-readable landmark name for the given id, falling back to a tidied
/// version of the id itself.
String landmarkDisplayName(String landmarkId) {
  for (final entry in landmarkCatalog) {
    if (entry.landmark.name == landmarkId) return entry.name;
  }
  final words = landmarkId
      .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
      .replaceAll('_', ' ');
  if (words.isEmpty) return landmarkId;
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

String normalizePlaceName(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

WorldLocation resolveWorldLocation({
  required String city,
  required String region,
  required double latitude,
  required double longitude,
}) {
  final normalizedCity = normalizePlaceName(city);
  final normalizedCountry = normalizePlaceName(region);
  for (final location in worldLocations) {
    final aliasMatch = location.aliases
        .any((alias) => normalizePlaceName(alias) == normalizedCity);
    final countryMatch = normalizedCountry.contains(
      normalizePlaceName(location.country),
    );
    final coordinateMatch = (latitude - location.latitude).abs() <= 1.5 &&
        (longitude - location.longitude).abs() <= 2.0;
    if (aliasMatch && (countryMatch || coordinateMatch)) {
      return location;
    }
  }

  final normalizedRegion = normalizePlaceName(region);
  final isIndia = normalizedRegion.contains('india');
  if (isIndia &&
      (normalizedRegion.contains('rajasthan') ||
          normalizedRegion.contains('thar'))) {
    return _fallback('regional-desert', 'Desert frontier', WorldBiome.desert,
        latitude, longitude);
  }
  if (isIndia &&
      (normalizedRegion.contains('himachal') ||
          normalizedRegion.contains('kashmir') ||
          normalizedRegion.contains('ladakh') ||
          normalizedRegion.contains('uttarakhand'))) {
    return _fallback(
        'regional-mountain',
        'Mountain frontier',
        latitude > 33 ? WorldBiome.coldDesert : WorldBiome.mountain,
        latitude,
        longitude);
  }
  if (isIndia &&
      (normalizedRegion.contains('kerala') ||
          normalizedRegion.contains('goa') ||
          normalizedRegion.contains('coastal') ||
          normalizedRegion.contains('tamil nadu'))) {
    return _fallback('regional-coast', 'Coastal frontier', WorldBiome.coastal,
        latitude, longitude);
  }
  if (isIndia && latitude.abs() < 25) {
    return _fallback('regional-tropical', 'Tropical frontier',
        WorldBiome.tropical, latitude, longitude);
  }
  if (latitude.abs() < 18) {
    return _fallback('tropical-frontier', 'Tropical frontier',
        WorldBiome.tropical, latitude, longitude);
  }
  return _fallback('regional-frontier', 'Regional frontier',
      WorldBiome.temperate, latitude, longitude);
}

WorldLocation _fallback(String id, String name, WorldBiome biome,
        double latitude, double longitude) =>
    WorldLocation(
      id: id,
      name: name,
      aliases: const [],
      country: 'Unknown',
      latitude: latitude,
      longitude: longitude,
      biome: biome,
      landmark: WorldLandmark.none,
      seasonalFoliage:
          biome == WorldBiome.temperate || biome == WorldBiome.mountain,
    );
