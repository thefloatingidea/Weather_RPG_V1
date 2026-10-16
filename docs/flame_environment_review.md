# Review: the Flame-generated environment in `weather_rpg`

Scope: `lib/weather_scene.dart` (3,468 lines), its inputs from `lib/world_catalog.dart`
and `lib/weather_rules.dart`, and the Flutter chrome that hosts it in `lib/main.dart`.

To review the environment as it actually looks rather than as it reads, I drove
`WeatherSceneGame` directly and rendered real frames to PNG
(`test/_probe_render.dart`, outputs in `build/probe_*.png`). Every claim below is
tied to either a rendered frame or a specific line.

Regenerate the frames at any time:

```
flutter test test/_probe_render.dart
```

---

## 1. What the scene actually looks like today

Six representative states, rendered from the current code at 900×420:

| Config | Frame |
| --- | --- |
| Mumbai, monsoon rain, day | `build/probe_mumbai_rain_day.png` |
| Delhi, clear day | `build/probe_delhi_clear_day.png` |
| London, clear night | `build/probe_london_night_clear.png` |
| Jaisalmer, 41 °C desert heat | `build/probe_jaisalmer_heat.png` |
| Srinagar, snow | `build/probe_srinagar_snow.png` |
| Chennai, cyclone environment | `build/probe_cyclone_env.png` |

The honest summary: the **weather simulation** is strong, the **scene composition**
is flat, and the **art direction** is the weakest link.

What is genuinely working:

- **Weather/state modelling.** `WeatherConditions` (`weather_rules.dart`) plus the
  ~60 derived getters on the game produce a wide, correct-feeling behavioural space:
  drizzle vs. heavy rain, fog by visibility, dust by code, overheat by temperature,
  gale lean by wind. The goblin reacts to all of it.
- **Character animation for a zero-asset setup.** Blink, gaze, head turn, walk cycle,
  shiver, gust lean, breath puffs, sweat, sun-dizziness, hit recovery, paddling,
  resting/sleeping silhouettes — all procedural and coherent.
- **The cyclone frame is the best-looking scene in the app.** The rotating spiral
  cloud walls with a growing eye, bowing palms, streaking debris and rotating fronds
  (`weather_scene.dart:1571-1693`) read as a real event. It is also, per §3.1,
  unreachable from the app.
- **Accessibility plumbing** — `reduceMotion` and `reduceFlashing` are threaded into
  most effect systems rather than bolted on.

Where it falls short:

- Landmarks, horizon, ground and clouds are all flat single-tone shapes. See §2.1.
- The character is always drawn **last and centred on top of the landmark**, so the
  one detailed object in the scene is the one most often occluded
  (`weather_scene.dart:1157-1180`). Visible in `probe_mumbai_rain_day.png`, where the
  goblin sits exactly on the Gateway of India's arch.
- Without the `_drawRainyForest` branch, "rain" is a flat water band plus a few lines.
- Night is a flat 20 %-blue wash over the lower 58 % of the canvas
  (`weather_scene.dart:1146-1149`), including the landmark it is supposed to keep visible.

---

## 2. Highest-value improvements

Ordered by visual return per unit of work.

### 2.1 Declare the assets, then put the goblin on a real sprite

`assets/images/` holds 20 PNGs totalling ~900 KB, and `pubspec.yaml` has **no
`assets:` section**. Nothing in `lib/` references any of them (verified by grep for
`assets/`, `Sprite`, `loadSprite`, `AssetImage`, `rootBundle`). So on every target
platform these files ship as dead weight and the app renders 100 % geometry.

They are not rough placeholders. They are finished pixel art:

| Asset | Size | Notes |
| --- | --- | --- |
| `goblin_frames/idle_00..07.png` | 96×112 ×8 | ready 8-frame idle animation |
| `goblin_frames/walk_00..07.png` | 96×112 ×8 | ready 8-frame walk animation |
| `goblin_explorer.png` | 162×184 | high-detail character portrait |
| `monsoon_forest.png` | 990×620 | full rainy-forest scene |
| `ocean_summer.png` | 2304×1296 | summer ocean scene |
| `wizard/*-sheet.png` | 1536×128 ×2 | 12-frame sheets, idle + walk |

`monsoon_forest.png` is the decisive one: it is a fully rendered pixel-art version of
the *exact* scene that `_drawRainyForest` (`weather_scene.dart:2731-2903`) tries to
reproduce in code — same left-hand tree with the hanging lantern, same fence on the
right, same pond with rain rings, same purple flowers, same red mushroom. `README.md:61`
confirms the intent ("not yet the final extracted sprite assets from the approved
reference atlas"). Side-by-side:

```
build/ref_vs_procedural.png   # reference asset above, current render below
```

**Recommendation, in order of payoff:**

1. Add to `pubspec.yaml`:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/images/
       - assets/images/goblin_frames/
       - assets/images/wizard/
   ```
2. Replace the geometry goblin with `SpriteAnimation` driven by the two 8-frame sets.
   The behavior controller already exposes exactly the signals needed: `isWalking`
   selects walk vs. idle, `walkDirection` flips on `scale(-1, 1)`, `stateAge` gives the
   time base. This deletes hundreds of lines of pose math and looks better immediately.
3. Keep the *effects* procedural (sweat, shiver, lantern glow, scarf tail) but draw them
   as overlays on the sprite, so the visual identity survives.
4. Use the sprite frames as the **palette and scale authority** for the rest of the
   scene: sample the sprite's greens/browns into a shared `ScenePalette`, and match the
   sprite's pixel block size when drawing terrain, so the world and the character stop
   looking like they came from two different projects.

If the assets cannot be used for licensing reasons, the same conclusion still applies —
the scene needs *one* art authority, and today `weather_scene.dart` has 430 hardcoded
`const ui.Color(...)` literals with no central palette.

### 2.2 Give the scene depth: split it into parallax layers

Today the paint order is one flat sequence over a single coordinate space:

```
sky → sunrise tint → stars/haze → sun/moon → clouds → ground slab → horizon ridge
→ biome trees → terrain details → landmark → weather → character → lightning → fog → bubble
```

Everything shares one baseline (`h * .57` for the ground, `weather_scene.dart:1054`),
so nothing is at a different distance. Fixing this is the single biggest structural
change available.

Proposed layer stack, drawn back to front, each with its own scroll/offset rate:

| # | Layer | Contents | Motion |
| --- | --- | --- | --- |
| 0 | Sky gradient | vertical gradient, not a flat rect | static |
| 1 | Celestial | sun/moon on a computed arc | static per frame |
| 2 | Far clouds | 4–6 slow, low-contrast | ×0.15 wind |
| 3 | Far ridge | silhouette, desaturated | ×0.3 wind |
| 4 | Landmark | the city's identity | ×0.4 wind (slight) |
| 5 | Mid terrain | trees, dunes, buildings | ×0.6 |
| 6 | Weather | rain/snow/dust/fog banks | physics-driven |
| 7 | Character | sprite | walks |
| 8 | Near ground + props | grass tufts, stones, puddle rims | ×1.4 wind |

Two cheap wins inside this restructuring:

- **Separate character and landmark lanes.** Keep the character in the front lane but
  bias `_sceneX` (`weather_scene.dart:347-374`) away from the landmark's screen box,
  and add a soft contact shadow + 1 px darker outline so the two never merge. Right now
  they collide on the horizontal centre in almost every configuration.
- **Buffer the static layers.** Layers 0–5 change only when location, weather class,
  season or size changes. Render them once into a `ui.Picture`/`ui.Image` and blit per
  frame. See §3.3.

### 2.3 Make the horizon and terrain follow the biome

`_drawHorizon` (`weather_scene.dart:2591-2649`) picks its colours from season/storm
flags and always draws the same sawtooth "green hills" ridge. Consequently:

- Delhi (urban) shows temperate green hills behind India Gate — see
  `probe_delhi_clear_day.png`.
- Jaisalmer (desert) draws those same green hills behind the dunes, then paints the
  desert on top — see `probe_jaisalmer_heat.png`.
- Srinagar's lake is a hard-edged, highly saturated teal band with no shoreline, and
  the houseboat reads as a floating brown slab — `probe_srinagar_snow.png`.

**Recommendation:** select the horizon silhouette and palette from
`location.biome` + `WorldSeason`, exactly as `_drawRegionalFallback`
(`weather_scene.dart:2369-2449`) already does for the ground. Urban should be a
building skyline; desert should be dune ridges; mountain should be the existing
`_drawMountainRange`; coastal should be sea horizon with haze. Then delete the
duplicate desert dune logic that currently draws twice for arid locations
(`weather_scene.dart:1073-1089` and `weather_scene.dart:1828-1835`).

Also fix the water: add a shoreline transition, reduce saturation toward the horizon,
and let the sky colour reflect into it (`ui.Color.lerp(water, _skyColor, .25)`).

### 2.4 Add a lighting pass — this is what separates "flat" from "atmospheric"

The scene has no light model. There are exactly two gradients in 3,468 lines
(`weather_scene.dart:985` sunrise tint, `weather_scene.dart:2795` lantern glow), and
every other shape is a flat fill. Two concrete additions:

1. **A global directional tint + gradient overlay** driven by `isDay`, `localHour` and
   storm state. The sun and moon are drawn at fixed coordinates
   (`weather_scene.dart:995-1025`); `localHour` is already in the config
   (`weather_scene.dart:160`), so computing an arc position and a matching light
   direction is nearly free. This also gives windswept shadows a consistent direction.
2. **Per-element shading.** Add a single `_shade(color, factor)` helper and apply a
   consistent lit-side / shadow-side pair to landmarks, trees, dunes and buildings. Right
   now `weatherSceneGroundColor` supplies one ground tone and `groundEdge` supplies one
   highlight stripe (`weather_scene.dart:1070`), which is why the ground reads as paper.

Then make the night pass per-element instead of a wash: instead of dimming the bottom
58 % uniformly (`weather_scene.dart:1144-1151`), multiply each drawn colour by a night
factor and keep the landmark lamps, goblin lantern and windows un-dimmed so they read
as light sources.

### 2.5 Give the particles real physics

`_drawWeatherParticles` (`weather_scene.dart:2905-3000`) positions every drop as a
pure function of index and time:

```dart
final x = (i * 41.0 + _elapsed * _environmentMotionScale * (windSlant * 12 + 12)) % w;
final y = (i * 29.0 + _elapsed * fallSpeed) % h;
```

Consequences: particles are perfectly evenly spaced, share a fixed screen-space slant
that ignores each drop's own fall speed, wrap abruptly at the edges, and produce the
visible diagonal stutter you can see in the rain and sandstorm frames.

**Recommendation:** promote particles to real state (`x, y, vx, vy, life`) updated in
`update()` — the `_AmbientCreature` struct (`weather_scene.dart:77-120`) is already the
pattern to copy. Then: advect with wind, vary per-particle speed, respawn above the top
edge with a lifetime fade, and add ground splash events that reuse the existing splash
rects (`weather_scene.dart:3246-3252`). Bonus: this makes rain react to `_wind` changes
continuously instead of snapping.

### 2.6 Snap drawing to a pixel grid for coherence

The scene mixes axis-aligned `_rect` blocks with anti-aliased `drawCircle`,
`drawOval` and quadratic-beziers (sun discs `weather_scene.dart:998-1001`, mountain
peaks, cloud gaps, pond rings, lantern glow). At a 900 px logical width a "pixel" is
2–3 px, so smooth curves visibly disagree with the blocks.

**Recommendation:** derive `unit = max(2, min(w,h) * .014)` (already done,
`weather_scene.dart:1170`) as the *scene pixel size*, round every primitive to that
grid, and replace decorative circles/ovals with pixel-stepped shapes. Set
`pixelArt: true` on `GameWidget` (`weather_scene.dart:189`) and
`FilterQuality.none` on any sprite added per §2.1.

### 2.7 Unify the UI palette with the scene

`_WeatherMenuPalette.fromWeather` (`main.dart:65-336`) computes an 11-mood palette for
the Flutter chrome, while the Flame scene independently re-derives its own weather
logic from the same data. The two can disagree — the HUD can say "storm" while the sky
is clear. `main.dart` also carries three more painters that duplicate scene concepts:
`_ForestBackdropPainter`, `_MenuParticlePainter`, `_SceneFrameEtchingPainter`.

**Recommendation:** extract one shared mood model (a `WeatherMood` enum plus palette)
into its own file, consume it from both `main.dart` and `WeatherSceneGame`, and pass
the palette into the scene so the panel frame, HUD tags and sky tones come from one
source.

---

## 3. Architecture and performance

### 3.1 Four of the five environments are unreachable

`SceneEnvironment` has five values; `main.dart` hardcodes `SceneEnvironment.live` in
all three construction sites (`main.dart:929`, `main.dart:1009`, `main.dart:1282`).
There is no UI path, no weather-code mapping and no test that ever selects `cyclone`,
`flood`, `desertHeat` or `sandstorm`. That makes roughly 700 lines of the best art in
the project (`_drawCyclone`, `_drawFlood`, `_drawFloodHouse`, `_drawSandstorm`,
`_drawFloodAlert`, plus the environment branches scattered through the getters) dead
code in the shipped app.

**Recommendation:** decide and wire it. Either
(a) expose an "extreme scenario" mode — a dev toggle in Settings, or an explicit
`environment` derivation from weather code + severity in one place — or
(b) delete the unreachable paths. Leaving them is the worst option: they already drift,
and they cannot be exercised by tests.

### 3.2 The propensity getter soup

56 boolean getters on the game (`_live`, `_cyclone`, `_flood`, `_desertHeat`,
`_sandstorm`, `_hot`, `_cold`, `_windy`, `_storm`, `_rain`, `_fog`, `_snow`, …) are
evaluated repeatedly inside `render()` and sometimes recursively (`_rain` calls `_storm`
calls `_cyclone`; `_cold` calls `_snow`). Several embed magic weather-code lists that
duplicate `WeatherConditions` (`weather_scene.dart:1441` tests `weatherCode == 71 || 73`
instead of using `WeatherConditions.snowCodes`, which is `{71,73,75,77,85,86}`).

**Recommendation:** resolve all of this **once** per config change into an immutable
`SceneState` value object (`WeatherConditions` + `WorldLocation` + season + derived
booleans) and have `render()` read fields instead of recomputing predicates. This is a
prerequisite for both the layer caching in §3.3 and for testing scene behaviour without
rendering.

### 3.3 Nothing is cached; everything is re-recorded every frame

Measured canvas operations per single `render()` call at 900×420, worst-case weather
state, via an instrumented `ui.Canvas`:

| Scene | ops/frame | rects | paths | circles | lines | ovals |
| --- | --- | --- | --- | --- | --- | --- |
| Clear day (Delhi) | 81 | 70 | 4 | 0 | 2 | 1 |
| Snow day (Srinagar) | 113 | 98 | 10 | 2 | 2 | 1 |
| Clear night (London) | 139 | 84 | 3 | 45 | 2 | 1 |
| Monsoon rain day (Mumbai) | 148 | 78 | 3 | 0 | 57 | 10 |
| Thunderstorm night (Mumbai) | 153 | 99 | 3 | 4 | 37 | 10 |
| Temperate rain (Paris) | 190 | 111 | 18 | 8 | 43 | 10 |
| Sandstorm (Jaisalmer) | 227 | 125 | 7 | 0 | 90 | 5 |
| Cyclone (Chennai) | 241 | 142 | 34 | 18 | 37 | 10 |
| Flood (Kolkata) | 294 | 187 | 8 | 1 | 88 | 10 |

Read alongside the source, the important part is not the raw count — it is that
**static content is rebuilt and re-recorded every frame, 60 times a second**:

- Every `_rect()` call constructs a fresh `ui.Paint` (`weather_scene.dart:3455-3458`).
  Night stars alone are 34 `drawCircle` calls *per star* (paint allocated inside the
  loop, `weather_scene.dart:1859-1864`).
- `_drawSpeechBubble` builds and lays out a `TextPainter` on **every** frame that
  dialogue is visible (`weather_scene.dart:1371-1383`), and dialogue is visible for
  2–4 s after each line.
- Landmarks rebuild multi-point `Path` objects per frame (e.g. `weather_scene.dart:1605-1644`
  builds three 181-point spiral paths every frame for the cyclone).

The 3,600-point cyclone spiral is worth flagging specifically: it is the most expensive
drawing in the app and the one most sensitive to device fill rate.

**Recommendations, cheapest first:**

1. `RepaintBoundary` around the scene (`main.dart:1251-1322` already has a
   `ClipRRect`/`Stack` there) so the HUD overlay does not force scene re-recording.
2. Cache the `TextPainter` and the `Paint` objects — a `Map<int, ui.Paint>` keyed by
   colour removes nearly all per-frame allocation with a small diff.
3. Render the static layers (§2.2 layers 0–5) into a `ui.Picture` on demand and
   `canvas.drawPicture` them per frame. This is the big one: it removes the landmark,
   horizon, terrain and biome work from the per-frame budget entirely.
4. Precompute the cyclone spiral path once per (size, approach) instead of per frame.
5. Profile before and after with `flutter run --profile` and the timeline's raster
   thread — the numbers above bound the *recording* work, not the GPU fill rate, and the
   gradient/fog overlays are the likely raster cost.

### 3.4 `weather_scene.dart` is a god object

3,468 lines, one class, 26 `_draw*` methods, 328 `_rect` call sites, no tests that
assert anything about the rendered scene (the existing scene test only checks two
palette functions). `render()` itself is ~250 lines of sequential drawing
(`weather_scene.dart:966-1213`).

**Recommendation:** split along the layer boundaries from §2.2 — `SceneBackdrop`,
`SceneLandmark`, `SceneTerrain`, `SceneWeather`, `SceneCharacter` — each with a
`render(canvas, state)` and, where useful, a cached layer. Keep them in one library
folder. This makes the environment testable per-layer and makes adding a city a matter
of adding one file rather than one `case`.

### 3.5 Smaller correctness and hygiene items

- **Fog alpha is squared, so the fog is far fainter than the code intends.**
  `weather_scene.dart:1192-1199` builds `mist` with `alpha` 18–48, then calls
  `mist.withOpacity(.28/.42/.34)` on it, which strips the original alpha and applies the
  fraction to it. The composed alpha therefore lands near 5–20 out of 255, and because
  `.28`, `.42` and `.34` are hardcoded the layer ordering ends up inverted relative to
  the computed `alpha`. The three bands should use one computed per-band alpha instead.
  This is the faded, washed-out look in the fog path.
- `weather_scene.dart:2332` (`ui.Color(0xFF596D72).withOpacity(.72)`) applies the
  deprecated API to an already-opaque constant; harmless, but it is one of the 40
  `withOpacity` deprecations the analyzer reports, and the intended value would be
  clearer as a single `fromARGB` or a precomputed constant.
- 46 analyzer infos currently (`flutter analyze`): 40 `withOpacity` deprecations and
  6 `curly_braces_in_flow_control_structures`. All cosmetic, none blocking, but they
  mask new issues.
- The scene has no `camera`/`viewport` configuration; everything is proportional to
  `size`, which is why the aspect ratio never breaks. Preserve this property when
  refactoring — it is a real strength.

---

## 4. Suggested sequence

| Step | Change | Why |
| --- | --- | --- |
| 1 | Declare assets in `pubspec.yaml`; load `goblin_frames` as a `SpriteAnimation` | Largest visible quality jump for the least code; unlocks the rest |
| 2 | Extract `ScenePalette` + `SceneState` (resolved per config change) | Prerequisite for every later step; removes getter recomputation |
| 3 | Cache static layers as `ui.Picture`; cache `Paint`/`TextPainter` | Makes headroom for the additions below on mid-range Android |
| 4 | Add parallax layers and separate character/landmark lanes | Fixes the flatness and the occlusion problem |
| 5 | Biome-driven horizon + terrain; shoreline and water reflection | Fixes the Delhi/Jaisalmer/Srinagar mismatches visible in the probes |
| 6 | Lighting pass: sun arc from `localHour`, directional tint, per-element shading, per-element night dim | Turns "flat" into "atmospheric" |
| 7 | Particle physics refactor (state + wind advection + splashes) | Removes the visible tiling and stutter |
| 8 | Unify mood/palette between `main.dart` and the scene | Stops the HUD and the world disagreeing |
| 9 | Decide the fate of the four unreachable environments | Either ship a scenario mode or delete ~700 lines |

---

## 5. Evidence files

| File | What it is |
| --- | --- |
| `build/probe_mumbai_rain_day.png` | Current render, Mumbai monsoon rain, day |
| `build/probe_delhi_clear_day.png` | Current render, Delhi clear day (green hills behind an urban landmark) |
| `build/probe_london_night_clear.png` | Current render, London clear night (flat night wash, warm windows) |
| `build/probe_jaisalmer_heat.png` | Current render, desert heat (sun disc banding, green horizon) |
| `build/probe_srinagar_snow.png` | Current render, snow (hard-edged lake, floating houseboat) |
| `build/probe_cyclone_env.png` | Current render, cyclone (best scene, and unreachable) |
| `build/ref_vs_procedural.png` | `monsoon_forest.png` above the procedural render of the same scene |
| `test/_probe_render.dart` | Harness that regenerates all frames |

`build/` is gitignored, so none of the PNGs are in version control;
`test/_probe_render.dart` is a new file and can be kept as a visual regression
harness or deleted.
