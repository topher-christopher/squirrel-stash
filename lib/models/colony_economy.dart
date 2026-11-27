/// v1.2 upkeep economy constants. Acorns and Golden Acorns are cosmetic
/// currencies only — nothing here ever touches a real dollar balance.
abstract final class ColonyEconomy {
  // --------------------------------------------------------------- Granary
  /// Acorn storage cap per Granary level (Golden Acorn upgrades).
  static const granaryCaps = [2500, 5000, 10000, 25000, 60000];

  /// Golden Acorns to reach each Granary level (index = level - 1).
  static const granaryGolden = [0, 2, 4, 8, 15];
  static int get granaryMax => granaryCaps.length;
  static int granaryCap(int level) => granaryCaps[(level - 1).clamp(0, granaryCaps.length - 1)];

  /// Smallest Granary level that already holds [acorns] (existing stashes
  /// are grandfathered in at the level their balance needs).
  static int granaryLevelFor(int acorns) {
    for (var i = 0; i < granaryCaps.length; i++) {
      if (acorns <= granaryCaps[i]) return i + 1;
    }
    return granaryCaps.length;
  }

  // ---------------------------------------------------------------- Hearth
  /// Longest burn the Deep-Root Hearth holds per burn-time level.
  static const hearthBurnHours = [12, 24, 72];
  static const hearthGolden = [0, 3, 8];
  static int get hearthMax => hearthBurnHours.length;
  static Duration hearthCapacity(int level) =>
      Duration(hours: hearthBurnHours[(level - 1).clamp(0, hearthBurnHours.length - 1)]);

  static const fuelAcornsPerHour = 10;

  /// Free burn time a brand-new or upgraded stash starts with.
  static const welcomeFuelHours = 12;

  /// Hearth Overdrive: lights stay on regardless of fuel.
  static const overdriveHours = [24, 48];
  static int overdriveAcorns(int hours) => hours >= 48 ? 420 : 240;

  // ------------------------------------------------------ Golden extras
  static const festivalGolden = 2;
  static const festivalHours = 24;

  /// Base Canopy Terrace pedestals, plus up to [maxExtraPedestals] more.
  static const basePedestals = 4;
  static const maxExtraPedestals = 2;
  static const pedestalGolden = [2, 3];

  // ------------------------------------------------------ Acorn sinks
  static const rushHourAcorns = 150;
  static const rushHourHours = 3;
  static const secondSquadAcorns = 300;
  static const secondSquadHours = 24;

  // ------------------------------------------------- Wild acorn bubbles
  /// The canopy collector fills in 8h while the Hearth is lit, 12h when dark.
  static const collectorLitHours = 8;
  static const collectorDarkHours = 12;
  static const bubbleCount = 5;
  static const acornsPerBubble = 30;
}
