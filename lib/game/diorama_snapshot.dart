import '../core/dates.dart';
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

/// One line on the Etch A Sketch due-date board.
class EtchLine {
  const EtchLine(this.label, this.days, this.paid);
  final String label;
  final int days;
  final bool paid;
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
    this.etch = const [],
    this.billCoverage = 1,
    this.trophyCount = 0,
    this.statueCount = 0,
    this.oakLevel = 1,
    this.homeStreak = 0,
    this.metroRides = 0,
    this.pedestals = const [],
    this.pocketGains = const {},
  });

  final bool frost;
  final bool twilight;
  final bool fairyLights;
  final bool outfits;

  /// Treat lantern projected onto the canopy birdhouse beacon.
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
  final List<EtchLine> etch;

  /// Free cash ÷ unpaid bills (the Bill Vault safety waterline; ≥1 = safe).
  final double billCoverage;

  /// Feat awards earned (fills Trophy Hall shelves and boxes).
  final int trophyCount;

  /// Goal statues reclaimed.
  final int statueCount;
  final int oakLevel;
  final int homeStreak;
  final int metroRides;

  /// Pedestal item kinds: `statue`, `feat`, `trinket` or ''.
  final List<String> pedestals;

  /// Vault pockets currently above cost basis (true) or below (false).
  final Map<RoomKey, bool> pocketGains;

  int levelOf(RoomKey room) => roomLevels[room] ?? 1;
}
