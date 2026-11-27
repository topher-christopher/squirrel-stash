# STATUS.md — SquirrelStash Sync Ledger

**Last Updated:** 2026-11-26 — v1 verification pass (Claude Code)
**Active Phase:** v1 verified (analyze, tests, live web preview) → next: on-device Android testing & custom art
**Stack:** Flutter 3.50.1 (Dart 3.14) + Flame 1.38 + SQLite (sqflite) + Riverpod 3.5

---

## 1. Tech Stack & Build Status

| Concern | Package | Notes |
|---|---|---|
| UI framework | Flutter 3.50.1 stable, `material_ui` 1.x | Flutter ≥3.47 moved Material out of the SDK: import `package:material_ui/material_ui.dart`, **not** `package:flutter/material.dart` (deprecated). |
| 2D diorama | `flame` ^1.38.2 | One `FlameGame` in a fixed 440 × 820 world (the blueprint's viewBox), scaled to fit. |
| State | `flutter_riverpod` ^3.5.0 | `Notifier`/`Provider` only (no codegen, no legacy providers). |
| Persistence | `sqflite` ^2.4.6 (+ `sqflite_common_ffi` for Windows/Linux & host tests) | Money stored as **integer cents**. `package:sqlite3` build hook uses the OS SQLite on Android/iOS/macOS (nothing downloaded or bundled); Windows/Linux fetch a checksum-verified binary at build time. |
| Audio | `audioplayers` ^6.8.1 | Ambient loops mix with the user's own music (`mixWithOthers`). Stems are procedurally generated (see `tool/`). |
| Formatting | `intl` ^0.20.3 | Currency and dates. |
| Fonts | Fredoka + Nunito (bundled variable TTFs, SIL OFL) | Offline; licenses in `assets/fonts/`. |

**Verified on this Mac (Intel, macOS 14.7) — v1 verification pass:**
- `flutter pub get` ✅
- `flutter analyze` ✅ **No issues found** (0 errors, 0 warnings, 0 infos)
- `flutter test` ✅ **40/40 passing**: 18 formula tests, 11 provider/action flow tests, 2 real-SQLite round-trip tests, 1 widget interaction test, 8 screenshot renders
- `flutter devices` → **Chrome (web)** and **macOS (desktop)**; no Android emulator (Android Studio not installed). The macOS target can't build without full Xcode.
- `flutter build web --release` ✅ (Wasm dry run also passes). **Live preview verified:** the app ran in a Chromium browser pane with the diorama animating, drawers opening and emoji rendering, and no runtime errors in the console.
- **Not yet run on an Android device or emulator**, so no APK/IPA/macOS build has been produced.

> **Web is a dev-preview target only** (`web/` exists so the app can be clicked through without an emulator). It renders through Flutter's canvas engine, not HTML/DOM, so CLAUDE.md's no-web-wrapper rule still holds for the shipped app. sqflite has no web driver, so the **web preview runs on an in-memory demo stash that resets on reload**. Android/iOS/macOS/Windows use SQLite.

### How to run locally
```bash
# Flutter lives at ~/development/flutter (not on PATH by default)
export PATH="$HOME/development/flutter/bin:$PATH"

flutter pub get
flutter analyze
flutter test                        # full suite (incl. screenshots)
flutter test test/screenshot        # re-render docs/screenshots/*.png
dart run tool/generate_audio.dart   # regenerate assets/audio/*.wav

# Live preview in Chrome (no emulator needed) — either:
flutter run -d chrome               # debug, with hot reload (press r / R)
# …or a release build served locally (smoother 60fps):
flutter build web --release
python3 -m http.server 8742 --directory build/web   # open http://localhost:8742

# Android (first target) — needs Android Studio (SDK + emulator) once:
flutter doctor --android-licenses
flutter devices
flutter run -d <android-device-id>
flutter build apk --release
```
iOS/macOS additionally need full Xcode + CocoaPods. Windows needs a Windows host with Visual Studio.

---

## 2. Completed Features (all blueprint features ported)

**1-Screen Hollow Oak Study (Flame, 60fps)**
- Carved arched window that **cross-fades** between three animated scenes: **Meadow** (Great Oak, swaying canopy, Professor Hoot, hammock napper, acorn-tossing stump squirrel, drifting leaves), **Alpine** (looping twin gondolas, carving skier squirrel with powder trail, river tubers), **Harbor** (sweeping lighthouse beam, sea lions, gulls, sailboat, fishing squirrel, rising tide).
- Free Cash **Acorn Pile** (4–15 acorns, one per $400) that grows acorn by acorn with a bounce; **Bills Campfire** with flicker, embers and the tea-sipping squirrel.
- **Winter Frostline:** when unpaid bills > free cash, crystals creep across the panes, snow falls, the canopy and ground frost over, squirrels wear scarves, and a full-screen icy vignette with corner dendrites fades in.
- **Payday sprint:** three acorn-carrying runners (one golden) plus sparkle bursts.
- **Great Oak upgrades** visible outside: Lv.1 lantern → Lv.2 twin lanterns → Lv.3 festival bunting → Lv.4 golden lanterns + golden chute hauler.
- **Twilight Firefly Window** decor (stars, moon, fireflies, darker landscape) and **Fairy Lights** decor (garland draped across the arch).
- Every tappable object squash-bounces on tap (`DioramaEvent.poke`) with haptics.

**Desk instruments**
- **Sand-Art Impulse Silo:** Sky-Blue skips / Mint-Emerald downsizes / Honey-Gold DIY layers animate to the month mix; forged **Silver ($25)** and **Royal Gold ($100)** acorns stack beside it; researcher squirrel in a chef hat.
- **Green / Yellow / Red Treat-Yourself lantern** (exact thresholds: frost → red; no goals or ≥45% average → green; else yellow).
- **Brass twin-bell Focus clock** (real local time when idle; progress sector + ticking second hand during a shift); study squirrel with a book while focusing; **Desk Espresso Press** decor.
- **Trophy shelf** with the two latest relics.

**Root cellar**
- Paginated (‹ ›) **Goal Chambers** that evolve Lv.1 Dirt Alcove → Lv.2 Timber Chamber (≥35%) → Lv.3 Gold Treasury (100%), with a chest, progress meter and priority glow; dashed **Dig New Goal Room** slot.
- **Reclaim & Upgrade:** confetti, then a celebration card that types out the **Time-Capsule note**, places the relic, adds +25 Golden Leaves and grows the oak.
- Brass chute and ladder **hauler** (down with an acorn, back up empty); allocations drop an acorn down the chute into the chamber's chest.
- **Amber Reserve** (glowing crystals and honey jar, `balance × APY / 365` daily yield), **Curio Vault** (holographic slab and silver bars), **Deep Treasury** (gold hoard and sleeping crowned Golden Elder); lantern-carrying root caretaker on patrol.

**HUD & drawers (Flutter)**
- Floating HUD pill: animated Free Cash, Total Stash (wide screens), +Payday, scene switcher, custom-art blueprint toggle, settings, **Zen Mode** (fades every label and number; the pill collapses to the eye).
- Slide-up drawers: **Cash**, **Bills/Frostline**, **Foraging & Alchemy Lab** (1-tap chips, Smart Downsize Calculator, custom chips, Sweep to Goal, recent wins with swipe-to-undo), **Focus Shift** (10s demo / 15 / 25 / 45 / 60m, pause/resume/reset, campfire or forest-breeze audio, Warm Hearth 1.0x→1.25x→1.5x, Golden Leaf decor shop), **Trophies & Oak level**, **New Goal**, **Goal Detail**, **Reserve detail** (holdings, quick deposits, editable APY), **Settings**.
- Celebration toasts, count-up money tickers, press-scale on every button, haptics vocabulary (`lib/core/haptics.dart`).

**Persistence & art pipeline**
- SQLite schema with migration hook (`lib/database/schema.dart`); demo hollow seeded on first launch; "Restore demo" and "Start fresh" in Settings.
- **Custom art drop-in** (`StashAssetManifest`): PNGs placed in `assets/images/windows/`, `assets/images/props/` or `assets/sprites/squirrels/` automatically replace the procedural art. Templates: `custom_window_template.json`, `props_manifest.json`, `squirrels.json`.

### Intentional deviations from GEMINI_PROTOTYPE.txt (please review)
1. **Sweep to Goal** moves only *unswept* wins from this month, as whole wins in exact cents, into any chamber (priority first). The prototype re-swept the same monthly total every tap and only offered `goals[0]`.
2. **Decor ownership** is separate from visibility. In the prototype, toggling an item off made it purchasable again (a double-charge bug).
3. **Professor Hoot** gifts +15 leaves **once per day** (the prototype allowed once per session).
4. **Espresso Press** decor now renders on the desk (the prototype defined it but never drew it).
5. **Impulse horizons** (month/year/all-time) come from real log dates instead of static tags.
6. **Focus timer** is wall-clock based and survives backgrounding and restarts; added Resume/Reset and the 60m preset from CLAUDE.md.
7. **Additions beyond the prototype:** add/edit/delete bills with real due dates; custom allocation, "Return acorns" and "Fill in chamber" for goals; reserve holdings as line items with editable APY; editable payday amount; real date pickers.
8. Toggling a bill paid still does **not** change checking (prototype parity: checking mirrors the bank balance).

---

## 3. Current Folder Tree
```text
squirrel-stash/
├── CLAUDE.md
├── STATUS.md
├── GEMINI_PROTOTYPE.txt
├── README.md
├── pubspec.yaml / pubspec.lock / analysis_options.yaml
├── android/ ios/ macos/ windows/        # Flutter platform runners (app label "SquirrelStash")
├── web/                                 # dev-preview target only (index.html, manifest.json, icons/)
├── assets/
│   ├── audio/
│   │   ├── campfire.wav
│   │   ├── chime.wav
│   │   ├── forest_breeze.wav
│   │   └── plink.wav
│   ├── fonts/
│   │   ├── Fredoka-OFL.txt
│   │   ├── Fredoka-Variable.ttf
│   │   ├── Nunito-OFL.txt
│   │   └── Nunito-Variable.ttf
│   ├── images/
│   │   ├── props/
│   │   │   └── props_manifest.json
│   │   └── windows/
│   │       └── custom_window_template.json
│   └── sprites/
│       └── squirrels/
│           └── squirrels.json
├── docs/
│   └── screenshots/                       # rendered by `flutter test test/screenshot`
│       ├── 01_meadow.png
│       ├── 02_frost.png
│       ├── 03_alpine_twilight.png
│       ├── 04_harbor.png
│       ├── 05_zen.png
│       ├── 06_lab_drawer.png
│       ├── 07_focus_drawer.png
│       └── 08_goal_drawer.png
├── lib/
│   ├── main.dart                          # opens SQLite, seeds, ProviderScope overrides
│   ├── app.dart
│   ├── core/
│   │   ├── audio_service.dart
│   │   ├── dates.dart
│   │   ├── haptics.dart
│   │   ├── ids.dart
│   │   └── money.dart
│   ├── database/
│   │   ├── desktop_db_factory.dart        # conditional import: FFI on Windows/Linux, stub on web
│   │   ├── desktop_db_factory_ffi.dart
│   │   ├── desktop_db_factory_stub.dart
│   │   ├── memory_stash_repository.dart
│   │   ├── schema.dart
│   │   ├── seed_data.dart
│   │   ├── sqlite_stash_repository.dart
│   │   ├── stash_database.dart
│   │   └── stash_repository.dart
│   ├── game/
│   │   ├── diorama_event.dart
│   │   ├── diorama_snapshot.dart
│   │   ├── layout.dart                    # all world coordinates & hotspots
│   │   ├── stash_diorama_game.dart
│   │   ├── art/
│   │   │   ├── asset_manifest.dart        # custom PNG drop-in registry
│   │   │   ├── paint_kit.dart
│   │   │   ├── palette.dart
│   │   │   └── squirrel_painter.dart
│   │   ├── components/
│   │   │   ├── cellar_critters.dart
│   │   │   ├── cellar_layer.dart
│   │   │   ├── desk_clock.dart
│   │   │   ├── desk_instruments.dart
│   │   │   ├── desk_layer.dart
│   │   │   ├── diorama_layer.dart
│   │   │   ├── fairy_lights.dart
│   │   │   ├── fx_layer.dart
│   │   │   ├── goal_chambers.dart
│   │   │   ├── root_reserves.dart
│   │   │   ├── study_wall.dart
│   │   │   ├── window_frame.dart
│   │   │   └── window_view.dart
│   │   └── scenes/
│   │       ├── alpine_scene.dart
│   │       ├── harbor_scene.dart
│   │       ├── meadow_scene.dart
│   │       ├── professor_hoot.dart
│   │       ├── scene_art.dart
│   │       ├── sky_painter.dart
│   │       ├── window_props.dart
│   │       └── window_weather.dart
│   ├── models/
│   │   ├── app_settings.dart
│   │   ├── bill.dart
│   │   ├── decor.dart
│   │   ├── focus_state.dart
│   │   ├── goal.dart
│   │   ├── holding.dart
│   │   ├── impulse.dart
│   │   ├── stash_snapshot.dart
│   │   ├── treat_status.dart
│   │   ├── trophy.dart
│   │   └── window_scene.dart
│   ├── providers/
│   │   ├── bills_provider.dart
│   │   ├── diorama_snapshot_provider.dart
│   │   ├── finance_math.dart              # pure blueprint formulas (unit-tested)
│   │   ├── finance_providers.dart
│   │   ├── focus_provider.dart
│   │   ├── goals_provider.dart
│   │   ├── impulse_provider.dart
│   │   ├── repository_providers.dart
│   │   ├── reserves_provider.dart
│   │   ├── settings_provider.dart
│   │   ├── stash_actions.dart             # cross-domain actions + feedback
│   │   └── ui_provider.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   └── app_typography.dart
│   └── ui/
│       ├── home_study_screen.dart
│       ├── diorama/
│       │   ├── blueprint_overlay.dart
│       │   ├── cellar_plaques.dart
│       │   ├── desk_plaques.dart
│       │   ├── diorama_stage.dart
│       │   ├── tap_zone.dart
│       │   └── window_plaques.dart
│       ├── drawers/
│       │   ├── bills_drawer.dart
│       │   ├── cash_drawer.dart
│       │   ├── decor_shop.dart
│       │   ├── drawer_shell.dart
│       │   ├── drawers.dart
│       │   ├── focus_drawer.dart
│       │   ├── goal_detail_drawer.dart
│       │   ├── lab_drawer.dart
│       │   ├── lab_sections.dart
│       │   ├── new_goal_drawer.dart
│       │   ├── prompts.dart
│       │   ├── reclaim_celebration.dart
│       │   ├── reserve_drawer.dart
│       │   ├── settings_drawer.dart
│       │   └── trophies_drawer.dart
│       └── widgets/
│           ├── animated_money.dart
│           ├── celebration_banner.dart
│           ├── frost_vignette.dart
│           ├── stash_controls.dart
│           └── study_hud_pill.dart
├── test/
│   ├── finance_math_test.dart
│   ├── home_screen_test.dart
│   ├── sqlite_repository_test.dart
│   ├── stash_actions_test.dart
│   ├── helpers/
│   │   └── test_harness.dart
│   └── screenshot/
│       └── render_screenshots_test.dart
└── tool/
    └── generate_audio.dart
```
All 98 `lib/` files are under the 300-line target (largest: `providers/stash_actions.dart` at 297, `game/art/squirrel_painter.dart` at 293; split these first if they grow).

---

## 4. Known Issues / Next Recommended Steps
1. **Run on a real Android device or emulator.** Install Android Studio (SDK + emulator), run `flutter doctor`, then `flutter run`. Untested on device so far: audio playback, haptics, frame rate on low-end phones, safe-area/edge-to-edge insets, and the keyboard over drawers.
2. **Small plaque text on phones.** Desk plaques use 8–9 world units, about 7–8pt on a 390pt-wide phone. Consider a larger-type setting or a slightly taller desk band.
3. **Tall and landscape screens.** The diorama keeps its 440 × 820 aspect, leaving about 90pt of unused height on tall phones and pillarboxing on tablets. A landscape/tablet layout (diorama plus a side drawer panel) would use the space.
4. **Recurring bills.** Bills don't auto-roll each month; "paid" stays manual. Proposal: a monthly flag that resets paid and advances the due date.
5. **Warm Hearth never cools** (prototype parity). Decide whether a gentle, non-punitive decay is wanted.
6. **Rare visitors.** Professor Hoot always perches in the Meadow (gift once a day). A spawn schedule and more visitors are open.
7. **Custom art.** The PNG and sprite-sheet drop-in code paths work but are untested with real art. Frost is procedural Canvas art (no GLSL shader yet).
8. **Audio stems** are procedural placeholders. Swap in recorded `.ogg`/`.wav` with the same filenames whenever ready.
9. Emoji (goal icons, chips) render with each platform's system emoji font, so they look different on Android, iOS, and Windows.
10. The first Windows build downloads SQLite via the `sqlite3` build hook, so it needs network access.
11. **Web preview quirks:** data is in-memory and resets on reload; emoji show as boxes for the first second while Flutter fetches its emoji font from Google Fonts; the console logs a harmless "Could not find a set of Noto fonts" warning (invisible emoji modifier characters).
12. `.claude/launch.json` (local preview config) is git-ignored because it holds machine-specific paths.
