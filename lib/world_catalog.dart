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
