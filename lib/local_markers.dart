/// Small, city-specific set-dressing that makes the environment feel local.
///
/// Landmarks are one large iconic structure per catalogued city. Markers are
/// the opposite: small, numerous, and aimed at the cities that have no
/// landmark of their own. Bareilly gets a jhumka shop, Aligarh gets a lock
/// shop, Firozabad gets bangles, and any unrecognised Indian city falls back
/// to a chai stall.
///
/// A marker is drawn only when the resolved location has no landmark, so a
/// scene never carries two competing focal points.
enum LocalMarkerKind {
  // Indian regional specialities.
  jhumkaShop,
  brasswareShop,
  lockShop,
  bangleStall,
  chikanStall,
  pethaShop,
  littiChokha,
  pohaJalebiCart,
  orangeBasket,
  biryaniPot,
  rosogollaStall,
  filterCoffeeStand,
  diyaCluster,
  kathputliPuppet,
  vadaPavCart,
  tramStop,
  chaiStall,

  // International props, for cities without a landmark.
  cafeTable,
  vendingMachine,
  phoneBox,
  hotDogCart,
  scooter,
  hawkerStall,
}

class LocalMarker {
  const LocalMarker({
    required this.kind,
    required this.name,
    required this.hint,
    this.cityAliases = const [],
    this.regionAliases = const [],
    this.countryAliases = const [],
  });

  final LocalMarkerKind kind;
  final String name;
  final String hint;

  /// Exact (normalised) city names. Highest priority match.
  final List<String> cityAliases;

  /// Substrings of the region string. Matches Indian states, US states, and
  /// similar administrative names that arrive from the search API.
  final List<String> regionAliases;

  /// Country name substrings. Lowest priority — the fallback for any city not
  /// otherwise matched.
  final List<String> countryAliases;
}

/// The marker catalogue.
///
/// Order matters only within a priority tier. Exact city matches are checked
/// first, then region substrings, then country substrings.
const localMarkerCatalog = <LocalMarker>[
  // ── Uttar Pradesh ─────────────────────────────────────────────────────────
  LocalMarker(
    kind: LocalMarkerKind.jhumkaShop,
    name: 'Bareilly ka Jhumka',
    hint: 'A small stall of hanging jhumkas catches the light.',
    cityAliases: ['bareilly'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.brasswareShop,
    name: 'Moradabad Brassware',
    hint: 'Hammered brass pots sit stacked outside the shop.',
    cityAliases: ['moradabad'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.lockShop,
    name: 'Aligarh Locks',
    hint: 'A rack of iron padlocks, all sizes, catches the light.',
    cityAliases: ['aligarh'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.chikanStall,
    name: 'Lucknow Chikankari',
    hint: 'Delicate white embroidery hangs from the stall roof.',
    cityAliases: ['lucknow'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.pethaShop,
    name: 'Agra Petha',
    hint: 'Trays of pale petha cubes sit stacked on the counter.',
    cityAliases: ['agra'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.pohaJalebiCart,
    name: 'Indori Poha-Jalebi',
    hint: 'A cart selling poha with a side of hot jalebi.',
    cityAliases: ['indore'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.littiChokha,
    name: 'Litti Chokha',
    hint: 'Litti roasting over coals, chokha in a clay bowl.',
    cityAliases: ['patna'],
    regionAliases: ['bihar'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.chaiStall,
    name: 'Chai Stall',
    hint: 'A kettle, three glasses, and a small crowd of steam.',
    cityAliases: ['kanpur', 'prayagraj', 'allahabad', 'meerut', 'gorakhpur'],
  ),

  // ── Other Indian cities ──────────────────────────────────────────────────
  LocalMarker(
    kind: LocalMarkerKind.bangleStall,
    name: 'Firozabad Bangles',
    hint: 'A wire frame hung with bangles in every colour.',
    cityAliases: ['firozabad'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.orangeBasket,
    name: 'Nagpur Oranges',
    hint: 'A basket of oranges at the roadside.',
    cityAliases: ['nagpur'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.biryaniPot,
    name: 'Hyderabadi Biryani',
    hint: 'A covered dum pot still letting off steam.',
    cityAliases: ['hyderabad', 'secunderabad'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.rosogollaStall,
    name: 'Rosogolla Stall',
    hint: 'A glass case of rosogollas in syrup.',
    cityAliases: ['kolkata', 'calcutta'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.filterCoffeeStand,
    name: 'Filter Coffee',
    hint: 'A steel tumbler and davara, coffee still dripping.',
    cityAliases: [
      'chennai',
      'madras',
      'bengaluru',
      'bangalore',
      'mysuru',
      'mysore',
      'coimbatore',
    ],
    regionAliases: ['tamil nadu', 'karnataka'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.diyaCluster,
    name: 'Floating Diyas',
    hint: 'Small lamps drift on the river.',
    cityAliases: ['varanasi', 'banaras', 'benares'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.kathputliPuppet,
    name: 'Kathputli',
    hint: 'A string puppet leans against a small stand.',
    cityAliases: ['jaipur'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.vadaPavCart,
    name: 'Vada Pav Cart',
    hint: 'A cart with a fryer, buns stacked beside it.',
    cityAliases: ['mumbai', 'bombay', 'pune', 'thane', 'nashik'],
    regionAliases: ['maharashtra'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.tramStop,
    name: 'Tram Stop',
    hint: 'A small shelter with a faded tram timetable.',
    cityAliases: ['kolkata', 'calcutta'],
  ),

  // ── International fallbacks ──────────────────────────────────────────────
  LocalMarker(
    kind: LocalMarkerKind.cafeTable,
    name: 'Café Table',
    hint: 'A small round table and two chairs on the pavement.',
    countryAliases: ['france', 'italy', 'spain', 'portugal'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.vendingMachine,
    name: 'Vending Machine',
    hint: 'A lit vending machine hums beside the path.',
    countryAliases: ['japan', 'korea', 'taiwan'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.phoneBox,
    name: 'Phone Box',
    hint: 'A red phone box, glass steamed from the inside.',
    countryAliases: ['united kingdom', 'ireland'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.hotDogCart,
    name: 'Hot Dog Cart',
    hint: 'A cart with a striped umbrella and a small queue.',
    countryAliases: ['united states', 'canada'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.scooter,
    name: 'Vespa',
    hint: 'A small scooter parked at the kerb.',
    countryAliases: ['italy', 'greece'],
  ),
  LocalMarker(
    kind: LocalMarkerKind.hawkerStall,
    name: 'Hawker Stall',
    hint: 'A small stall under an awning, lit by one bulb.',
    countryAliases: ['singapore', 'malaysia', 'thailand', 'vietnam'],
  ),

  // ── Catch-all ─────────────────────────────────────────────────────────────
  LocalMarker(
    kind: LocalMarkerKind.chaiStall,
    name: 'Chai Stall',
    hint: 'A kettle, three glasses, and a small crowd of steam.',
    countryAliases: ['india', 'pakistan', 'bangladesh', 'sri lanka', 'nepal'],
  ),
];

String _normalise(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Picks the most specific marker for the given location.
///
/// Priority: exact city match, then region substring, then country substring.
/// Returns null when nothing matches, in which case the scene draws nothing —
/// an unmarked scene is better than a wrongly marked one.
LocalMarker? pickLocalMarker({
  required String city,
  required String region,
  String? country,
}) {
  final cityKey = _normalise(city);
  final regionKey = _normalise(region);
  final countryKey = _normalise(country ?? '');

  for (final marker in localMarkerCatalog) {
    if (marker.cityAliases.any((a) => _normalise(a) == cityKey)) {
      return marker;
    }
  }
  for (final marker in localMarkerCatalog) {
    if (marker.regionAliases.any((a) => regionKey.contains(_normalise(a)))) {
      return marker;
    }
  }
  for (final marker in localMarkerCatalog) {
    if (marker.countryAliases.any((a) => countryKey.contains(_normalise(a)))) {
      return marker;
    }
    // Region sometimes carries the country, e.g. "Maharashtra, India".
    if (marker.countryAliases.any((a) => regionKey.contains(_normalise(a)))) {
      return marker;
    }
  }
  return null;
}