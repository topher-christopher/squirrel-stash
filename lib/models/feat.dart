/// How a Trophy Hall feat is earned.
enum FeatKind {
  /// Stacks every period it is achieved (x2, x3…).
  repeatable,

  /// Lifelong multi-tier milestone ladder.
  ladder,

  /// Evolves season by season.
  seasonal,

  /// Hidden until earned (`???`).
  mystery,
}

enum MysteryTier {
  easy('Easy'),
  medium('Medium'),
  legendary('Super');

  const MysteryTier(this.label);
  final String label;
}

/// One rung of a milestone ladder.
class LadderTier {
  const LadderTier(this.threshold, this.acorns, [this.golden = 0]);

  /// Count, or cents for money ladders.
  final int threshold;
  final int acorns;
  final int golden;
}

/// A trophy definition from the catalog below.
class FeatDef {
  const FeatDef({
    required this.key,
    required this.name,
    required this.icon,
    required this.description,
    required this.kind,
    this.acorns = 0,
    this.golden = 0,
    this.tiers = const [],
    this.mystery,
    this.moneyLadder = false,
  });

  final String key;
  final String name;
  final String icon;
  final String description;
  final FeatKind kind;
  final int acorns;
  final int golden;
  final List<LadderTier> tiers;
  final MysteryTier? mystery;

  /// Ladder thresholds are cents (shown as dollars).
  final bool moneyLadder;
}

/// A feat earned for one period (`2026-11`, `2026-W47`, `tier3`, `once`…).
class FeatAward {
  const FeatAward({
    required this.id,
    required this.featKey,
    required this.periodKey,
    required this.awardedAt,
    this.acorns = 0,
    this.golden = 0,
  });

  final String id;
  final String featKey;
  final String periodKey;
  final DateTime awardedAt;
  final int acorns;
  final int golden;

  String get uniqueKey => '$featKey|$periodKey';

  Map<String, Object?> toMap() => {
        'id': id,
        'feat_key': featKey,
        'period_key': periodKey,
        'awarded_at': awardedAt.toIso8601String(),
        'acorns': acorns,
        'golden': golden,
      };

  factory FeatAward.fromMap(Map<String, Object?> m) => FeatAward(
        id: m['id']! as String,
        featKey: m['feat_key']! as String,
        periodKey: m['period_key']! as String,
        awardedAt: DateTime.parse(m['awarded_at']! as String),
        acorns: (m['acorns'] as num? ?? 0).toInt(),
        golden: (m['golden'] as num? ?? 0).toInt(),
      );
}

/// The full Trophy Hall catalog.
abstract final class Feats {
  static const ironShield = 'iron_shield';
  static const copperSkillet = 'copper_skillet';
  static const fourSeasons = 'four_seasons';
  static const fourSeasonsStage = 'four_seasons_stage';
  static const ladderSaved = 'ladder_saved';
  static const ladderWins = 'ladder_wins';
  static const ladderMeals = 'ladder_meals';
  static const ladderHops = 'ladder_hops';
  static const ladderFocus = 'ladder_focus';
  static const ladderGoals = 'ladder_goals';
  static const canopyStargazer = 'canopy_stargazer';
  static const windowShopper = 'window_shopper';
  static const dawnChorus = 'dawn_chorus';
  static const nightOwl = 'night_owl';
  static const doubleHarvest = 'double_harvest';
  static const rushHour = 'rush_hour';
  static const unbreakableOak = 'unbreakable_oak';

  static const all = <FeatDef>[
    FeatDef(key: ironShield, name: 'Forged Iron Shield', icon: '🛡️',
        description: 'Log 10 willpower wins in a calendar month',
        kind: FeatKind.repeatable, acorns: 50),
    FeatDef(key: copperSkillet, name: 'Copper Skillet Plaque', icon: '🍳',
        description: 'Log 10 Home-Cooked Meals in one week',
        kind: FeatKind.repeatable, acorns: 60),
    FeatDef(key: fourSeasons, name: 'Four-Seasons Forager', icon: '🍂',
        description: 'Log activity in Spring, Summer, Fall & Winter',
        kind: FeatKind.seasonal, golden: 1),
    FeatDef(key: ladderSaved, name: 'Willpower Hoard', icon: '🌰',
        description: 'Lifetime willpower dollars saved',
        kind: FeatKind.ladder, moneyLadder: true, tiers: [
          LadderTier(10000, 100), LadderTier(50000, 250, 1),
          LadderTier(100000, 500, 1), LadderTier(500000, 1000, 2),
          LadderTier(1000000, 2000, 3),
        ]),
    FeatDef(key: ladderWins, name: 'Steady Paws', icon: '🐾',
        description: 'Lifetime willpower wins logged',
        kind: FeatKind.ladder, tiers: [
          LadderTier(10, 50), LadderTier(50, 100), LadderTier(100, 200, 1),
          LadderTier(500, 400, 1), LadderTier(1000, 800, 2),
          LadderTier(5000, 1500, 2), LadderTier(10000, 3000, 3),
        ]),
    FeatDef(key: ladderMeals, name: 'Hearth Cook', icon: '🥘',
        description: 'Home-cooked meals logged',
        kind: FeatKind.ladder, tiers: [
          LadderTier(10, 60), LadderTier(25, 120), LadderTier(50, 250, 1),
          LadderTier(100, 500, 1), LadderTier(250, 1000, 2),
        ]),
    FeatDef(key: ladderHops, name: 'Pavement Pounder', icon: '🚲',
        description: 'Short-hop Metro trips walked or biked',
        kind: FeatKind.ladder, tiers: [
          LadderTier(10, 40), LadderTier(25, 90), LadderTier(50, 180, 1),
          LadderTier(100, 360, 1), LadderTier(250, 720, 2),
        ]),
    FeatDef(key: ladderFocus, name: 'Deep Focus', icon: '⏳',
        description: 'Focus Shifts completed',
        kind: FeatKind.ladder, tiers: [
          LadderTier(5, 50), LadderTier(25, 120, 1), LadderTier(50, 250, 1),
          LadderTier(100, 500, 2), LadderTier(250, 1000, 2),
        ]),
    FeatDef(key: ladderGoals, name: 'Chamber Sealer', icon: '🏛️',
        description: 'Savings goals reclaimed',
        kind: FeatKind.ladder, tiers: [
          LadderTier(1, 100), LadderTier(3, 200, 1), LadderTier(5, 400, 1),
          LadderTier(10, 800, 2), LadderTier(25, 1600, 3),
        ]),
    FeatDef(key: canopyStargazer, name: 'Canopy Stargazer', icon: '🔭',
        description: 'Spend 60 seconds in Cozy Zen',
        kind: FeatKind.mystery, mystery: MysteryTier.easy, acorns: 75),
    FeatDef(key: windowShopper, name: 'Window Shopper', icon: '🪟',
        description: 'Swipe through every room in the tree',
        kind: FeatKind.mystery, mystery: MysteryTier.easy, acorns: 75),
    FeatDef(key: dawnChorus, name: 'Dawn Chorus', icon: '🐦',
        description: 'Log a willpower win before 6 AM',
        kind: FeatKind.mystery, mystery: MysteryTier.easy, acorns: 75),
    FeatDef(key: nightOwl, name: 'Night Owl Forager', icon: '🦉',
        description: 'Log a willpower win after 11 PM',
        kind: FeatKind.mystery, mystery: MysteryTier.medium, acorns: 150),
    FeatDef(key: doubleHarvest, name: 'Double Harvest', icon: '🌾',
        description: 'Forge a Golden Acorn on Payday',
        kind: FeatKind.mystery, mystery: MysteryTier.medium, acorns: 150),
    FeatDef(key: rushHour, name: 'Rush Hour Regular', icon: '🚇',
        description: 'Ride the Metro 10 times in one week',
        kind: FeatKind.mystery, mystery: MysteryTier.medium, acorns: 150),
    FeatDef(key: unbreakableOak, name: 'Unbreakable Oak', icon: '🌳',
        description: 'Log willpower wins 30 days in a row',
        kind: FeatKind.mystery, mystery: MysteryTier.legendary,
        acorns: 500, golden: 2),
  ];

  static FeatDef? byKey(String key) {
    for (final f in all) {
      if (f.key == key) return f;
    }
    return null;
  }
}
