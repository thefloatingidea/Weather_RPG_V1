// Extra environment detail drawn on top of the existing scene.
//
// Everything here is purely decorative and self-contained: it reads a small
// plain-data context, draws a capped number of small rectangles, and never
// touches game state. To switch every addition off, set [kWorldDetail] to
// false. Positions come from a hash of the place's id, so a place always looks
// the same, but different from its neighbours.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'world_catalog.dart';

/// Master switch for all additions in this file.
const bool kWorldDetail = true;

final ui.Paint _paint = ui.Paint()..isAntiAlias = false;

void _px(ui.Canvas c, double x, double y, double w, double h, ui.Color col) {
  _paint.color = col;
  c.drawRect(ui.Rect.fromLTWH(x, y, w, h), _paint);
}

/// Stable seed for a place. Not `String.hashCode`, so it never changes
/// between runs or platforms.
int detailSeed(String id) {
  var n = 7;
  for (final u in id.codeUnits) {
    n = (n * 31 + u) & 0x7FFFFFFF;
  }
  return n;
}

/// Stable pseudo-random number in [0, 1) for (seed, index, channel).
double detailRandom(int seed, int i, int k) {
  var n = ((seed * 73856093) ^ (i * 19349663) ^ (k * 83492791)) & 0x7FFFFFFF;
  n = (((n >> 15) ^ n) * 2246822519) & 0x7FFFFFFF;
  n = (((n >> 13) ^ n) * 3266489917) & 0x7FFFFFFF;
  return (n & 0xFFFF) / 65536.0;
}

/// Everything the ground layer needs to know, as plain data.
class WorldDetailContext {
  const WorldDetailContext({
    required this.w,
    required this.h,
    required this.seed,
    required this.biome,
    required this.arid,
    required this.winter,
    required this.storm,
    required this.elapsed,
    this.zone,
  });

  final double w;
  final double h;
  final int seed;
  final WorldBiome biome;

  /// Dry, sandy ground (desert biome, arid regions, sandstorms).
  final bool arid;
  final bool winter;
  final bool storm;

  /// Seconds, already scaled for reduce-motion.
  final double elapsed;

  /// Climate of the place, used for zone-specific extras (savanna, boreal...).
  final ClimateZone? zone;
}

ui.Color _tone(ui.Color c, WorldDetailContext x) =>
    x.storm ? ui.Color.lerp(c, const ui.Color(0xFF1B2A33), .35)! : c;

/// Position inside the ground band, stable for (seed, i).
ui.Offset _spot(WorldDetailContext x, int i,
    {double y0 = .70, double y1 = .95, int ch = 0}) {
  final rx = detailRandom(x.seed, i, ch);
  final ry = detailRandom(x.seed, i, ch + 1);
  return ui.Offset(x.w * (.03 + .94 * rx), x.h * (y0 + (y1 - y0) * ry));
}

double _sway(WorldDetailContext x, int i, double amount) =>
    math.sin(x.elapsed * 1.6 + i * 1.9) * amount;

/// Biome-specific ground clutter. Draw it right after the terrain details.
void paintBiomeGroundDetail(ui.Canvas c, WorldDetailContext x) {
  if (!kWorldDetail) return;
  if (x.winter) {
    _winter(c, x);
  } else if (x.arid || x.biome == WorldBiome.desert) {
    _desert(c, x);
  } else {
    switch (x.biome) {
      case WorldBiome.tropical:
        _tropical(c, x);
      case WorldBiome.coastal:
        _coastal(c, x);
      case WorldBiome.river:
        _river(c, x);
      case WorldBiome.urban:
        _urban(c, x);
      case WorldBiome.mountain:
        _mountain(c, x);
      case WorldBiome.coldDesert:
        _coldDesert(c, x);
      case WorldBiome.temperate:
      case WorldBiome.desert:
        _temperate(c, x);
    }
  }
  if (!x.winter && !x.arid) _zoneExtras(c, x);
}

/// Small additions that make climates look different even when two places
/// share a biome (for example savanna and rainforest are both "tropical").
void _zoneExtras(ui.Canvas c, WorldDetailContext x) {
  switch (x.zone) {
    case ClimateZone.tropicalSavanna:
      _savanna(c, x);
    case ClimateZone.boreal:
      _boreal(c, x);
    case ClimateZone.mediterranean:
      _mediterranean(c, x);
    case ClimateZone.tundra:
    case ClimateZone.polar:
      _tundra(c, x);
    default:
      break;
  }
}

void _savanna(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 10; i++) {
    final p = _spot(x, 60 + i, y0: .72);
    final s = _sway(x, i, u * .4);
    for (var k = 0; k < 3; k++) {
      _px(c, p.dx + (k - 1) * u * 1.1 + s * k * .4, p.dy - u * (2.2 + k % 2), u * .5, u * (2.6 + k % 2), _tone(const ui.Color(0xFFC9A94E), x));
    }
  }
  for (var i = 0; i < 2; i++) {
    final p = _spot(x, 80 + i, y0: .70, y1: .76);
    _px(c, p.dx, p.dy - u * 5, u * .9, u * 5, _tone(const ui.Color(0xFF4A3A28), x));
    _px(c, p.dx - u * 4, p.dy - u * 6.6, u * 8.8, u * 1.6, _tone(const ui.Color(0xFF5E6B2E), x));
    _px(c, p.dx - u * 2.4, p.dy - u * 7.8, u * 5.6, u * 1.2, _tone(const ui.Color(0xFF6E7C38), x));
  }
}

void _boreal(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 3; i++) {
    final p = _spot(x, 60 + i, y0: .74);
    _px(c, p.dx, p.dy, u * 3.4, u * 1.8, _tone(const ui.Color(0xFF70777A), x));
    _px(c, p.dx - u * .2, p.dy - u * .8, u * 3.2, u * 1.1, _tone(const ui.Color(0xFF5E7F4A), x));
  }
  for (var i = 0; i < 5; i++) {
    final p = _spot(x, 70 + i, y0: .78);
    _px(c, p.dx, p.dy, u * 2.6, u * .7, _tone(const ui.Color(0xFF9DB08A), x));
  }
  for (var i = 0; i < 3; i++) {
    final p = _spot(x, 80 + i, y0: .72);
    const dark = ui.Color(0xFF2F5A47);
    _px(c, p.dx, p.dy - u * 3.4, u * 1.0, u * 1.2, _tone(dark, x));
    _px(c, p.dx - u * .7, p.dy - u * 2.2, u * 2.4, u * 1.2, _tone(dark, x));
    _px(c, p.dx - u * 1.2, p.dy - u * 1.0, u * 3.4, u * 1.2, _tone(dark, x));
  }
}

void _mediterranean(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 5; i++) {
    final p = _spot(x, 60 + i, y0: .73);
    final s = _sway(x, i, u * .4);
    _px(c, p.dx - u * 1.2, p.dy - u * .4, u * 3, u * .8, _tone(const ui.Color(0xFF5F7D4A), x));
    for (var k = 0; k < 3; k++) {
      _px(c, p.dx + (k - 1) * u * 1.2 + s * .5, p.dy - u * (2.6 + k % 2), u * .6, u * (2.4 + k % 2), _tone(const ui.Color(0xFF8E6BBF), x));
    }
  }
  for (var i = 0; i < 2; i++) {
    final p = _spot(x, 75 + i, y0: .74);
    _px(c, p.dx, p.dy - u * 2.4, u * 5, u * 2.4, _tone(const ui.Color(0xFF7C8A5A), x));
    _px(c, p.dx + u * .6, p.dy - u * 3.2, u * 3.4, u * 1.0, _tone(const ui.Color(0xFF93A06E), x));
  }
  for (var i = 0; i < 4; i++) {
    final p = _spot(x, 85 + i, y0: .78);
    _px(c, p.dx, p.dy, u * 1.6, u * .9, _tone(const ui.Color(0xFFB4673B), x));
  }
}

void _tundra(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 6; i++) {
    final p = _spot(x, 60 + i, y0: .76);
    _px(c, p.dx, p.dy, u * 2.2, u * .7, _tone(i.isEven ? const ui.Color(0xFFD9893B) : const ui.Color(0xFFB7C79A), x));
  }
  for (var i = 0; i < 4; i++) {
    final p = _spot(x, 70 + i, y0: .74);
    const shrub = ui.Color(0xFF8A4B3A);
    _px(c, p.dx, p.dy - u * 1.6, u * 2.8, u * 1.4, _tone(shrub, x));
    _px(c, p.dx + u * .6, p.dy - u * 2.4, u * 1.6, u * .9, _tone(shrub, x));
  }
  final q = _spot(x, 80, y0: .82, y1: .88);
  _px(c, q.dx, q.dy, x.w * .07, x.h * .018, const ui.Color(0xAA7A93A6));
  _px(c, q.dx + u * 1.2, q.dy + u * .3, x.w * .03, u * .5, const ui.Color(0x88DCE8F0));
}

void _temperate(ui.Canvas c, WorldDetailContext x) {
  const sets = [
    [ui.Color(0xFFF4F0E4), ui.Color(0xFFF2C94C)],
    [ui.Color(0xFFB794F4), ui.Color(0xFFF6AD55)],
    [ui.Color(0xFFFC8181), ui.Color(0xFFFAF089)],
  ];
  final pal = sets[x.seed % sets.length];
  final u = x.w * .006;
  for (var i = 0; i < 7; i++) {
    final p = _spot(x, i, y0: .72);
    final sx = _sway(x, i, u * .35);
    _px(c, p.dx, p.dy, u * .6, u * 3.2, _tone(const ui.Color(0xFF3C7A47), x));
    _px(c, p.dx - u + sx, p.dy - u, u * 3, u, _tone(pal[0], x));
    _px(c, p.dx + sx, p.dy - u * 2, u, u * 3, _tone(pal[0], x));
    _px(c, p.dx + sx, p.dy - u, u, u, _tone(pal[1], x));
  }
  for (var i = 0; i < 6; i++) {
    final p = _spot(x, 20 + i, y0: .74);
    _px(c, p.dx, p.dy, u * 2.4, u, _tone(const ui.Color(0xFF3F7A4C), x));
    _px(c, p.dx + u * .6, p.dy - u * .8, u * 1.4, u, _tone(const ui.Color(0xFF4C9059), x));
  }
}

void _tropical(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  final dark = _tone(const ui.Color(0xFF2E7D4F), x);
  final light = _tone(const ui.Color(0xFF4FA86A), x);
  for (var i = 0; i < 6; i++) {
    final p = _spot(x, i, y0: .72);
    final s = _sway(x, i, u * .5);
    _px(c, p.dx, p.dy - u * 2, u * .7, u * 4, dark);
    for (var k = 0; k < 2; k++) {
      final ly = p.dy - u * (1.8 - k * 1.6);
      _px(c, p.dx - u * 3 + s, ly, u * 3, u * .8, k == 0 ? light : dark);
      _px(c, p.dx + u * .7 + s, ly + u * .6, u * 3, u * .8, k == 0 ? dark : light);
    }
  }
  for (var i = 0; i < 4; i++) {
    final p = _spot(x, 30 + i, y0: .75);
    _px(c, p.dx, p.dy, u * .6, u * 3, dark);
    _px(c, p.dx - u, p.dy - u * 1.4, u * 3, u * 1.4, _tone(const ui.Color(0xFFE5484D), x));
    _px(c, p.dx, p.dy - u * 1.0, u, u, _tone(const ui.Color(0xFFFFD166), x));
  }
}

void _coastal(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 6; i++) {
    final p = _spot(x, i, y0: .76);
    _px(c, p.dx, p.dy, u * 2, u * 1.2, _tone(const ui.Color(0xFFF3E6DA), x));
    _px(c, p.dx + u * .4, p.dy - u * .5, u * 1.2, u * .6, _tone(const ui.Color(0xFFE8B7B0), x));
  }
  for (var i = 0; i < 2; i++) {
    final p = _spot(x, 10 + i, y0: .80);
    _px(c, p.dx, p.dy, x.w * .05, u * 1.1, _tone(const ui.Color(0xFF8A6B4A), x));
    _px(c, p.dx + x.w * .018, p.dy + u * .2, u * 1.2, u * .6, _tone(const ui.Color(0xFF5E4630), x));
  }
  for (var i = 0; i < 5; i++) {
    final p = _spot(x, 20 + i, y0: .72);
    final s = _sway(x, i, u * .5);
    for (var k = 0; k < 3; k++) {
      _px(c, p.dx + (k - 1) * u * 1.3 + s * k * .5, p.dy - u * (2 + k % 2), u * .5, u * (3 + k % 2), _tone(const ui.Color(0xFFA9B66B), x));
    }
  }
  for (var i = 0; i < 6; i++) {
    final p = _spot(x, 40 + i, y0: .78);
    _px(c, p.dx, p.dy, u * 1.4, u * .8, _tone(const ui.Color(0xFF9AA0A6), x));
  }
}

void _river(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 5; i++) {
    final p = _spot(x, i, y0: .72);
    final s = _sway(x, i, u * .6);
    for (var k = 0; k < 3; k++) {
      final off = (k - 1) * u * 1.4;
      final top = u * (4 + k % 2 * 1.4);
      _px(c, p.dx + off + s * (k + 1) * .3, p.dy - top, u * .5, top + u, _tone(const ui.Color(0xFF5E8F4A), x));
    }
    _px(c, p.dx + s * .6, p.dy - u * 5.6, u * 1.1, u * 2.2, _tone(const ui.Color(0xFF6B4A2B), x));
  }
  for (var i = 0; i < 6; i++) {
    final p = _spot(x, 20 + i, y0: .80);
    _px(c, p.dx, p.dy, u * 2.4, u * 1.2, _tone(const ui.Color(0xFF7C8A8E), x));
    _px(c, p.dx, p.dy + u * 1.2, u * 2.4, u * .5, _tone(const ui.Color(0xFF4F5C60), x));
  }
}

void _urban(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  const seam = ui.Color(0x33000000);
  for (var row = 0; row < 3; row++) {
    final y = x.h * (.78 + row * .07);
    _px(c, 0, y, x.w, u * .35, seam);
    final off = row.isOdd ? x.w * .06 : 0.0;
    for (var k = 0; k < 8; k++) {
      _px(c, off + k * x.w * .125, y, u * .35, x.h * .07, seam);
    }
  }
  for (var i = 0; i < 3; i++) {
    final p = _spot(x, i, y0: .79);
    _px(c, p.dx, p.dy, u * 1.5, u * .5, const ui.Color(0x55000000));
    _px(c, p.dx + u * 1.5, p.dy + u * .5, u * 1.5, u * .5, const ui.Color(0x55000000));
    _px(c, p.dx + u * 3, p.dy + u, u * 1.2, u * .5, const ui.Color(0x55000000));
    _px(c, p.dx + u * .6, p.dy - u * 1.2, u * .5, u * 1.4, _tone(const ui.Color(0xFF4C8A4F), x));
  }
  final m = _spot(x, 9, y0: .86);
  _px(c, m.dx, m.dy, x.w * .05, x.h * .016, const ui.Color(0x66000000));
  _px(c, m.dx + u * .6, m.dy + u * .4, x.w * .05 - u * 1.2, x.h * .016 - u * .8, const ui.Color(0x44FFFFFF));
}

void _desert(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 7; i++) {
    final p = _spot(x, i, y0: .74);
    _px(c, p.dx, p.dy, u * 1.8, u * 1.0, const ui.Color(0xFFB98A55));
    _px(c, p.dx + u * .3, p.dy - u * .4, u * 1.0, u * .5, const ui.Color(0xFFD2A874));
  }
  for (var i = 0; i < 4; i++) {
    final p = _spot(x, 20 + i, y0: .74);
    final dry = _tone(const ui.Color(0xFF8C7A3E), x);
    _px(c, p.dx, p.dy - u * 2.2, u * .5, u * 2.6, dry);
    _px(c, p.dx - u * 1.4, p.dy - u * 1.6, u * 1.4, u * .5, dry);
    _px(c, p.dx + u * .5, p.dy - u * 2.8, u * 1.4, u * .5, dry);
  }
  final t = _spot(x, 40, y0: .84);
  const weed = ui.Color(0xFF9A8348);
  _px(c, t.dx, t.dy, u * 3, u * .5, weed);
  _px(c, t.dx + u * 1.2, t.dy - u * 1.2, u * .5, u * 3, weed);
  _px(c, t.dx + u * .4, t.dy - u * .5, u * 2.2, u * .5, weed);
}

void _mountain(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 4; i++) {
    final p = _spot(x, i, y0: .74);
    final big = 1.0 + detailRandom(x.seed, i, 5) * .8;
    _px(c, p.dx, p.dy, u * 4 * big, u * 2.2 * big, _tone(const ui.Color(0xFF6D7479), x));
    _px(c, p.dx + u * .8 * big, p.dy - u * 1.4 * big, u * 2.6 * big, u * 1.6 * big, _tone(const ui.Color(0xFF7E858A), x));
    _px(c, p.dx + u * .8 * big, p.dy - u * 1.4 * big, u * 2.6 * big, u * .5, _tone(const ui.Color(0xFFA0A7AB), x));
  }
  for (var i = 0; i < 10; i++) {
    final p = _spot(x, 20 + i, y0: .78);
    _px(c, p.dx, p.dy, u * .8, u * .5, _tone(const ui.Color(0xFF8B9094), x));
  }
  for (var i = 0; i < 6; i++) {
    final p = _spot(x, 40 + i, y0: .72);
    final s = _sway(x, i, u * .3);
    _px(c, p.dx + s, p.dy - u * 1.6, u * .5, u * 1.8, _tone(const ui.Color(0xFF9AA55A), x));
    if (i < 4) {
      _px(c, p.dx - u * .4 + s, p.dy - u * 2.4, u * 1.2, u * .8, _tone(const ui.Color(0xFFA37BD8), x));
    }
  }
}

void _coldDesert(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 5; i++) {
    final p = _spot(x, i, y0: .74);
    _px(c, p.dx, p.dy, u * 3.4, u * 1.2, _tone(const ui.Color(0xFF8E99A4), x));
    _px(c, p.dx, p.dy - u * .5, u * 3.4, u * .5, _tone(const ui.Color(0xFFB6C0C9), x));
  }
  for (var i = 0; i < 8; i++) {
    final p = _spot(x, 20 + i, y0: .78);
    _px(c, p.dx, p.dy, u * .8, u * .5, _tone(const ui.Color(0xFF9AA3AB), x));
  }
  for (var i = 0; i < 5; i++) {
    final p = _spot(x, 40 + i, y0: .73);
    final s = _sway(x, i, u * .3);
    _px(c, p.dx + s, p.dy - u * 1.8, u * .5, u * 2, _tone(const ui.Color(0xFFA8956A), x));
    _px(c, p.dx + u * .8 + s, p.dy - u * 1.2, u * .5, u * 1.4, _tone(const ui.Color(0xFFA8956A), x));
  }
}

void _winter(ui.Canvas c, WorldDetailContext x) {
  final u = x.w * .006;
  for (var i = 0; i < 4; i++) {
    final p = _spot(x, i, y0: .74);
    _px(c, p.dx, p.dy, u * 3, u * 1.6, const ui.Color(0xFF59646F));
    _px(c, p.dx - u * .3, p.dy - u * .7, u * 3.6, u * .9, const ui.Color(0xFFF2F6F8));
  }
  for (var i = 0; i < 5; i++) {
    final p = _spot(x, 20 + i, y0: .76);
    _px(c, p.dx, p.dy - u * 1.6, u * .5, u * 1.8, const ui.Color(0xFF2F5A47));
    _px(c, p.dx - u * .6, p.dy - u * 1.0, u * 1.7, u * .5, const ui.Color(0xFF2F5A47));
  }
}

/// A few moths circling the character's lantern. [lantern] is in the same
/// coordinate space as the canvas; [unit] is the character's pixel size.
void paintLanternMoths(ui.Canvas c, ui.Offset lantern, double unit,
    double elapsed, int seed) {
  if (!kWorldDetail) return;
  for (var i = 0; i < 3; i++) {
    final ph = elapsed * (1.1 + i * .37) + i * 2.1 + detailRandom(seed, i, 7) * 6;
    final r = unit * (2.4 + i * .9);
    final mx = lantern.dx + math.cos(ph * 1.3) * r + math.sin(ph * 3.1) * unit * .5;
    final my = lantern.dy - unit * 1.2 + math.sin(ph) * r * .7 + math.cos(ph * 5.0) * unit * .3;
    final up = math.sin(elapsed * 22 + i * 1.9) > 0;
    const wing = ui.Color(0xE6F2E6C8);
    _px(c, mx - unit * .6, my - (up ? unit * .5 : unit * .15), unit * .55, up ? unit * .5 : unit * .3, wing);
    _px(c, mx + unit * .05, my - (up ? unit * .5 : unit * .15), unit * .55, up ? unit * .5 : unit * .3, wing);
    _px(c, mx - unit * .12, my - unit * .1, unit * .24, unit * .4, const ui.Color(0xFF7A6A4C));
  }
}
