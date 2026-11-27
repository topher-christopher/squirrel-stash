import '../core/dates.dart';
import '../models/bird.dart';
import '../models/room.dart';
import '../models/treat_status.dart';

/// Visual state of one Goal Chamber chest.
class GoalArt {
  const GoalArt({required this.level, required this.percent, required this.priority});

  /// 1 Dirt Alcove, 2 Timber Chamber, 3 Gold Treasury.
  final int level;
  final int percent;
  final bool priority;
}

/// Which scene the Hollow Log Bill Vault plays.
enum WaterScene {
  /// Bills under 25% of Free Cash: a shallow brook and lawn chairs.
  low,

  /// 25–50%: a walnut-shell skiff and squirrels patching seams.
  mid,

  /// Over 50%: a brass scuba diver and the raft angler.
  high,
}

/// Everything the Great Oak needs to draw, pushed from Riverpod.
/// Plain data — the game never reaches back into providers.
class TreeSnapshot {
  const TreeSnapshot({
    this.frost = false,
    this.twilight = false,
    this.fairyLights = false,
    this.outfits = false,
    this.beacon = false,
    this.seasonal = false,
    this.season = Season.fall,
    this.treat = TreatLevel.green,
    this.acornPile = 0,
    this.focusRunning = false,
    this.focusProgress = 0,
    this.roomLevels = const {},
    this.goals = const [],
    this.goalCount = 0,
    this.siloFill = 0.12,
    this.skipFraction = 0,
    this.downsizeFraction = 0,
    this.diyFraction = 1,
    this.hootHasGift = false,
    this.paydayBurst = false,
    this.billPressure = 0,
    this.trophyCount = 0,
    this.statueCount = 0,
    this.oakLevel = 1,
    this.homeStreak = 0,
    this.metroRides = 0,
    this.pedestals = const [],
    this.pocketGains = const {},
    this.lit = true,
    this.hearthFuel = 1,
    this.overdrive = false,
    this.festival = false,
    this.rushHour = false,
    this.winter = false,
    this.acornBubbles = 0,
    this.feederSeed,
    this.feederFill = 0,
    this.lure,
    this.perched = const [],
    this.squads = 1,
    this.expeditionsOut = 0,
    this.seedBags = 0,
  });

  final bool frost;

  /// Twilight sky (the Grand Tree look, or the dim of an unfueled Hearth).
  final bool twilight;
  final bool fairyLights;
  final bool outfits;

  /// Treat lantern projected onto the Owl Moonlight Lantern.
  final bool beacon;
  final bool seasonal;
  final Season season;
  final TreatLevel treat;

  /// Free Cash Acorn Pile size in the Canopy Treasury (0 or 4–15).
  final int acornPile;
  final bool focusRunning;
  final double focusProgress;
  final Map<RoomKey, int> roomLevels;
  final List<GoalArt> goals;
  final int goalCount;
  final double siloFill;
  final double skipFraction;
  final double downsizeFraction;
  final double diyFraction;
  final bool hootHasGift;
  final bool paydayBurst;

  /// Unpaid bills ÷ Free Cash (drives the Bill Vault waterline; ≥1 = Frostline).
  final double billPressure;

  /// Feat awards earned (fills Trophy Hall shelves and boxes).
  final int trophyCount;

  /// Goal statues reclaimed.
  final int statueCount;
  final int oakLevel;
  final int homeStreak;
  final int metroRides;

  /// Canopy Terrace pedestal item kinds (`statue`, `feat`, `trinket` or '').
  /// Its length is how many pedestals stand on the terrace.
  final List<String> pedestals;

  /// Vault pockets currently above cost basis (true) or below (false).
  final Map<RoomKey, bool> pocketGains;

  /// The Deep-Root Hearth is burning (fuel, Overdrive or a Festival). When
  /// false the tree dims and the colony curls up asleep.
  final bool lit;

  /// Hearth fuel left, 0..1 of its burn capacity.
  final double hearthFuel;
  final bool overdrive;
  final bool festival;
  final bool rushHour;

  /// Winter theme: jackets, beanies, sleds and snowball fights.
  final bool winter;

  /// Wild acorn bubbles ready to tap above the canopy (0–5).
  final int acornBubbles;
  final SeedKind? feederSeed;
  final double feederFill;
  final LureKind? lure;

  /// Visitors currently at the feeder (newest first).
  final List<BirdSpecies> perched;
  final int squads;
  final int expeditionsOut;

  /// Seed bags waiting by the burrow, ready to pour.
  final int seedBags;

  int levelOf(RoomKey room) => roomLevels[room] ?? 1;

  WaterScene get waterScene => billPressure < 0.25
      ? WaterScene.low
      : (billPressure <= 0.5 ? WaterScene.mid : WaterScene.high);
}
