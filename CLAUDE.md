# CLAUDE.md — SquirrelStash Permanent Engineering & Design Rules

## 1. Project Identity & Mission
**SquirrelStash** is a cozy, passive-simulation personal finance tracker and ambient focus companion inspired by *Fallout Shelter*, *Cats & Soup*, and *Spirit City: Lofi Sessions*.
- **Design history:** The v1 Gemini React/SVG prototype is retired (archived outside the repo). This file, `STATUS.md` and the code are the source of truth.
- **Core Goal:** Rebuild SquirrelStash from scratch into a clean, modular, production-grade, offline-first application with true 60fps 2D game rendering, tactile animations, persistent local storage, and native mobile/desktop ergonomics.

---

## 2. Mandatory Tech Stack (NO React / NO Web Wrappers)
Do **NOT** use React, Next.js, Vue, HTML/CSS/SVG DOM rendering, or Electron. Build using a genuine native UI + 2D game-engine hybrid:
- **Primary Framework:** **Flutter (Dart)** — single codebase compiling natively to iOS, Android, macOS, and Windows.
- **2D Living Diorama Engine:** **Flame (`flame` package)** embedded directly inside the Flutter widget tree to power the 60fps autonomous squirrels, layered parallax scenery, weather/frost shaders, particle effects, and custom sprite sheets.
- **Local Persistence:** **SQLite (`drift` or `sqflite`)** so all bank balances, bills, goal chambers, reclaimed trophies, custom temptation chips, impulse logs, and Golden Leaf unlocks persist permanently on-device without requiring a cloud account.
- **Live Market Prices:** **`http`** only, zero API keys (CoinGecko simple price + Yahoo Finance chart JSON), cached in SQLite for offline fallback.
- **Audio Engine:** **`audioplayers`** for one soft `plink` SFX and an **optional** calm background piano loop dropped in at `assets/audio/ambient_piano.wav` (silent when muted or absent). `AudioPlayersService` is a `WidgetsBindingObserver`: all audio pauses on `inactive` / `hidden` / `paused` / `detached` and resumes only on `resumed` if still enabled. No loud chimes.
- **State Management:** **Riverpod (`flutter_riverpod`)** or clean Bloc/ChangeNotifier architecture separating financial math, game simulation state, and UI drawers.

---

## 3. Core Visual Architecture: "The Great Oak Colony" (v1.2)
One continuous, zoomable **Fallout Shelter-style cutaway of the Great Oak** (sunlit canopy → lively trunk → underground root tunnels) in a fixed **600 × 1150** Flame world (`lib/game/layout.dart`), hosted in an `InteractiveViewer` (min `1.0x`, max `2.8x`) with a floating **Reset Zoom** chip. Zero-box diegetic philosophy: money lives *inside* the rooms.

1. **Top HUD (minimal & collapsible):** Free Cash (checking − Goal Chamber allocations), Total Stash (net worth), custom **Acorn** & **Golden Acorn** counters (`AcornIcon` / `GoldenAcornIcon` — never raw emoji), `+Payday`, a Focus Timer quick-pill (no Focus room), the **Starter / Max** switch (re-themes every room at once, free), the **Privacy Eye**, and **Cozy Zen** (hides all chrome and room icons so the tree is pure ambient art).
2. **Icon-free tree:** no medallions, labels or dollar figures float over rooms. Each room's name is carved subtly into its own wood (floor plank / station plate). Zooming in fades in extra interior animations; tapping a room glides the camera to it and opens its drawer, whose header shows the **room name + primary dollar total**.
3. **Swipeable room drawer:** one bottom sheet with a horizontal `PageView` across all rooms in natural order (pills + dots on top); the camera follows each swipe.
4. **Rooms** (`RoomKey`, top → bottom, 18 drawer pages):
   - **Crown:** **Canopy Treasury** (Free Cash acorn pile, `+Payday` sprint, Green / Yellow / Red **Treat Yourself Lantern**) and the **Canopy Terrace** deck with 4 stone Display Pedestals (+2 Golden Acorn extras). **Canopy Bird Feeder** on the right branch (upgradeable birdhouse, wooden landing perch, hanging feeder, Lifetime Bird & Critter Logbook); the **Owl Moonlight Lantern** with an open songbird perch and Professor Hoot on the left branch; tappable wild-acorn bubbles above the crown.
   - **Left trunk — 3 hero rooms:** **Acorn Outfitter** (indoor half-pipe skatepark, DJ booth, disco ball, film canisters, Giant Framed Pokémon Card, free trinkets & wardrobe), **Ratatouille Kitchen** (grocery spend, home-cooked streak, Brass Thumbpin Dining Table, Treehouse Christmas Tree), **Hollow Log Bill Vault** (full width, no Etch A Sketch in the room; waterline scenes from unpaid bills ÷ Free Cash: low < 25% brook & lawn chairs, mid 25–50% walnut skiff, high > 50% scuba diver & raft angler; due-date countdowns, statements & card insights in the drawer).
   - **Right trunk — 3 compact rooms:** **Foraging & Willpower Lab** (pinnable editable habits, Smart Downsize), **Trophy Hall** (stacking trophies, ladders, mystery feats, goal statues, stats — *no credit-card stats here*; multi-act custodian), **Goals Alcove** (Lv.1 Dirt → Lv.2 Timber → Lv.3 Gold chests; reclaim at 100% raises a statue).
   - **Ground line:** **Scavenger Burrow** outpost (timed seed expeditions 2h / 6h / 12h → ready-to-pour seed bags). Catwalks cross the lift shaft; the lift ends at the **root concourse** (never inside the Metro).
   - **Underground:** **DC Metro Station** (WMATA fares $2.25 / $2.50 / $6.75 / custom; LED board cycling real Red & Orange/Silver stops; Caps fans off Gallery Place / Metro Center), **seven equal-sized vault pockets** (Brokerage, Pokémon Gallery, Crypto Cavern, ESPP, HYSA & Savings — no automatic APY, Retirement Vault, Silver & Bullion Alcove) and the **Deep-Root Hearth & Tree-Light Generator**.
5. **Winter Frostline:** whenever `upcomingUnpaidBills > unallocatedFreeCash` — snow over the tree, frosted crown, jackets & beanies, sleds & snowball fights, red lantern, icy full-screen vignette (the winter colony life also runs with Seasonal Foliage in real winter).
6. **Acorn upkeep economy (cosmetic currencies only, never real USD; never penalizes balances):** 10 Acorns per $1 of willpower + Focus Shifts + wild canopy bubbles; 1 Golden Acorn per $100 cumulative willpower, per reclaimed goal, and per seasonal/ladder milestone. **No cosmetic paywalls:** trinkets, outfits, Grand Tree looks and room themes are free. Acorns are *spent* on Hearth fuel & Overdrive (unfueled = twilight & sleeping squirrels), Rush-Hour floods, seed expeditions, a temporary 2nd squad and feeder lures; Golden Acorns buy Granary storage (Acorns over the cap wait in an overflow), Hearth burn time, terrace pedestals and 24h Colony Festivals. Every species needs a uniform 100 lifetime visits for its keepsake. Time-driven code reads `clockProvider` and settles in `ColonyActions.tick()`.

---

## 4. Custom Artwork Drop-In Architecture
Custom PNGs replace procedural placeholders without touching game logic (`StashAssetManifest` + `artAssetsProvider`):
- `assets/images/rooms/` — `<room>.png` room interiors; world boxes in `rooms_template.json`.
- `assets/images/icons/` — `acorn.png`, `golden_acorn.png`, `<room>.png` medallions (`icons_template.json`).
- `assets/images/props/` — `chest_lv1..3.png` (`props_manifest.json`).
- `assets/images/outfitter/` — `custom_pokemon_card.png`, `custom_film_canister.png`, `custom_skate_deck.png` (`outfitter_manifest.json`).
- `assets/images/metro/` — `custom_caps_flag.png` (`metro_manifest.json`).
- `assets/audio/ambient_piano.wav` — optional calm background piano loop (none ships).
- `assets/sprites/squirrels/` — sprite-sheet poses (`idle`, `tea`, `sleep`, `toss`, `hauler`, `researcher`, `focus`, `lantern`) described by `squirrels.json`.

---

## 5. Modular Folder Structure & Token Efficiency Rules
Keep every Dart file focused and modular (**target < 300 lines per file**) so future edits touch only 1–2 files instead of burning tokens:
```text
squirrel_stash/
├── CLAUDE.md  STATUS.md  pubspec.yaml
├── assets/  images/{rooms,icons,props}/  sprites/squirrels/  audio/  fonts/
└── lib/
    ├── main.dart
    ├── core/                  # dates, money, haptics, audio, streaks, market_price_service (http)
    ├── theme/                 # Warm oak, amber, and frost color tokens & typography
    ├── models/                # Bill(+Statement), Goal, Trophy, Habit, ImpulseLog, Holding, Room, Feat, Bird, Expedition, ColonyState, …
    ├── database/              # SQLite schema & migrations (v3), repositories, seed data
    ├── providers/             # Pure math engines (finance, card insights, feats, stats, colony + BirdSim) + notifiers & actions
    ├── game/                  # FlameGame, layout, layers (sky, canopy, trunk, catwalks, lift, colony life, weather), rooms/ art
    └── ui/
        ├── home_study_screen.dart
        ├── diorama/           # TreeStage (InteractiveViewer + camera), invisible room tap hotspots
        ├── widgets/           # HUD, acorn icons, room medallions, banners, frost vignette
        └── drawers/           # Swipeable room drawer + one body per room, upgrades, focus, settings
```
Schema changes: bump `Schema.version` and add statements under that version in `Schema.migrations` (never edit shipped statements); add a migration test in `test/sqlite_repository_test.dart`.

---

## 6. Mandatory Session Wrap-Up Protocol
At the end of **every** coding session or feature update, you **MUST** update `STATUS.md` with:
1. **Current Tech Stack & Build Status** (packages used, how to run locally).
2. **Completed Features & Recent Changes** (concise bullet list).
3. **Current Folder Tree** (exact file paths).
4. **Known Issues / Next Recommended Steps** (so Gemini can review screenshots and write surgical prompts for the next session).