# STATUS.md — SquirrelStash Sync Ledger

**Last Updated:** 2026-11-27 — manual backup & restore (Claude Code); before that, v1.1 Great Oak upgrade + icon-free tree pass
**Active Phase:** v1.1 built and verified (analyze, 65 tests, screenshot review, web build, physical Pixel 9 Pro XL) → next: on-device Android test of live prices, zoom performance and custom art
**Stack:** Flutter 3.50.1 (Dart 3.14) + Flame 1.38 + SQLite (sqflite, schema v2) + Riverpod 3.5 + http 1.6 + share_plus 13 + file_picker 13

---

## 1. Tech Stack & Build Status

| Concern | Package | Notes |
|---|---|---|
| UI framework | Flutter 3.50.1 stable, `material_ui` 1.x | Import `package:material_ui/material_ui.dart`, **not** `package:flutter/material.dart`. |
| 2D Great Oak | `flame` ^1.38.2 | One `FlameGame` in a fixed **600 × 1150** world, inside an `InteractiveViewer` (1.0x–2.8x). |
| State | `flutter_riverpod` ^3.5.0 | `Notifier`/`Provider` only (no codegen). |
| Persistence | `sqflite` ^2.4.6 (+ `sqflite_common_ffi`) | **Schema v2** with a tested v1 → v2 migration. Money is integer cents; per-unit market prices are REAL dollars. |
| Live prices | `http` ^1.6.0 | CoinGecko `/api/v3/simple/price` (crypto) + Yahoo Finance chart JSON (stocks, ETFs, ESPP, silver `SI=F`). No API keys. Prices are cached on each holding for offline use. |
| Audio | `audioplayers` ^6.8.1 | Procedural stems in `assets/audio/` (see `tool/`). |
| Formatting | `intl` ^0.20.3 | Currency and dates. |
| Backup export | `share_plus` ^13.3.1 | Share sheet for the backup JSON (Drive, Files, email). Needs AGP ≥ 8.12 / Kotlin 2.2 / Java 17 (we have AGP 9.3, Kotlin 2.4). |
| Backup save / import | `file_picker` ^13.4.1 | `FilePicker.saveFile` (system save dialog) and `FilePicker.pickFile`. macOS needs `com.apple.security.files.user-selected.read-write`, now in both entitlements files. |
| Fonts | Fredoka + Nunito (bundled, SIL OFL) | They lack glyphs such as ▲ ↻ ✎ ● ✓ (render as boxes). Use Material Icons or ASCII. |

**Verified on this Mac (Intel, macOS 14.7) and a physical Pixel 9 Pro XL (Android 16) in this session:**
- `flutter analyze` ✅ **No issues found**
- `flutter test` ✅ **78/78 passing**: 16 finance/date/economy tests, 13 card-insight, trophy, kitchen/metro and stats tests, 2 live-price parser tests (mocked HTTP), 4 SQLite tests (incl. the v1 → v2 migration and fresh-install seeding), **12 backup codec tests** (round trip, SQLite restore, provider replace, malformed and newer-version rejection), 14 provider/action flow tests, 1 widget test (HUD → tap room → camera glide → half-height drawer → drag to full and back → log win → swipe rooms), 16 screenshot renders
- `flutter build web --release` ✅
- **Backup on the Pixel (release APK, installed in place with `adb install -r`, data kept):** the Backup & restore section renders. **Export** opens the share sheet with `squirrelstash-backup-YYYY-MM-DD.json` (Drive is listed). **Save backup to Files** wrote a 61 KB file to Downloads and showed the inline "Backup saved" line. **Import was not tried on the device** (it's covered by unit tests only). Don't use `flutter run` to update a phone that holds real data: if the install fails, it uninstalls the app and wipes the stash.
- **Runs on a physical Pixel 9 Pro XL** over USB (debug build in about 1 minute, Impeller/Vulkan; release build via `flutter run --release`). The Pixel 9 Pro XL **emulator** is too slow on this Intel Mac: the debug build never got past the splash. **Live prices are only tested against mocked responses** so far.
- **Fixed:** `android.permission.INTERNET` was only in the debug manifest, so release builds couldn't fetch live prices. It's now in `android/app/src/main/AndroidManifest.xml`.

### How to run locally
```bash
export PATH="$HOME/development/flutter/bin:$PATH"   # Flutter is not on PATH by default
flutter pub get
flutter analyze
flutter test                        # full suite (incl. screenshots)
flutter test test/screenshot        # re-render docs/screenshots/*.png
flutter run -d chrome               # dev preview (in-memory demo, offline prices)
flutter build web --release && python3 -m http.server 8742 --directory build/web
# Android (first target), once Android Studio is installed:
flutter doctor --android-licenses && flutter run -d <android-device-id>
```
> Web is a dev preview only (canvas renderer, not DOM). It runs on an in-memory demo stash and the **offline** price service (browser CORS blocks Yahoo).

---

## 2. Completed Features & Recent Changes (v1.1)

**Permanent Android release signing**
- `bash tool/create_release_key.sh` (interactive, run once) creates `~/keystores/squirrelstash-release.jks` (PKCS12, RSA 4096, alias `squirrelstash`) outside the repo and writes `android/key.properties`. With an existing keystore (restored from backup) it only recreates `key.properties`.
- `android/app/build.gradle.kts` signs release builds with that key. There is **no debug-key fallback**: without `key.properties`, release builds fail with a clear message; debug builds are unaffected.
- `*.jks`, `*.keystore` and `key.properties` are ignored in both `.gitignore` and `android/.gitignore`.
- **Status:** keystore created (2026-11-27) and `build/app/outputs/flutter-apk/app-release.apk` built and verified with `apksigner` (v2 scheme, `CN=SquirrelStash`, SHA-256 `cb24a6256ca0e80c3b780dd2938503525ba76e514ccf3044a3996b495eecaf2d`). **Installed on the Pixel 9 Pro XL** (2026-11-27, one-time uninstall; it launches and the installed signature matches).

**Backup & restore (new, Settings → "Backup & restore")**: protects real data across reinstalls or a signing-key change, since the stash lives only in on-device SQLite.
- **Format** (`database/backup_codec.dart`): one JSON file, `squirrelstash-backup-YYYY-MM-DD.json`, shaped `{format: "squirrelstash-backup", formatVersion: 1, schemaVersion: 2, exportedAt, tables: {settings, bills, statements, goals, trophies, habits, logs, holdings, decor, groceries, rides, awards}}`. Rows are each model's SQLite `toMap()`, so the file mirrors the schema exactly (cents as ints, prices as doubles, dates as ISO-8601).
- **Versioning:** a newer `formatVersion` or `schemaVersion` is rejected with "made by a newer version of SquirrelStash, update the app". When the schema moves to v3, add a row-map upgrade under `BackupCodec._upgrades[3]` so v2 backups still restore.
- **Validation:** not JSON, not a backup, missing versions, a damaged table, a bad row (missing id, wrong type, unparseable date) or non-string settings all raise `BackupFormatException` with a friendly message naming the table and row. Retired decor keys are skipped, as in `loadAll()`.
- **Export** (`core/backup_files.dart`): reads `repository.loadAll()`, writes the file to the temp folder and opens the share sheet (`📤 Export backup`). On Android and desktop a second button (`💾 Save backup to Files`) opens the system save dialog, which can save straight to Downloads or Google Drive. iOS skips it because its share sheet already has "Save to Files".
- **Import** (`📥 Import backup`): pick any file (no MIME filter, because Drive often reports .json under other types), decode and validate it, then confirm with the export date and counts ("14 holdings · 230 wins · 6 bills · …"). Restoring calls `stashSnapshotProvider.notifier.replace(snapshot)`, which rewrites SQLite in one transaction, so a failed restore leaves the stash untouched. Results and errors show inline under the buttons, because a SnackBar would sit behind the modal sheet.

**Unified zoomable Great Oak** (replaces the split window + desk + cellar layout)
- One continuous cutaway: sunlit **canopy** (swaying crown, limbs, Professor Hoot, hammock napper, birdhouse beacon, fairy lights, branch runners) → **trunk** (six rooms on three floors around a **central acorn-pulley lift** that loops to the Metro platform) → grassy **terrace** with 4 **Display Pedestals** → **root tunnels** (DC Metro + 7 vault pockets).
- `InteractiveViewer` (min 1.0x, max 2.8x) plus a floating **Reset Zoom** chip.
- **No icons or floating labels on the tree** (changed after review): zoomed out you see only the rooms and the squirrels working. Each room's name is **carved subtly into the front edge of its floor plank** (the Metro gets a WMATA-style station name plate). It reads when zoomed in and recedes when zoomed out. Zooming past 1.12x→1.3x fades in extra interior animations (`game.detail`). **Tapping a room** glides the camera to it (parked in the upper 20% of the screen) and opens its drawer, whose header shows the room name **and its headline total** (Free Cash, unpaid bills, vault value…).
- Falling leaves (seasonal colors), Frostline snow, frosted crown and scarves, twilight fireflies, and the full-screen frost vignette.

**Top HUD** (`study_hud_pill.dart`, collapsible): Free Cash, Total Stash, custom **Acorn** and **Golden Acorn** counters (tap them to open the upgrade shop), `+Payday`, the **Focus quick-pill** (live countdown; there is no Focus room), the **Starter / Max** room preview switch, the **Privacy Eye** (masks amounts on the HUD, tree plaques and animated totals), **Cozy Zen** (hides all chrome and icons, leaving a faint leaf to exit) and Settings. The scene switcher is gone.

**Acorn art hooks** (`acorn_icons.dart`): `AcornIcon` and `GoldenAcornIcon` are custom painters. A PNG at `assets/images/icons/acorn.png` or `golden_acorn.png` replaces them automatically. Room medallions (used only in drawers and upgrade cards now) accept `assets/images/icons/<room>.png`.

**Swipeable room drawer** (`room_drawer.dart` + `half_sheet.dart`): it **opens at half height** over a light backdrop, so the zoomed room stays visible above it. Drag the header up to fill the screen, drag it down to return to half (or further to close), or tap the grab handle to toggle. Content scrolls at either height. A `PageView` covers all 15 rooms in natural order, with an icon pill bar and dots at the top. The tree camera follows each swipe, and deep rooms (Metro, vault pockets) are lifted above the sheet, then settle back when it closes. Every room ends with a **Room Upgrade** card.

**Hero rooms**
- **Acorn Outfitter:** Borrower-scale trinkets (film-canister barrels, framed giant Pokémon card, booster-box bench, button rug, thumbtack café table, bottle-cap firepit, thimble moss planter, skateboard-wheel ottoman, sneaker daybed, copper penny gong) that unlock as the room levels up. Tap any trinket for a humorous **Field Note**. Also holds the colony wardrobe (knight helm, beanie, aviator goggles, banker's visor) and the **Display Pedestal** picker (statues, earned feats, trinkets).
- **Trophy Hall:** shelves fill with earned trophies and overflow into boxes; goal statues stand in a glass case; a curator squirrel dusts. The drawer holds the stats ledger and every trophy.
- **Squirrel Kitchen:** stove, steaming pots and chef squirrels. Neutral grocery tracking (store, amount, optional item count) with month/year totals, trip count, average per trip, average days between trips, and a Home-Cooked Meal counter and streak.
- **DC Metro Station:** coffered vault ceiling, a looping train, commuters in suits with briefcases, plus a skateboarder and a cyclist. 1-tap fares: **Short Hop $2.25 / Weekend Max $2.50 / Weekday Max $6.75 / Custom**, ride counts, a per-fare breakdown and a shortcut to log a walked or biked hop.

**Medium rooms:** **Canopy Treasury** (Free Cash pile, payday sprint, Treat Yourself lantern, cash tools), **Foraging & Willpower Lab** (sand silo), **Hollow Log Bill Vault** (safety waterline + Etch A Sketch), **Goal Chambers** (up to 3 chests + dig slot; each sealed goal becomes a statue).
**Seven equal vault pockets:** Brokerage, Pokémon Gallery, Crypto Cavern, ESPP, HYSA & Savings, Retirement Vault (sleeping Golden Elder), Silver Alcove (mining squirrel).

**Hollow Log Bill Vault**
- Presets: **TD Cash (1st), Capital One Quicksilver (9th), Chase Amazon (12th), Chase Southwest Rapid Rewards (28th)** as variable-balance cards, plus fixed **Monthly Rent**. "Start fresh" keeps these presets with empty amounts.
- Recurring bills (`dueDay`) **roll to the next month automatically** once paid and past due. This fixes v1 known issue #4.
- Red **Etch A Sketch** with acorn-cap knobs, both in the room art and at the top of the drawer: live "days until due", with anything ≤5 days, due today or late highlighted.
- **Statement history:** "Enter statement balance" updates the bill and upserts `bill_statements (bill_id, year_month)` for the bill's cycle month.
- **Credit Card Spend Insights:** month-over-month change (`+$X / +Y%`) per card and for all cards combined (cycle-aligned), neutral badges (*Lowest in N months*, *Highest in N months*, *Near 6-mo average*, *Above/Below average*), a spend-share bar, average monthly statement per card, and an expandable statement history.

**Foraging & Willpower Lab:** a pinned summary bar (up to 4 habits, showing this month's count and dollars; tap to log), then a segmented **1-Tap Wins / Smart Downsize / Habits** control. Built-in habits: **Water/Soda Instead of Alcohol** and **Skipped Restaurant Appetizer** (ask for an amount each time), **Picked Up Instead of Delivery** (1-tap fee/tip estimate *or* a custom difference), **Walked/Biked Short-Hop Metro +$2.25** (one-way or round-trip), **Cooked at Home**, and the v1 wins. Every habit can be edited, pinned or deleted; past wins never change. Sweep to Goal and swipe-to-undo are unchanged.

**Acorn economy** (Leaves and Silver/Royal Gold are retired everywhere)
- **10 Acorns per $1** of willpower. Focus Shift = max(10, minutes × 2 × hearth). Professor Hoot gives +50 a day. A reclaimed goal gives +250.
- **1 Golden Acorn per $100** of cumulative willpower (tracked in `golden_savings_milestones`, so undoing and re-logging never pays twice). Also +1 per reclaimed goal, plus seasonal and ladder milestones.
- **Two-tier upgrades** (`decor_shop.dart` → `UpgradesDrawer`): Acorns raise each room Starter → Cozy → Max (300 / 900). Acorns + Golden Acorns buy Grand Tree upgrades: **Treat Lantern Beacon** (projects green/yellow/red onto the canopy birdhouse), Fairy Lights, Twilight Sky, **Seasonal Foliage** (follows the real season) and Colony Outfits.

**Trophies** (`feat.dart` catalog + pure `feat_engine.dart`, persisted in `trophy_awards`)
- Stacking: **Forged Iron Shield** (10 wins in a calendar month, +50, ×N), **Copper Skillet Plaque** (10 home-cooked meals in an ISO week, +60), **Four-Seasons Forager** (one stage per active season; +1 Golden Acorn per full set).
- Ladders: willpower $ ($100 → $10k), wins (10 → 10,000), home-cooked meals, short hops, Focus Shifts, goals reclaimed.
- Mystery (`???`): Canopy Stargazer (60s in Cozy Zen), Window Shopper (swipe through every room), Dawn Chorus, Night Owl Forager, Double Harvest (a Golden Acorn forged on payday), Rush Hour Regular, Unbreakable Oak (30-day streak).
- **Stats ledger** (Trophy Hall): timeframe pills (All-Time / This Month / Last Month / This Year / Last Year); hero cards (willpower saved, most-used habit, best week, best month, biggest single skip, longest streak); a **per-impulse table with $ and count for every habit**; collapsible Groceries, DC Metro, Goals & Vaults, and Colony & Focus sections. Card stats are kept out of this room.

**Live prices & holdings** (`market_price_service.dart`, `reserve_drawer.dart`, `holding_editor.dart`)
- `Holding` gained `trackingMode`, `ticker`, `quantity`, `costBasisPerUnit`, `lastFetchedPrice`, `lastUpdatedAt`, optional `apyPercent` (null = no yield), ESPP `esppDiscountPercent` / `esppCashPotCents`, and `recurringCents`.
- Each holding row shows Qty, Avg Cost, Live Price, Total Value and Gain/Loss ($ and %), with an edit pencil. "Refresh prices" works per pocket; when a fetch fails, the cached price stays.
- ESPP shows a quarterly purchase pot (estimated shares after the discount, +paycheck contribution). HYSA has a "log this month's deposit" button for its recurring tracker. Silver shows total oz × spot.

### Decisions & deviations (please review)
1. **Window scenes (Meadow/Alpine/Harbor) were removed entirely**, not just hidden from the HUD, because the unified tree has no window. Their code is deleted.
2. **Desk instruments are gone.** The Treat lantern now lives in the Canopy Treasury (and on the beacon upgrade), and the Focus clock became the HUD quick-pill.
3. Habits keep a hidden "kind" (skip / downsize / swap) that drives the silo sand colors. The pinned bar replaces the old fixed Skips/Downsizes/DIY summary.
4. Undoing a win takes its Acorns back but **not** a Golden Acorn already forged.
5. **Migration gifts:** v1 Golden Leaves × 10 → Acorns, and existing users get Golden Acorns for past willpower at $100 each. The v1 brokerage APY setting is dropped (no automatic APY). Amber holdings named "savings/HYSA" move to HYSA, curio "silver/bullion" moves to Silver, and everything else maps Amber → Brokerage, Curio → Pokémon, Treasury → Retirement. On their first action after upgrading, migrated users will see one "Trophy earned … (+N more)" banner as their history is scored.
6. The statement month is the bill's **due-date month**. The combined card trend sums each card's k-th latest statement, so cards with different due days line up.
7. Room levels and pedestals are stored as `room_lv_<room>` and `pedestals` keys in `settings` (no new table).
8. Privacy Eye masks the HUD, tree plaques and every `AnimatedMoney`. Plain text amounts inside drawers are still visible.

---

## 3. Current Folder Tree
```text
squirrel-stash/
├── CLAUDE.md  STATUS.md  GEMINI_PROTOTYPE.txt  README.md
├── pubspec.yaml / pubspec.lock / analysis_options.yaml
├── android/ ios/ macos/ windows/  web/ (dev preview)
├── assets/
│   ├── audio/        campfire.wav chime.wav forest_breeze.wav plink.wav
│   ├── fonts/        Fredoka-* Nunito-* (+ OFL licenses)
│   ├── images/
│   │   ├── icons/    icons_template.json   (acorn.png, golden_acorn.png, <room>.png drop-ins)
│   │   ├── props/    props_manifest.json   (chest_lv1..3.png drop-ins)
│   │   └── rooms/    rooms_template.json   (<room>.png interior drop-ins + world boxes)
│   └── sprites/squirrels/ squirrels.json
├── docs/screenshots/ 01_great_oak 02_max_unlocked 03_frost 04_cozy_zen 05_zoom_trunk 06_zoom_roots
│                     07_lab 08_billVault 09_trophyHall 10_kitchen 11_metro 12_brokerage 13_outfitter 14_upgrades
│                     15_lab_drawer_expanded 16_settings_drawer
├── lib/
│   ├── main.dart  app.dart
│   ├── core/       audio_service backup_files dates haptics ids market_price_service money streaks
│   ├── database/   backup_codec desktop_db_factory desktop_db_factory_ffi desktop_db_factory_stub
│   │               memory_stash_repository schema seed_data seed_history
│   │               sqlite_stash_repository stash_database stash_repository
│   ├── models/     ambient_track app_settings bill (+BillStatement) decor feat focus_state goal
│   │               grocery_trip habit holding impulse metro_ride room stash_snapshot treat_status
│   │               trinket trophy
│   ├── providers/  art_assets_provider awards_provider bills_provider card_insights
│   │               diorama_snapshot_provider economy feat_engine finance_math finance_providers
│   │               focus_provider goals_provider impulse_provider kitchen_metro_math
│   │               kitchen_metro_provider repository_providers reserves_provider reward_service
│   │               room_summary_provider rooms_provider settings_provider stash_actions
│   │               stats_engine ui_provider willpower_actions
│   ├── game/
│   │   ├── stash_diorama_game.dart  layout.dart  diorama_snapshot.dart  diorama_event.dart
│   │   ├── art/         asset_manifest paint_kit palette squirrel_outfits squirrel_painter
│   │   ├── components/  canopy_layer canopy_residents diorama_layer fx_layer pulley_lift
│   │   │                rooms_layer sky_earth_layer trunk_layer weather_layer
│   │   └── rooms/       room_kit treasury_art outfitter_art trophy_hall_art kitchen_art metro_art
│   │                    lab_goals_art bill_vault_art pocket_art
│   ├── theme/      app_colors app_theme app_typography
│   └── ui/
│       ├── home_study_screen.dart
│       ├── diorama/    blueprint_overlay room_hotspots tap_zone tree_stage
│       ├── drawers/    backup_section bills_drawer card_insights_view decor_shop drawer_shell drawers etch_board
│       │               focus_drawer goal_detail_drawer goals_drawer habit_editor half_sheet holding_editor
│       │               kitchen_drawer lab_drawer lab_sections metro_drawer new_goal_drawer
│       │               outfitter_drawer prompts reclaim_celebration reserve_drawer room_drawer
│       │               settings_drawer stats_dashboard treasury_drawer trophies_drawer
│       └── widgets/    acorn_icons animated_money celebration_banner frost_vignette room_icons
│                       stash_controls study_hud_pill
├── test/  backup_codec_test finance_math_test insights_and_feats_test market_price_service_test
│          sqlite_repository_test stash_actions_test home_screen_test helpers/test_harness
│          screenshot/render_screenshots_test
└── tool/  generate_audio.dart  create_release_key.sh
```
All 131 `lib/` files are under the 300-line target. The largest are `game/art/squirrel_painter.dart` (275), `ui/widgets/study_hud_pill.dart` (274) and `providers/stash_actions.dart` (263).

**SQLite v2 tables:** `settings`, `bills` (+`kind`, `due_day`), **`bill_statements`**, `goals`, `trophies` (goal statues), `impulse_chips` (habits: +`entry`, `round_trip`, `pinned`, `habit_key`), `impulse_logs` (+`habit_id`), `holdings` (+10 market/ESPP/APY columns), `decor` (Grand Tree upgrades), **`grocery_trips`**, **`metro_rides`**, **`trophy_awards`**.

---

## 4. Known Issues / Next Recommended Steps
0. **The Pixel now runs the release-signed app.** Update it with `flutter build apk --release` then `adb install -r build/app/outputs/flutter-apk/app-release.apk`. Don't run a plain debug `flutter run` against it: the signature differs, and it may uninstall the app and wipe real data. Consider `applicationIdSuffix ".debug"` so debug builds install side by side. Import backup is still untested on device.
1. **Keep testing on the Pixel.** Still to check on device: live price fetches (Yahoo's unofficial chart endpoint may start requiring a cookie or crumb; CoinGecko's free tier rate-limits at about 30 calls a minute), InteractiveViewer pinch feel, frame rate while zoomed (the whole 600 × 1150 world redraws every frame, with static layers cached as pictures), audio, haptics and safe-area insets.
2. **Procedural art is placeholder.** The Seasonal Foliage crown looks blotchy in fall colors, rooms are simple at Starter level, and the train and commuters are basic. The drop-in paths for room interiors, icons and chests are wired but untested with real PNGs.
3. **Carved room names are deliberately faint** (8.2 world units, about 5pt at 1.0x, about 15pt at full zoom). Check on device that they read well when zoomed in. Custom room PNGs replace the procedural room, carving included, so hand-drawn rooms should paint their own name.
4. Privacy Eye doesn't mask plain text inside drawers (see decision 8).
5. Focus Shifts are counted all-time only, so the stats timeframe filter can't split them by month.
6. Marking a card paid doesn't prompt for a statement; you enter it from the bill's menu ("Enter statement balance").
7. Habit icons, trophy icons and goal icons are still system emoji, which look different on each platform.
8. Tall phones and tablets get backdrop gutters beside the tree; a landscape layout (tree + side drawer) is still open.
9. Carried over from v1: Warm Hearth never cools; web emoji load late; the first Windows build downloads SQLite.
10. **Backups are manual and unencrypted.** Nothing exports on a schedule, and the JSON holds real balances in plain text, so keep it in private storage. Restore replaces the whole stash (no merge). Possible next steps: a "last backed up N days ago" nudge in Settings, an optional passphrase, and an auto-export before "Start fresh" or a restore.
