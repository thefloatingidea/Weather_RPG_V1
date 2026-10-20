// Map-box overrides for climate zones.
//
// The country-based rules in `climateZoneFor` cannot see geography inside a
// country, and its last-resort latitude band calls everything between 20 and
// 30 degrees "desert" (which would show cactus trees in Dhaka, Guangzhou or
// Miami). These boxes correct the biggest cases from latitude and longitude
// alone. They are deliberately coarse: first match wins, so specific boxes
// come before broad ones, and anything not covered returns null and falls
// back to the existing rules.
import 'world_catalog.dart';

class _ClimateBox {
  const _ClimateBox(
      this.zone, this.minLat, this.maxLat, this.minLon, this.maxLon);

  final ClimateZone zone;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  bool contains(double lat, double lon) =>
      lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
}

const ClimateZone _alpine = ClimateZone.alpine;
const ClimateZone _desert = ClimateZone.subtropicalDesert;
const ClimateZone _rain = ClimateZone.tropicalRainforest;
const ClimateZone _temperate = ClimateZone.temperateDeciduous;

const List<_ClimateBox> _boxes = [
  // Mountain belts.
  _ClimateBox(_alpine, 36, 49, -114, -104.5), // Rockies
  _ClimateBox(_alpine, 45.5, 47.8, 6, 14), // Alps
  _ClimateBox(_alpine, 29, 36, 80, 99), // Tibetan plateau
  _ClimateBox(_alpine, 34, 39, 66, 77), // Hindu Kush, Karakoram, Pamir
  _ClimateBox(_alpine, 39, 45, 70, 82), // Tian Shan
  _ClimateBox(_alpine, 41, 44, 40, 49), // Caucasus
  _ClimateBox(_alpine, 6, 14, 36, 40), // Ethiopian highlands
  // Atacama before the Andes, so the coastal desert wins.
  _ClimateBox(_desert, -30, -18, -71.5, -69),
  _ClimateBox(_alpine, -55, -30, -72, -69), // southern Andes
  _ClimateBox(_alpine, -20, -8, -73, -67), // central Andes
  _ClimateBox(_alpine, -4, 4, -80, -76.5), // Ecuador
  _ClimateBox(_alpine, 2, 8, -77.5, -72.5), // Colombia
  // Hot deserts.
  _ClimateBox(_desert, 18, 31, -13, 33), // Sahara
  _ClimateBox(_desert, 15, 32, 36, 59.5), // Arabia
  _ClimateBox(_desert, 26, 36, 50, 66), // Iranian plateau
  _ClimateBox(_desert, 26, 30, 69, 75), // Thar
  _ClimateBox(_desert, 36, 41, 77, 90), // Taklamakan
  _ClimateBox(_desert, -33, -19, 116, 143), // Australian interior
  _ClimateBox(_desert, -29, -17, 12, 24), // Namib and Kalahari
  _ClimateBox(_desert, 25, 36.5, -118, -103), // Sonoran and Chihuahuan
  _ClimateBox(_desert, 0, 12, 41, 51), // Horn of Africa
  // Rainforest and humid tropics.
  _ClimateBox(_rain, -10, 5, -75, -50), // Amazon
  _ClimateBox(_rain, -5, 4, 11, 30), // Congo
  _ClimateBox(_rain, 8, 27, 88, 125), // monsoon Asia
  _ClimateBox(_rain, 24, 28, -83, -79.5), // south Florida
  _ClimateBox(_rain, -25, -15, -60, -40), // Atlantic Brazil
  // Humid temperate regions that the latitude band would call desert.
  _ClimateBox(_temperate, 28, 36, -98, -75), // south-east United States
  _ClimateBox(_temperate, 27, 40, 105, 142), // east China, Korea, Japan
  _ClimateBox(_temperate, -35, -25, -60, -40), // southern Brazil, Uruguay
  // Far north: Canada and Alaska.
  _ClimateBox(ClimateZone.boreal, 52, 66.5, -168, -60),
];

/// Climate zone for a coordinate, or null when no box applies and the
/// existing country and latitude rules should decide.
ClimateZone? climateZoneByBox(double latitude, double longitude) {
  if (latitude.abs() >= 72 || latitude <= -60) return ClimateZone.polar;
  // Greenland, without catching Iceland.
  if ((latitude >= 60 && latitude <= 84 && longitude >= -73 && longitude <= -26) ||
      (latitude >= 68 && latitude <= 84 && longitude >= -26 && longitude <= -12)) {
    return ClimateZone.polar;
  }
  for (final box in _boxes) {
    if (box.contains(latitude, longitude)) return box.zone;
  }
  return null;
}
