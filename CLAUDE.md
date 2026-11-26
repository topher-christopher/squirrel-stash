# CLAUDE.md — SquirrelStash Permanent Engineering & Design Rules

## 1. Project Identity & Mission
**SquirrelStash** is a cozy, passive-simulation personal finance tracker and ambient focus companion inspired by *Fallout Shelter*, *Cats & Soup*, and *Spirit City: Lofi Sessions*.
- **Reference Blueprint:** Treat `GEMINI_PROTOTYPE.txt` strictly as a **functional, mathematical, and visual design blueprint**—do NOT copy its React/SVG web code.
- **Core Goal:** Rebuild SquirrelStash from scratch into a clean, modular, production-grade, offline-first application with true 60fps 2D game rendering, tactile animations, persistent local storage, and native mobile/desktop ergonomics.

---

## 2. Mandatory Tech Stack (NO React / NO Web Wrappers)
Do **NOT** use React, Next.js, Vue, HTML/CSS/SVG DOM rendering, or Electron. Build using a genuine native UI + 2D game-engine hybrid:
- **Primary Framework:** **Flutter (Dart)** — single codebase compiling natively to iOS, Android, macOS, and Windows.
- **2D Living Diorama Engine:** **Flame (`flame` package)** embedded directly inside the Flutter widget tree to power the 60fps autonomous squirrels, layered parallax scenery, weather/frost shaders, particle effects, and custom sprite sheets.
- **Local Persistence:** **SQLite (`drift` or `sqflite`)** so all bank balances, bills, goal chambers, reclaimed trophies, custom temptation chips, impulse logs, and Golden Leaf unlocks persist permanently on-device without requiring a cloud account.
- **Audio Engine:** **`audioplayers`** (or procedural/bundled loopable `.ogg`/`.wav` stems) for toggleable campfire crackle, forest breeze, and chime feedback during Focus Shifts.
- **State Management:** **Riverpod (`flutter_riverpod`)** or clean Bloc/ChangeNotifier architecture separating financial math, game simulation state, and UI drawers.

---

## 3. Core Visual Architecture: "The 1-Screen Hollow Oak Study"
Preserve the exact spatial hierarchy and zero-box diegetic philosophy established in `GEMINI_PROTOTYPE.txt`:

1. **Top Floating Study HUD Pill (Minimal & Collapsible):**
   - Displays **Free Spendable Cash** (Checking minus cash reserved in Goal Chambers) and **Total Net Worth**.
   - Quick-action **`+Payday`** button (triggers a multi-squirrel acorn delivery sprint).
   - **Window Scenery Switcher** (`🌳 Meadow` / `🎿 Alpine` / `🦭 Harbor`) to hot-swap the panoramic window scene.
   - **Zen Mode (`Eye` toggle):** Fades all HUD pills, numbers, and labels so the user can leave the app running on a desk stand as pure ambient art.

2. **Center Layer: Panoramic Arched Study Window (Flame 2D Canvas + Swappable Art Slot):**
   - Renders the outdoor world through an arched carved-oak window frame.
   - **Default Scene (`Meadow`):** Sunny/twilight sky, Great Oak branches with permanent upgrade lanterns, swaying leaf hammock with napping squirrel, acorn-tossing squirrel on stump, rare woodland visitors (e.g., *Professor Hoot*), the **Free Cash Acorn Pile** (scales dynamically with unallocated cash), and the **Bills Campfire**.
   - **Built-In Alternate Window Themes:** Include working animated Flame scenes for **Alpine Ski-Lift & River Tubing** (looping gondola, carving skier, drifting river tubers) and **Sea-Lion Lighthouse Jetty** (lighthouse beam, sunbathing sea lions, rising tide).
   - **Full-Screen Winter Frostline Mechanic:** Whenever `upcomingUnpaidBills > unallocatedFreeCash`, ice crystals creep onto the windowpanes, snow falls outside, surface squirrels wear knitted scarves, and a subtle icy vignette frames the entire viewport.

3. **Foreground Layer: Carved Oak Desk (Instant Thumb-Reach Instruments):**
   - **Sand-Art Impulse Silo & Researcher Squirrel:** Transparent glass tube filling with layered colored sand/acorns (**Sky-Blue** = Full Skips, **Mint-Emerald** = Smart Downsizes, **Honey-Gold** = DIY/Home Swaps), auto-forging small wins into **Silver (`$25`)** and **Royal Gold (`$100`)** acorns.
   - **Green / Yellow / Red *"Treat Yourself!"* Lantern:**
     - **Green (`TREAT YOURSELF!`):** Bills are covered AND goals are either empty or on pace (`>= 45%` funded) — encourages guilt-free spending on deals/treats without needing a goal or logging a skip.
     - **Yellow (`MINDFUL PACE`):** Bills are covered, but active goals are still warming up.
     - **Red (`FROST ALERT`):** Upcoming bills exceed free cash — shelter acorns until payday.
   - **Brass Focus Shift Clock & Study Squirrel:** Ticks live during focus sessions; opens the Pomodoro/Focus timer (`15m`, `25m`, `45m`, `60m`, plus a quick `10s Demo`), campfire audio toggle, **Warm Hearth** non-punitive streak multiplier (`1.0x` $\rightarrow$ `1.25x` $\rightarrow$ `1.5x`), and the **Golden Leaf Cosmetic Decor Shop** (strictly cosmetic currency—never mixed with real USD).
   - **Oak Level & Trophy Keepsake Stand:** Displays current Great Oak level (`Lv.1–4`) and miniature relics from completed goals.

4. **Bottom Layer: Cutaway Root Cellar (Below Floorboards):**
   - **Central Brass Acorn Chute & Wooden Ladder:** Autonomous hauler squirrels carry golden acorns down from the desk/meadow into active Goal Chambers.
   - **Repeatable *Fallout Shelter* Goal Chambers:** Paginated cleanly (`‹` `›` pegs) so the 1-screen layout scales infinitely. Each chamber evolves visually (`Lv.1 Dirt Alcove` $\rightarrow$ `Lv.2 Timber Chamber` $\rightarrow$ `Lv.3 Gold Treasury`). At `100%`, tapping **Reclaim & Upgrade** seals the chamber, reveals the user's **Time-Capsule Future-Self Note**, places a relic on the Trophy Stand, and upgrades the Great Oak.
   - **Three Deep Oak-Root Reserves:**
     - **Amber Reserve (Brokerage / HYSA):** Tracks 1–3 day liquid investments plus a carved **daily passive yield** plaque (`balance * APY / 365`).
     - **Curio Vault (Collectibles & Bullion):** Tracks graded Pokémon cards, sealed boxes, and silver bullion separately from daily banking.
     - **Deep Treasury (Roth IRA & 401k):** Locked long-term retirement hoard guarded by a sleeping Golden Elder Squirrel.

---

## 4. Custom Artwork Drop-In Architecture
The user plans to illustrate custom artwork (Procreate / Illustrator) later. Structure `assets/` and an `AssetManifest` config so custom PNGs can replace procedural placeholders without rewriting game logic:
- `assets/images/windows/` — Swappable `1200x960` transparent/layered window backdrops (`meadow.png`, `alpine.png`, `harbor.png`, plus a documented `custom_window_template.json` anchor config).
- `assets/sprites/squirrels/` — Sprite-sheet ready character definitions (`idle`, `tea`, `sleep`, `toss`, `hauler`, `researcher`, `focus`).
- `assets/images/props/` — Multi-state chest sprites, acorn piles, and frost overlays.

---

## 5. Modular Folder Structure & Token Efficiency Rules
Keep every Dart file focused and modular (**target < 300 lines per file**) so future edits touch only 1–2 files instead of burning tokens:
```text
squirrel_stash/
├── CLAUDE.md
├── STATUS.md
├── GEMINI_PROTOTYPE.txt
├── pubspec.yaml
├── assets/
│   ├── images/windows/
│   ├── sprites/squirrels/
│   └── audio/
└── lib/
    ├── main.dart
    ├── theme/                 # Warm oak, amber, and frost color tokens & typography
    ├── models/                # Account, Bill, Goal, Trophy, ImpulseChip, ImpulseLog, FocusState
    ├── database/              # SQLite schema, migrations, and seed data
    ├── providers/             # Financial calculations, Treat-Yourself logic, Focus timer state
    ├── game/                  # FlameGame world, window scenes, desk sprites, cellar & squirrel AI
    └── ui/
        ├── home_study_screen.dart
        ├── widgets/           # Top HUD pill, celebration banners, frost vignette
        └── drawers/           # Bottom sheets (Cash, Bills, Impulse Lab, Focus Timer, Goals, Vault)
```

---

## 6. Mandatory Session Wrap-Up Protocol
At the end of **every** coding session or feature update, you **MUST** update `STATUS.md` with:
1. **Current Tech Stack & Build Status** (packages used, how to run locally).
2. **Completed Features & Recent Changes** (concise bullet list).
3. **Current Folder Tree** (exact file paths).
4. **Known Issues / Next Recommended Steps** (so Gemini can review screenshots and write surgical prompts for the next session).