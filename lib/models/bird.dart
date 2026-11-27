/// Seed bags carried home by the Scavenger Burrow squads. Pouring one into
/// the Canopy Bird Feeder attracts that seed's visitors for [feederHours].
enum SeedKind {
  sunflowerMillet('Sunflower & Millet Mix', 'Cardinals, Blue Jays, Chickadees & Robins', 6, 0.55),
  berryHickory('Berry & Hickory Nut Blend', 'Woodpeckers, Waxwings, Orioles & Chipmunks', 6, 0.45),
  goldenHusk('Golden Husk & Wild Berry Feast', 'Bald Eagles, Great Horned Owls, Falcons & a rare white squirrel', 8, 0.30);

  const SeedKind(this.label, this.attracts, this.feederHours, this.visitRate);

  final String label;
  final String attracts;

  /// How long one bag lasts in the feeder.
  final int feederHours;

  /// Chance that a 10-minute feeder slot brings a visitor (before lures).
  final double visitRate;

  /// The feeder holds up to this many bags of one seed at a time.
  static const maxBagsInFeeder = 3;

  List<BirdSpecies> get visitors => [for (final b in BirdSpecies.values) if (b.seed == this) b];

  static SeedKind? tryParse(String? raw) {
    for (final s in values) {
      if (s.name == raw) return s;
    }
    return null;
  }
}

enum BirdRarity { common, uncommon, rare }

/// Every species (and critter) that can visit the feeder. Each needs a
/// uniform 100 lifetime visits to unlock its keepsake; counts keep growing
/// forever after that.
enum BirdSpecies {
  cardinal('Northern Cardinal', SeedKind.sunflowerMillet, 30, BirdRarity.common, 'Scarlet Crest Feather'),
  blueJay('Blue Jay', SeedKind.sunflowerMillet, 18, BirdRarity.common, 'Sky-Blue Jay Feather'),
  chickadee('Black-capped Chickadee', SeedKind.sunflowerMillet, 30, BirdRarity.common, 'Chickadee Cap Button'),
  robin('American Robin', SeedKind.sunflowerMillet, 22, BirdRarity.common, "Robin's Egg Charm"),
  woodpecker('Red-bellied Woodpecker', SeedKind.berryHickory, 24, BirdRarity.uncommon, 'Drummer Bark Chip'),
  waxwing('Cedar Waxwing', SeedKind.berryHickory, 26, BirdRarity.uncommon, 'Waxwing Wax Seal'),
  oriole('Baltimore Oriole', SeedKind.berryHickory, 22, BirdRarity.uncommon, 'Oriole Sunset Plume'),
  chipmunk('Eastern Chipmunk', SeedKind.berryHickory, 28, BirdRarity.uncommon, 'Striped Cheek Pouch', critter: true),
  baldEagle('Bald Eagle', SeedKind.goldenHusk, 20, BirdRarity.rare, 'Eagle Talon Medal'),
  greatHornedOwl('Great Horned Owl', SeedKind.goldenHusk, 18, BirdRarity.rare, 'Moonlit Owl Tuft', nightOnly: true),
  peregrine('Peregrine Falcon', SeedKind.goldenHusk, 22, BirdRarity.rare, 'Falcon Dive Pin'),
  albinoSquirrel('Albino Squirrel', SeedKind.goldenHusk, 40, BirdRarity.rare, 'Snow-White Tail Tuft', critter: true);

  const BirdSpecies(this.label, this.seed, this.weight, this.rarity, this.keepsake,
      {this.nightOnly = false, this.critter = false});

  final String label;
  final SeedKind seed;

  /// Relative pick weight among the seed's visitors.
  final int weight;
  final BirdRarity rarity;
  final String keepsake;

  /// Only visits between 7pm and 7am.
  final bool nightOnly;

  /// Climbs in along the branch instead of flying.
  final bool critter;

  /// Big birds land on the branch tip instead of the feeder tray.
  bool get large => this == baldEagle || this == greatHornedOwl || this == peregrine;

  static const keepsakeVisits = 100;

  static BirdSpecies? tryParse(String? raw) {
    for (final b in values) {
      if (b.name == raw) return b;
    }
    return null;
  }
}

/// Timed feeder lures and temporary feeder upgrades (bought with Acorns).
enum LureKind {
  berrySuet('Sweet Berry & Suet Cake', '12 hours', 80, 'More visits; woodpeckers, waxwings & orioles love it'),
  moonOil('Moonlight Lantern Oil', '1 night', 120, 'Lights the Owl Lantern; busy nights & owl sightings'),
  deluxeFeast('Deluxe Multi-Perch Feast', '24 hours', 200, 'Extra perches: double visits & more rare guests');

  const LureKind(this.label, this.durationLabel, this.acorns, this.blurb);

  final String label;
  final String durationLabel;
  final int acorns;
  final String blurb;

  /// When a lure bought at [now] wears off. Moonlight oil burns through the
  /// next full night (until a 7am at least six hours away).
  DateTime endsAt(DateTime now) => switch (this) {
        berrySuet => now.add(const Duration(hours: 12)),
        deluxeFeast => now.add(const Duration(hours: 24)),
        moonOil => () {
            var end = DateTime(now.year, now.month, now.day, 7);
            while (end.difference(now).inHours < 6) {
              end = DateTime(end.year, end.month, end.day + 1, 7);
            }
            return end;
          }(),
      };

  static LureKind? tryParse(String? raw) {
    for (final l in values) {
      if (l.name == raw) return l;
    }
    return null;
  }
}

/// One simulated feeder visit.
class BirdVisit {
  const BirdVisit(this.species, this.at, this.lure);
  final BirdSpecies species;
  final DateTime at;
  final LureKind? lure;
}

/// Lifetime Bird & Critter Logbook row (`bird_log` table).
class BirdLogEntry {
  const BirdLogEntry({
    required this.species,
    required this.visits,
    required this.firstSeen,
    required this.lastSeen,
    this.lureTally = const {},
  });

  final BirdSpecies species;
  final int visits;
  final DateTime firstSeen;
  final DateTime lastSeen;

  /// Visits per lure (`none` when no lure was active).
  final Map<String, int> lureTally;

  bool get keepsakeUnlocked => visits >= BirdSpecies.keepsakeVisits;

  /// The lure active during most of this species' visits (null = no lure).
  LureKind? get favoriteLure {
    String? best;
    var top = 0;
    lureTally.forEach((key, n) {
      if (n > top) {
        top = n;
        best = key;
      }
    });
    return LureKind.tryParse(best);
  }

  BirdLogEntry withVisit(BirdVisit v) => BirdLogEntry(
        species: species,
        visits: visits + 1,
        firstSeen: v.at.isBefore(firstSeen) ? v.at : firstSeen,
        lastSeen: v.at.isAfter(lastSeen) ? v.at : lastSeen,
        lureTally: {...lureTally, v.lure?.name ?? 'none': (lureTally[v.lure?.name ?? 'none'] ?? 0) + 1},
      );

  static BirdLogEntry first(BirdVisit v) => BirdLogEntry(
        species: v.species,
        visits: 1,
        firstSeen: v.at,
        lastSeen: v.at,
        lureTally: {v.lure?.name ?? 'none': 1},
      );

  Map<String, Object?> toMap() => {
        'species': species.name,
        'visits': visits,
        'first_seen': firstSeen.toIso8601String(),
        'last_seen': lastSeen.toIso8601String(),
        'lure_tally': [for (final e in lureTally.entries) '${e.key}:${e.value}'].join(','),
      };

  /// Returns null for a retired/unknown species.
  static BirdLogEntry? fromMap(Map<String, Object?> m) {
    final species = BirdSpecies.tryParse(m['species'] as String?);
    if (species == null) return null;
    final tally = <String, int>{};
    for (final part in (m['lure_tally'] as String? ?? '').split(',')) {
      final kv = part.split(':');
      if (kv.length == 2) tally[kv[0]] = int.tryParse(kv[1]) ?? 0;
    }
    return BirdLogEntry(
      species: species,
      visits: (m['visits'] as num).toInt(),
      firstSeen: DateTime.parse(m['first_seen']! as String),
      lastSeen: DateTime.parse(m['last_seen']! as String),
      lureTally: tally,
    );
  }
}
