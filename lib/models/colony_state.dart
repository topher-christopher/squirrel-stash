import 'bird.dart';
import 'colony_economy.dart';

/// Time-driven colony upkeep state, stored as keys in the `settings` table:
/// the Deep-Root Hearth, timed boosts, the canopy acorn collector, the
/// feeder's seed & lure and the last few visitors.
class ColonyState {
  const ColonyState({
    this.hearthLevel = 1,
    this.hearthFuelUntil,
    this.overdriveUntil,
    this.festivalUntil,
    this.rushHourUntil,
    this.secondSquadUntil,
    this.collectorProgress = 0,
    this.collectorCheckedAt,
    this.extraPedestals = 0,
    this.feederSeed,
    this.feederUntil,
    this.lure,
    this.lureUntil,
    this.birdCheckedAt,
    this.recent = const [],
  });

  /// Burn-time level 1..3 (12h → 24h → 3 days).
  final int hearthLevel;
  final DateTime? hearthFuelUntil;
  final DateTime? overdriveUntil;
  final DateTime? festivalUntil;
  final DateTime? rushHourUntil;
  final DateTime? secondSquadUntil;

  /// Canopy collector fill, 0..1 (5 tappable acorn bubbles when full).
  final double collectorProgress;
  final DateTime? collectorCheckedAt;
  final int extraPedestals;
  final SeedKind? feederSeed;
  final DateTime? feederUntil;
  final LureKind? lure;
  final DateTime? lureUntil;

  /// Feeder visits are simulated up to this moment.
  final DateTime? birdCheckedAt;

  /// Most recent visitors (newest first) — the ones still perched.
  final List<BirdVisit> recent;

  static bool _on(DateTime? until, DateTime now) => until != null && now.isBefore(until);

  static DateTime? _latest(Iterable<DateTime?> times) {
    DateTime? best;
    for (final t in times) {
      if (t != null && (best == null || t.isAfter(best))) best = t;
    }
    return best;
  }

  /// The tree stays lit until fuel, Overdrive or a Festival runs out.
  DateTime? get litUntil => _latest([hearthFuelUntil, overdriveUntil, festivalUntil]);
  bool isLit(DateTime now) => _on(litUntil, now);
  bool overdriveOn(DateTime now) => _on(overdriveUntil, now);
  bool festivalOn(DateTime now) => _on(festivalUntil, now);
  bool rushHourOn(DateTime now) => _on(rushHourUntil, now);
  bool secondSquadOn(DateTime now) => _on(secondSquadUntil, now);
  int squads(DateTime now) => secondSquadOn(now) ? 2 : 1;

  Duration get hearthCapacity => ColonyEconomy.hearthCapacity(hearthLevel);

  Duration fuelLeft(DateTime now) =>
      _on(hearthFuelUntil, now) ? hearthFuelUntil!.difference(now) : Duration.zero;

  double fuelFraction(DateTime now) =>
      (fuelLeft(now).inSeconds / hearthCapacity.inSeconds).clamp(0.0, 1.0);

  SeedKind? seedIn(DateTime now) => _on(feederUntil, now) ? feederSeed : null;

  /// How full the feeder is, 0..1 (three bags of one seed fill it).
  double feederFill(DateTime now) {
    final seed = seedIn(now);
    if (seed == null) return 0;
    final cap = seed.feederHours * SeedKind.maxBagsInFeeder * 3600;
    return (feederUntil!.difference(now).inSeconds / cap).clamp(0.0, 1.0);
  }

  LureKind? lureOn(DateTime now) => _on(lureUntil, now) ? lure : null;

  int get bubbles => (collectorProgress * ColonyEconomy.bubbleCount + 1e-9)
      .floor()
      .clamp(0, ColonyEconomy.bubbleCount);

  int get pedestalCount => ColonyEconomy.basePedestals + extraPedestals;

  /// Visitors still perched (seen within the last half hour).
  List<BirdSpecies> perched(DateTime now) {
    final out = <BirdSpecies>[];
    for (final v in recent) {
      if (now.difference(v.at).inMinutes <= 30 && !out.contains(v.species)) out.add(v.species);
    }
    return out;
  }

  ColonyState copyWith({
    int? hearthLevel,
    DateTime? hearthFuelUntil,
    DateTime? overdriveUntil,
    DateTime? festivalUntil,
    DateTime? rushHourUntil,
    DateTime? secondSquadUntil,
    double? collectorProgress,
    DateTime? collectorCheckedAt,
    int? extraPedestals,
    SeedKind? feederSeed,
    DateTime? feederUntil,
    LureKind? lure,
    DateTime? lureUntil,
    DateTime? birdCheckedAt,
    List<BirdVisit>? recent,
  }) =>
      ColonyState(
        hearthLevel: hearthLevel ?? this.hearthLevel,
        hearthFuelUntil: hearthFuelUntil ?? this.hearthFuelUntil,
        overdriveUntil: overdriveUntil ?? this.overdriveUntil,
        festivalUntil: festivalUntil ?? this.festivalUntil,
        rushHourUntil: rushHourUntil ?? this.rushHourUntil,
        secondSquadUntil: secondSquadUntil ?? this.secondSquadUntil,
        collectorProgress: collectorProgress ?? this.collectorProgress,
        collectorCheckedAt: collectorCheckedAt ?? this.collectorCheckedAt,
        extraPedestals: extraPedestals ?? this.extraPedestals,
        feederSeed: feederSeed ?? this.feederSeed,
        feederUntil: feederUntil ?? this.feederUntil,
        lure: lure ?? this.lure,
        lureUntil: lureUntil ?? this.lureUntil,
        birdCheckedAt: birdCheckedAt ?? this.birdCheckedAt,
        recent: recent ?? this.recent,
      );

  static const keys = [
    'hearth_level', 'hearth_fuel_until', 'overdrive_until', 'festival_until', 'rush_hour_until',
    'second_squad_until', 'collector_progress', 'collector_checked_at', 'extra_pedestals',
    'feeder_seed', 'feeder_until', 'lure', 'lure_until', 'bird_checked_at', 'recent_visitors',
  ];

  Map<String, String> toMap() {
    String t(DateTime? d) => d?.toIso8601String() ?? '';
    return {
      'hearth_level': '$hearthLevel',
      'hearth_fuel_until': t(hearthFuelUntil),
      'overdrive_until': t(overdriveUntil),
      'festival_until': t(festivalUntil),
      'rush_hour_until': t(rushHourUntil),
      'second_squad_until': t(secondSquadUntil),
      'collector_progress': collectorProgress.toStringAsFixed(5),
      'collector_checked_at': t(collectorCheckedAt),
      'extra_pedestals': '$extraPedestals',
      'feeder_seed': feederSeed?.name ?? '',
      'feeder_until': t(feederUntil),
      'lure': lure?.name ?? '',
      'lure_until': t(lureUntil),
      'bird_checked_at': t(birdCheckedAt),
      'recent_visitors': [
        for (final v in recent.take(6)) '${v.species.name}@${v.at.toIso8601String()}@${v.lure?.name ?? ''}',
      ].join(','),
    };
  }

  factory ColonyState.fromMap(Map<String, String> m) {
    DateTime? t(String k) => DateTime.tryParse(m[k] ?? '');
    final recent = <BirdVisit>[];
    for (final raw in (m['recent_visitors'] ?? '').split(',')) {
      final parts = raw.split('@');
      if (parts.length < 2) continue;
      final species = BirdSpecies.tryParse(parts[0]);
      final at = DateTime.tryParse(parts[1]);
      if (species != null && at != null) {
        recent.add(BirdVisit(species, at, parts.length > 2 ? LureKind.tryParse(parts[2]) : null));
      }
    }
    return ColonyState(
      hearthLevel: (int.tryParse(m['hearth_level'] ?? '') ?? 1).clamp(1, ColonyEconomy.hearthMax),
      hearthFuelUntil: t('hearth_fuel_until'),
      overdriveUntil: t('overdrive_until'),
      festivalUntil: t('festival_until'),
      rushHourUntil: t('rush_hour_until'),
      secondSquadUntil: t('second_squad_until'),
      collectorProgress: (double.tryParse(m['collector_progress'] ?? '') ?? 0).clamp(0.0, 1.0),
      collectorCheckedAt: t('collector_checked_at'),
      extraPedestals: (int.tryParse(m['extra_pedestals'] ?? '') ?? 0).clamp(0, ColonyEconomy.maxExtraPedestals),
      feederSeed: SeedKind.tryParse(m['feeder_seed']),
      feederUntil: t('feeder_until'),
      lure: LureKind.tryParse(m['lure']),
      lureUntil: t('lure_until'),
      birdCheckedAt: t('bird_checked_at'),
      recent: recent,
    );
  }
}
