# STATUS.md — SquirrelStash Sync Ledger

**Last Updated:** 2026-11-27 — v1.2 "Living Colony" (Claude Code): Acorn upkeep economy & seed expeditions, Canopy Bird Feeder & Lifetime Logbook, re-themed Great Oak, live DC Metro stops, audio lifecycle fix
**Active Phase:** v1.2 (`1.2.0+2`) built, verified on the host (analyze, 109 tests incl. 28 screenshot renders, web release build) and **installed on the Pixel 9 Pro XL** for hands-on testing. Next: **v2.0** (replaces the planned v1.3), a full graphics redo with custom Fallout Shelter-style art: in-depth rooms in a 2.5D dollhouse cutaway.
**Stack:** Flutter 3.50.1 (Dart 3.14) + Flame 1.38 + SQLite (sqflite, **schema v3**) + Riverpod 3.5 + http 1.6 + share_plus 13 + file_picker 13 + audioplayers 6.8

---

## 1. Tech Stack & Build Status

| Concern | Package | Notes |
|---|---|---|
| UI framework | Flutter 3.50.1 stable, `material_ui` 1.x | Import `package:material_ui/material_ui.dart`, **not** `package:flutter/material.dart`. |
| 2D Great Oak | `flame` ^1.38.2 | One `FlameGame` in a fixed **600 × 1150** world, inside an `InteractiveViewer` (1.0x–2.8x). |
| State | `flutter_riverpod` ^3.5.0 | `Notifier`/`Provider` only (no codegen). Time-driven code reads `clockProvider`, so tests can fast-forward. |
| Persistence | `sqflite` ^2.4.6 (+ `sqflite_common_ffi`) | **Schema v3** with tested v1 → v2 → v3 migrations. Money is integer cents; per-unit market prices are REAL dollars. |
| Live prices | `http` ^1.6.0 | CoinGecko + Yahoo Finance chart JSON, no API keys, cached per holding. |
| Audio | `audioplayers` ^6.8.1 | Lifecycle-aware `AudioPlayersService`: one soft `plink.wav` SFX plus an **optional** piano loop drop-in (see §2.1). |
| Formatting | `intl` ^0.20.3 | Currency and dates. |
| Backup | `share_plus` ^13.3.1, `file_picker` ^13.4.1 | Backup JSON is now `schemaVersion: 3`; v2 backups still restore through the row upgrade `BackupCodec._toV3`. |
| Fonts | Fredoka + Nunito (bundled, SIL OFL) | They lack glyphs such as ▲ ↻ ✎ ● ✓ (render as boxes). Use Material Icons or ASCII. |

**Verified on this Mac (Intel, macOS 14.7) in this session:**
- `flutter analyze` ✅ **No issues found**
- `flutter test` ✅ **109/109 passing**: the v1.1 tests (updated for free looks and the new room order), **16 new colony tests** (`test/colony_test.dart`: Granary cap & overflow, collector/fuel/lure math, deterministic bird sim, owl only at night, 100-visit keepsakes, and fast-forward-clock flows for expeditions, feeder visits, Hearth dimming, bubble harvests, Golden upgrades and lure refusals), a **v2 → v3 SQLite migration test**, a v3 table upsert test, a **v2 backup → v3 upgrade test**, a colony backup round trip, and **28 screenshot renders** (12 new).
- `flutter build web --release` ✅ (compile check)
- **Pixel 9 Pro XL (2026-11-27):** release APK `1.2.0+2` (versionCode 2) signed with the release key (SHA-256 `cb24a625…caf2d`, matches the installed app), installed in place with `adb install -r` (first-install time unchanged, so data kept). It launches on Impeller/Vulkan, the v3 migration ran with no `SQLite unavailable` fallback, and the tree renders with the live Metro board, disco lights, holiday tree and a lit Hearth (the 12h welcome fill). The phone's stash was in the "Start fresh" state ($0, 100 Acorns) before this update. **Still to try by hand:** audio pause/resume (needs a temporary `ambient_piano.wav`), frame rate while zoomed, haptics, and tapping the acorn bubbles at 1.0x. See §4.

### How to run locally
```bash
export PATH="$HOME/development/flutter/bin:$PATH"   # Flutter is not on PATH by default
flutter pub get
flutter analyze
flutter test                        # full suite (incl. screenshots)
flutter test test/screenshot        # re-render docs/screenshots/*.png
flutter run -d chrome               # dev preview (in-memory demo, offline prices)
# Pixel (release-signed, keeps data). Never a plain debug `flutter run` against it:
flutter build apk --release && ~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 2. Completed Features & Recent Changes (v1.2)

### 2.1 Audio lifecycle fix & calm background piano
- `AudioPlayersService` is a `WidgetsBindingObserver`. The moment the app goes `inactive`, `hidden`, `paused` or `detached` it pauses the piano and stops SFX (no force-close needed). On `resumed` the piano comes back **only if** it is still switched on. Play and pause calls are serialized so quick toggles and lifecycle changes never race.
- **Removed:** the loud owl reward chime (`chime.wav`), `campfire.wav`, `forest_breeze.wav`, the `AmbientTrack` model and the track picker. Rewards now use the soft `plink`. `tool/generate_audio.dart` only makes `plink.wav`.
- **Drop-in slot:** `assets/audio/ambient_piano.wav` (a block-sandbox-style calm piano loop). **No file ships**, so the toggle stays completely silent until you add one and rebuild. The Focus drawer says so; Settings shows "Calm background piano".
- Schema v3 deletes the retired `ambient_track` setting.

### 2.2 Acorn upkeep economy (no more cosmetic paywalls)
- **Free:** every Outfitter trinket (no level gates), Colony Outfits, all Grand Tree looks (beacon, fairy lights, twilight, seasonal foliage) and every room theme. Each room drawer ends with a free **Starter / Cozy / Max** picker (`RoomThemeCard`).
- **HUD Starter | Max switch fixed:** it now re-themes **every room** at once (persisted), and every room has distinct Max art: gold trim plus room-specific extras (neon SKATE sign & light truss, lab chalkboard & microscope, kitchen garland & presents, vault portholes & lifebuoy, goal torches, birdhouse mansion, burrow stone arch & map, Metro ad panels, pocket lamps & coin stacks, brass furnace). It lights "Max" when all rooms are Max, "Starter" when all are Starter, and neither for a mix.
- **Granary cap** (`AppSettings.withAcorns / spendAcorns`): Acorns over the cap wait in `acorns_overflow` and roll in automatically when there is room, so nothing earned is ever lost. Caps 2,500 → 5,000 → 10,000 → 25,000 → 60,000 (Golden Acorns 2 / 4 / 8 / 15). Existing balances are grandfathered into a big enough level by the v3 migration.
- **Passive canopy collector:** up to 5 tappable wild-acorn bubbles float above the crown (30 Acorns each). It fills in 8h while the Hearth is lit and 12h when dark, including time away. Tap the bubbles (or "+N" in the Hearth or Shop) to harvest.
- **Deep-Root Hearth & Tree-Light Generator** (new room, bottom-right root cavern): fuel costs 10 Acorns per hour (+4h / +12h / Fill). While lit: tree fairy lights, Outfitter disco, kitchen tree decorating and full worker bustle. When it runs dry the tree dims to twilight and every squirrel curls up asleep where it stands (the "work clock" freezes), trains stop and the fire falls to embers. **Balances are never touched.** New and upgraded stashes get a 12h welcome fill.
- **Golden Acorn infrastructure:** Granary Storage, Hearth Burn-Time (12h → 24h → 3 days; 3 / 8 Golden), up to 2 extra Canopy Terrace pedestals (2 / 3 Golden), Instant 24h Colony Festival (2 Golden: confetti every few seconds, peak disco, Hearth lit, rare visitors ×3).
- **Acorn sinks:** Hearth fuel, Hearth Overdrive 24h (240) / 48h (420), DC Metro Rush-Hour Worker Flood 3h (150), Seed Foraging Expeditions (40 / 120 / 300), Temporary 2nd Scavenger Squad 24h (300), feeder lures (80 / 120 / 200).
- The HUD Acorn counters open the **Colony Shop & Granary** (`decor_shop.dart`): Granary bar and overflow, bubbles, Golden infrastructure, Hearth, boosts, free looks and all room themes.
- A **colony clock** (`ColonyActions.tick`: at launch, every 20s and on resume) settles bubbles, feeder visits and returning squads.

### 2.3 Scavenger Burrow & Canopy Bird Feeder
- **Right canopy branch:** hammock removed. Upgradeable birdhouse (pine box → painted with a flower box → three-story mansion with a weathervane), a wooden landing perch where visitors touch down, and the hanging feeder showing its seed level and lures. A rope bucket hauls seed bags up the outer bark from the burrow.
- **Left canopy branch:** old red birdhouse removed. **Owl Moonlight Lantern** (moon-glass globe, owl-shaped cap) with an open songbird perch underneath. It glows at dusk, takes the Treat color with the Beacon look, and blazes with moths under Moonlight Lantern Oil. Professor Hoot moved here.
- **Grass-level Scavenger Burrow Outpost** (new room): prep alcove with backpack hooks and a quartermaster, a grassy mound with the hole on the ground line, a signpost, and ready seed bags by the door. On dispatch a squirrel pops out with a backpack and sprints off the map; on return it sprints back in carrying a seed bag (auto-collected, no second timer or payment).
  - Meadow Edge Dash 2h / 40 → Sunflower & Millet Mix (Cardinal, Blue Jay, Chickadee, Robin)
  - Woodland Ridge Trek 6h / 120 → Berry & Hickory Nut Blend (Red-bellied Woodpecker, Cedar Waxwing, Baltimore Oriole, Eastern Chipmunk)
  - Deep Forest Expedition 12h / 300 → Golden Husk & Wild Berry Feast (Bald Eagle, Great Horned Owl at night, Peregrine Falcon, Albino Squirrel)
- **Bird Feeder drawer:** feeder status, perched-now chips, pour a bag (6h per bag, 8h for Golden Husk, up to 3 bags of one seed), lures (Sweet Berry & Suet Cake 12h, Moonlight Lantern Oil "1 night" = until a 7am at least 6h away, Deluxe Multi-Perch Feast 24h with two extra perches) and the logbook.
- **Visits** are simulated per 10-minute slot while seed is in the feeder (deterministic per slot, so nothing double counts). Night halves the rate unless Moonlight Oil is out; the owl only comes 7pm–7am.
- **Lifetime Bird & Critter Logbook:** all-time visits, first/last seen and favorite lure for 12 species. Each needs a **uniform 100 visits** for its keepsake medallion (with a banner on unlock), and counts keep climbing past 100. Unseen species show as silhouettes.

### 2.4 Re-themed Great Oak
- **Crown:** Canopy Treasury plus the **Canopy Terrace** deck with 4 stone Display Pedestals (up to 6). The pedestals left the ground line.
- **Left trunk (hero rooms):**
  - **Acorn Outfitter:** indoor mini half-pipe with 1–3 skaters riding the curve, DJ Hazelnut on bottle-cap turntables, and a spinning mirror disco ball casting slowly panning, color-shifting lights (off when the Hearth is out, brighter at a Festival). Upgraded 35mm film canisters and Giant Framed Pokémon Card (original card art).
  - **Ratatouille Kitchen:** stove, the Brass Thumbpin Dining Table (moved here) on the Vintage Button Rug with spool stools, and the Treehouse Christmas Tree, with a decorator on a ladder and a light-string helper while lit (unlit in the dark).
  - **Hollow Log Bill Vault:** full width, with the **Etch A Sketch removed from the room** (the countdown board stays in the drawer). Three waterline scenes from unpaid bills ÷ Free Cash: **High (> 50%)** brass scuba diver plus a raft angler whose heavy acorn slips back about 3 times in 4; **Mid (25–50%)** walnut-shell skiff and a seam patcher; **Low (< 25%)** a shallow clear brook, lawn chairs and acorn-cup drinks. The Frostline freezes the surface.
- **Right trunk (compact rooms):** Foraging Lab; Trophy Hall with a 24-second custodian routine (polish the pedestal → duck behind the case → rappel upside-down to buff the top shelf → scrub the mirror → startled by his reflection → bolt out the mouse hole → peek from the side doorway → stroll back); Goals Alcove (shorter, hauler on a ledge).
- **Interconnected life:** catwalk bridges with doorways across the shaft (Outfitter ↔ Lab, Kitchen ↔ Trophy Hall) with commuting squirrels, the seed rope lift, and deck and ground skaters year-round. **Winter theme** (Frostline, or Seasonal Foliage in real winter): jackets and knit beanies colony-wide, snow on the mound and deck, wooden sleds and a snowball fight.
- The central lift now runs Canopy Terrace → 3 trunk floors → **root concourse** and ends there (it no longer drops into the Metro).

### 2.5 Live DC Metro & Capitals fans
- The LED board cycles a real stop on every train (arrive → doors open, one rider off, one on → depart): Red Line Shady Grove → Gallery Place, Orange/Silver Metro Center → Ballston-MU and back, then the Red Line home, looping. The line pill and the car stripe use the line color.
- Rush-Hour Worker Flood: 7 commuters and 9-second train cycles for 3h.
- Trains departing **Gallery Place** and **Metro Center** leave three Caps fans (red jersey, scarf, red-and-navy beanie, one waving a flag) cheering on the platform until the next train. Flag drop-in: `assets/images/metro/custom_caps_flag.png`.

### Decisions & deviations (please review)
1. **The new places are rooms:** Bird Feeder, Scavenger Burrow and Deep-Root Hearth are `RoomKey`s, so they get tap hotspots, camera glides, drawer pages, themes and PNG slots. The drawer now has 18 pages, and **Window Shopper needs all 18**.
2. "Liquid cash" for the waterline is **Free Cash** (checking − goal allocations), the same base as the Frostline.
3. Overflow Acorns flow into the Granary **automatically** when room opens (no manual "haul in" tap).
4. The 2nd squad only allows a second dispatch while hired; a squad already out finishes even if the hire expires.
5. Lures boost visits but **need seed in the feeder**. One lure at a time; buying the same lure again stacks its time (except Moonlight Oil).
6. No Golden Acorn reward on keepsake unlock (only the keepsake was asked for). Easy to add.
7. The focus multiplier "Warm Hearth" is renamed **Focus Warmth** in the Focus drawer to avoid confusion with the Deep-Root Hearth (same setting, same behavior).
8. Room art is still procedural at every theme level; custom PNGs replace it per room as before.

---

## 3. Current Folder Tree
```text
squirrel-stash/
├── CLAUDE.md  STATUS.md  README.md
├── pubspec.yaml / pubspec.lock / analysis_options.yaml
├── android/ ios/ macos/ windows/  web/ (dev preview)
├── assets/
│   ├── audio/        plink.wav            (+ optional ambient_piano.wav drop-in)
│   ├── fonts/        Fredoka-* Nunito-* (+ OFL licenses)
│   ├── images/
│   │   ├── icons/      icons_template.json      (acorn.png, golden_acorn.png, <room>.png)
│   │   ├── props/      props_manifest.json      (chest_lv1..3.png)
│   │   ├── rooms/      rooms_template.json      (<room>.png interiors, v1.2 boxes for all 18 rooms)
│   │   ├── outfitter/  outfitter_manifest.json  (custom_pokemon_card / custom_film_canister / custom_skate_deck .png)
│   │   └── metro/      metro_manifest.json      (custom_caps_flag.png)
│   └── sprites/squirrels/ squirrels.json
├── docs/screenshots/ 01_great_oak 02_max_unlocked 03_frost 04_cozy_zen 05_zoom_trunk 06_zoom_roots
│                     07_lab_drawer 08_billVault_drawer 09_trophyHall_drawer 10_kitchen_drawer 11_metro_drawer
│                     12_brokerage_drawer 13_outfitter_drawer 14_colony_shop 15_lab_drawer_expanded
│                     16_settings_drawer 17_birdFeeder_drawer 18_burrow_drawer 19_hearth_drawer 20_logbook
│                     21_hearth_dark 22_zoom_canopy 23_zoom_outfitter 24_zoom_burrow 25_zoom_metro
│                     26_vault_low_water 27_vault_mid_water 28_zoom_trunk_max
├── lib/
│   ├── main.dart  app.dart
│   ├── core/       audio_service backup_files dates haptics ids market_price_service money streaks
│   ├── database/   backup_codec desktop_db_factory desktop_db_factory_ffi desktop_db_factory_stub
│   │               memory_stash_repository schema seed_colony seed_data seed_history
│   │               sqlite_stash_repository stash_database stash_repository
│   ├── models/     app_settings bill (+BillStatement) bird (SeedKind, BirdSpecies, LureKind, BirdLogEntry)
│   │               colony_economy colony_state decor expedition feat focus_state goal grocery_trip
│   │               habit holding impulse metro_ride room stash_snapshot treat_status trinket trophy
│   ├── providers/  art_assets_provider awards_provider bills_provider card_insights clock_provider
│   │               colony_actions colony_math (+BirdSim) colony_provider diorama_snapshot_provider
│   │               economy feat_engine finance_math finance_providers focus_provider goals_provider
│   │               impulse_provider kitchen_metro_math kitchen_metro_provider repository_providers
│   │               reserves_provider reward_service room_summary_provider rooms_provider
│   │               settings_provider stash_actions stats_engine ui_provider willpower_actions
│   ├── game/
│   │   ├── stash_diorama_game.dart  layout.dart  diorama_snapshot.dart  diorama_event.dart
│   │   ├── art/         asset_manifest bird_painter paint_kit palette skate_kit squirrel_gear
│   │   │                squirrel_outfits squirrel_painter
│   │   ├── components/  canopy_layer canopy_residents catwalks_layer colony_life_layer diorama_layer
│   │   │                fx_layer pulley_lift rooms_layer sky_earth_layer trunk_layer weather_layer
│   │   └── rooms/       bill_vault_art bird_feeder_art burrow_art custodian hearth_art holiday_tree
│   │                    kitchen_art lab_goals_art metro_art metro_lines outfitter_art outfitter_props
│   │                    pocket_art room_kit treasury_art trophy_hall_art waterline_scenes
│   ├── theme/      app_colors app_theme app_typography
│   └── ui/
│       ├── home_study_screen.dart
│       ├── diorama/    blueprint_overlay room_hotspots tap_zone tree_stage
│       ├── drawers/    backup_section bills_drawer bird_feeder_drawer bird_logbook_view burrow_drawer
│       │               card_insights_view colony_cards colony_tiles decor_shop drawer_shell drawers
│       │               etch_board focus_drawer goal_detail_drawer goals_drawer habit_editor half_sheet
│       │               hearth_drawer holding_editor kitchen_drawer lab_drawer lab_sections metro_drawer
│       │               new_goal_drawer outfitter_drawer prompts reclaim_celebration reserve_drawer
│       │               room_drawer settings_drawer stats_dashboard treasury_drawer trophies_drawer
│       └── widgets/    acorn_icons animated_money celebration_banner frost_vignette room_icons
│                       stash_controls study_hud_pill
├── test/  backup_codec_test colony_test finance_math_test insights_and_feats_test
│          market_price_service_test sqlite_repository_test stash_actions_test home_screen_test
│          helpers/test_harness screenshot/render_screenshots_test
└── tool/  generate_audio.dart  create_release_key.sh
```
All 158 `lib/` files are under the 300-line target (largest: `study_hud_pill.dart` 279, `colony_tiles.dart` 263, `squirrel_painter.dart` 261).

**SQLite v3 tables:** `settings`, `bills`, `bill_statements`, `goals`, `trophies`, `impulse_chips`, `impulse_logs`, `holdings`, `decor` (every look owned since v3), `grocery_trips`, `metro_rides`, `trophy_awards`, **`expeditions`** (id, route, started_at, ends_at, acorns, collected_at), **`seed_bags`** (seed, bags), **`bird_log`** (species, visits, first_seen, last_seen, lure_tally).

**New settings keys:** `acorns_overflow`, `granary_level`, `hearth_level`, `hearth_fuel_until`, `overdrive_until`, `festival_until`, `rush_hour_until`, `second_squad_until`, `collector_progress`, `collector_checked_at`, `extra_pedestals`, `feeder_seed`, `feeder_until`, `lure`, `lure_until`, `bird_checked_at`, `recent_visitors`, plus `room_lv_birdFeeder`, `room_lv_burrow` and `room_lv_hearth`.

**Custom art and audio drop-ins (rebuild after adding):** `assets/images/rooms/<room>.png` (now including `birdFeeder`, `burrow` and `hearth`), `assets/images/outfitter/custom_pokemon_card.png`, `custom_film_canister.png`, `custom_skate_deck.png`, `assets/images/metro/custom_caps_flag.png` and `assets/audio/ambient_piano.wav`, plus the v1.1 icon, prop and sprite slots.

---

## 4. Known Issues / Next Recommended Steps
1. **Hands-on test of v1.2 on the Pixel** (installed 2026-11-27). Check that audio pauses when the app is backgrounded or the shade is pulled down (no piano file ships, so test with a temporary `ambient_piano.wav`), frame rate with the new layers while zoomed, the tap target of the acorn bubbles at 1.0x (they appear as the collector fills, about one per 1.6h with the Hearth lit), and how the 18-page drawer feels.
2. **The colony settles on launch, every 20s and on resume**, so a squad that returns while the app is closed is announced on the next open. There are no OS notifications.
3. The **pedestal row** in the Outfitter drawer squeezes 6 tiles into one row on narrow phones.
4. **Bird visits ignore the Hearth**: wild birds still come while the colony sleeps (by design; not checked on device).
5. The procedural art is still placeholder (the burrow alcove is plain, birds are tiny at 1.0x, disco spots are subtle). **Next: v2.0 (replaces the planned v1.3)** redoes all the graphics with custom art modeled on Fallout Shelter: in-depth rooms in a 2.5D dollhouse cutaway with edge-to-edge interior PNGs. Per-room boxes are in `rooms_template.json`, and the drawing order already lets squirrels, birds, trains and effects animate over a custom PNG.
6. Carried over: the Privacy Eye doesn't mask plain text in drawers; Focus Shifts are all-time only in stats; habit and trophy icons are still emoji; backups are manual and unencrypted; import is untested on device; consider `applicationIdSuffix ".debug"` so debug builds can install beside the release app.
