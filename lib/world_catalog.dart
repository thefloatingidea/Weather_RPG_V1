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

/// Broad climate bands used to pick vegetation. Derived from latitude and
/// country, with well-known exceptions overridden. This is a felt sense of
/// "what grows here", not a scientific Köppen classification.
enum ClimateZone {
  tropicalRainforest,
  tropicalSavanna,
  subtropicalDesert,
  mediterranean,
  temperateDeciduous,
  boreal,
  tundra,
  polar,
  alpine,
}

/// What kind of tree should be drawn by default in a given climate.
enum TreeSpecies { broadleaf, pine, palm, cypress, cactus, shrub, baobab }

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

/// Climate and default tree for a location, derived lazily from its own
/// coordinates and country. Kept as an extension so existing catalog entries
/// and the fallback constructor stay untouched.
extension WorldLocationClimate on WorldLocation {
  ClimateZone get climate => climateZoneFor(
        latitude: latitude,
        country: country,
        biome: biome,
      );

  TreeSpecies get defaultTree => defaultTreeFor(climate);
}

/// Latitude- and country-driven climate zone.
///
/// The rules are deliberately simple: country overrides first (because the
/// well-known cases should not be guessed), then latitude bands. A biome hint
/// from a catalog entry wins over both when it describes extreme terrain
/// (desert, cold desert, mountain) that the fallback system cannot know about.
ClimateZone climateZoneFor({
  required double latitude,
  required String country,
  WorldBiome? biome,
}) {
  final normalized = normalizePlaceName(country);
  bool has(String name) => normalized.contains(name);

  // Catalog biome hints win for extreme terrain.
  if (biome == WorldBiome.desert) return ClimateZone.subtropicalDesert;
  if (biome == WorldBiome.coldDesert) return ClimateZone.alpine;
  if (biome == WorldBiome.mountain) return ClimateZone.alpine;

  // Hot deserts: North Africa, Arabian peninsula, Iranian plateau, US Southwest.
  if (has('egypt') ||
      has('libya') ||
      has('algeria') ||
      has('morocco') ||
      has('tunisia') ||
      has('sudan') ||
      has('saudi') ||
      has('emirates') ||
      has('uae') ||
      has('qatar') ||
      has('oman') ||
      has('kuwait') ||
      has('bahrain') ||
      has('iraq') ||
      has('iran') ||
      has('yemen') ||
      has('jordan') ||
      has('israel') ||
      has('arizona') ||
      has('nevada')) {
    return ClimateZone.subtropicalDesert;
  }

  // Alpine: high-altitude countries where the mountains dominate the scene.
  if (has('nepal') ||
      has('bhutan') ||
      has('tibet') ||
      has('mongolia') ||
      has('kazakhstan') ||
      has('kyrgyzstan') ||
      has('tajikistan') ||
      has('uzbekistan') ||
      has('switzerland') ||
      (has('austria') && latitude.abs() > 46)) {
    return ClimateZone.alpine;
  }

  // Boreal: far-north countries. Canada is NOT included by default — southern
  // Canada is temperate deciduous, and only its northern territories reach
  // boreal, which the latitude check below handles.
  if (has('norway') ||
      has('sweden') ||
      has('finland') ||
      has('iceland') ||
      has('russia') ||
      has('alaska') ||
      (has('canada') && latitude.abs() >= 55)) {
    return ClimateZone.boreal;
  }

  // Tropical belt by country (equatorial and monsoon regions).
  if (has('singapore') ||
      has('malaysia') ||
      has('indonesia') ||
      has('philippines') ||
      has('thailand') ||
      has('vietnam') ||
      has('cambodia') ||
      has('laos') ||
      has('myanmar') ||
      has('brunei') ||
      has('sri lanka') ||
      has('maldives') ||
      has('kenya') ||
      has('tanzania') ||
      has('uganda') ||
      has('rwanda') ||
      has('nigeria') ||
      has('ghana') ||
      has('ivory coast') ||
      has('senegal') ||
      has('cameroon') ||
      has('congo') ||
      (has('brazil') && latitude.abs() < 15) ||
      has('colombia') ||
      has('venezuela') ||
      has('ecuador') ||
      (has('peru') && latitude.abs() < 12) ||
      has('costa rica') ||
      has('panama') ||
      has('nicaragua') ||
      has('guatemala') ||
      has('honduras') ||
      has('belize')) {
    return ClimateZone.tropicalRainforest;
  }

  // Mediterranean: dry-summer subtropics. Coastal southern Europe, parts of
  // California, Chile, South Africa, and southern Australia.
  if (has('spain') ||
      has('portugal') ||
      has('italy') ||
      has('greece') ||
      has('croatia') ||
      has('malta') ||
      has('cyprus') ||
      (has('turkey') && latitude.abs() < 40) ||
      has('lebanon') ||
      has('syria') ||
      has('california') ||
      (has('chile') && latitude.abs() < 38) ||
      has('south africa') ||
      (has('australia') &&
          latitude.abs() >= 30 &&
          latitude.abs() <= 38)) {
    return ClimateZone.mediterranean;
  }

  // Latitude bands as the last resort.
  final absLat = latitude.abs();
  if (absLat < 10) return ClimateZone.tropicalRainforest;
  if (absLat < 20) return ClimateZone.tropicalSavanna;
  if (absLat < 30) return ClimateZone.subtropicalDesert;
  if (absLat < 40) return ClimateZone.mediterranean;
  if (absLat < 55) return ClimateZone.temperateDeciduous;
  if (absLat < 66) return ClimateZone.boreal;
  if (absLat < 72) return ClimateZone.tundra;
  return ClimateZone.polar;
}

TreeSpecies defaultTreeFor(ClimateZone zone) => switch (zone) {
      ClimateZone.tropicalRainforest => TreeSpecies.palm,
      ClimateZone.tropicalSavanna => TreeSpecies.baobab,
      ClimateZone.subtropicalDesert => TreeSpecies.cactus,
      ClimateZone.mediterranean => TreeSpecies.cypress,
      ClimateZone.temperateDeciduous => TreeSpecies.broadleaf,
      ClimateZone.boreal => TreeSpecies.pine,
      ClimateZone.tundra => TreeSpecies.shrub,
      ClimateZone.polar => TreeSpecies.shrub,
      ClimateZone.alpine => TreeSpecies.pine,
    };

/// Stable 32-bit seed from a location's id. Used to vary procedural scenery
/// per city so two temperate towns do not render identically.
int worldLocationSeed(WorldLocation location) {
  var hash = 5381;
  for (final unit in location.id.codeUnits) {
    hash = ((hash << 5) + hash) ^ unit;
  }
  return hash & 0x7FFFFFFF;
}

// ─────────────────────────────────────────────────────────────────────────────
// Catalog. Climate and tree species are derived lazily from each entry's own
// coordinates and country, so nothing below needs editing when a new city is
// added.
// ─────────────────────────────────────────────────────────────────────────────

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

  /// Secondary line. Falls back to the city when [displayName] is a nickname,
  /// so the nickname and the place name are both visible without repeating
  /// either.
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

/// Resolves a city into a catalog entry, or constructs a plausible frontier
/// location from its coordinates and country.
///
/// The fallback chain consults country hints and latitude bands via
/// [climateZoneFor], so a temperate-zone search no longer always ends up in
/// the same tree-lined field: Cairo gets cacti, Oslo gets pines, Berlin gets
/// an urban skyline.
WorldLocation resolveWorldLocation({
  required String city,
  required String region,
  required double latitude,
  required double longitude,
}) {
  final normalizedCity = normalizePlaceName(city);
  final normalizedRegion = normalizePlaceName(region);
  for (final location in worldLocations) {
    final aliasMatch = location.aliases
        .any((alias) => normalizePlaceName(alias) == normalizedCity);
    final countryMatch = normalizedRegion.contains(
      normalizePlaceName(location.country),
    );
    final coordinateMatch = (latitude - location.latitude).abs() <= 1.5 &&
        (longitude - location.longitude).abs() <= 2.0;
    if (aliasMatch && (countryMatch || coordinateMatch)) {
      return location;
    }
  }

  final isIndia = normalizedRegion.contains('india');

  // India-specific regions first: they are the app's home turf and deserve
  // the more precise names.
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

    // Indo-Gangetic plain and central India. Fertile river plains — the crude
  // latitude band would otherwise classify all of this as subtropical desert.
  if (isIndia &&
      (normalizedRegion.contains('uttar pradesh') ||
          normalizedRegion.contains('bihar') ||
          normalizedRegion.contains('jharkhand') ||
          normalizedRegion.contains('punjab') ||
          normalizedRegion.contains('haryana') ||
          normalizedRegion.contains('delhi') ||
          normalizedRegion.contains('madhya pradesh') ||
          normalizedRegion.contains('chhattisgarh') ||
          normalizedRegion.contains('west bengal') ||
          normalizedRegion.contains('odisha') ||
          normalizedRegion.contains('assam') ||
          normalizedRegion.contains('uttarakhand'))) {
    return _fallback('regional-plains', 'River plains', WorldBiome.river,
        latitude, longitude);
  }

  // Deccan plateau: Maharashtra, Karnataka, Telangana, Andhra Pradesh.
  if (isIndia &&
      (normalizedRegion.contains('maharashtra') ||
          normalizedRegion.contains('karnataka') ||
          normalizedRegion.contains('telangana') ||
          normalizedRegion.contains('andhra pradesh') ||
          normalizedRegion.contains('goa'))) {
    return _fallback('regional-deccan', 'Deccan frontier',
        WorldBiome.tropical, latitude, longitude);
  }

  // Country-driven climate zone. This decides the visual scene more than the
  // region string does for non-catalog cities.
  final zone = climateZoneFor(
    latitude: latitude,
    country: region,
    biome: null,
  );

  switch (zone) {
    case ClimateZone.subtropicalDesert:
      return _fallback('regional-desert', 'Desert frontier', WorldBiome.desert,
          latitude, longitude);
    case ClimateZone.alpine:
      return _fallback('regional-alpine', 'Alpine frontier',
          WorldBiome.mountain, latitude, longitude);
    case ClimateZone.boreal:
      return _fallback('regional-boreal', 'Boreal frontier',
          WorldBiome.mountain, latitude, longitude);
    case ClimateZone.tundra:
    case ClimateZone.polar:
      return _fallback('regional-tundra', 'Tundra frontier',
          WorldBiome.coldDesert, latitude, longitude);
    case ClimateZone.tropicalRainforest:
      return _fallback('regional-tropical', 'Tropical frontier',
          WorldBiome.tropical, latitude, longitude);
    case ClimateZone.tropicalSavanna:
      return _fallback('regional-savanna', 'Savanna frontier',
          WorldBiome.tropical, latitude, longitude);
    case ClimateZone.mediterranean:
      return _fallback('regional-mediterranean', 'Coastal frontier',
          WorldBiome.coastal, latitude, longitude);
    case ClimateZone.temperateDeciduous:
      // Temperate is the most common case, so it further splits by likelihood
      // of the city being urban, coastal, or inland.
      if (normalizedRegion.contains('united states') ||
          normalizedRegion.contains('united kingdom') ||
          normalizedRegion.contains('germany') ||
          normalizedRegion.contains('france') ||
          normalizedRegion.contains('japan') ||
          normalizedRegion.contains('china')) {
        return _fallback('regional-urban', 'Urban frontier', WorldBiome.urban,
            latitude, longitude);
      }
      return _fallback('regional-temperate', 'Temperate frontier',
          WorldBiome.river, latitude, longitude);
  }
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