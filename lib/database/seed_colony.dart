import '../models/bird.dart';
import '../models/colony_economy.dart';
import '../models/colony_state.dart';
import '../models/expedition.dart';

/// The demo colony's upkeep state: a lit Hearth, a half-full canopy
/// collector, Sunflower mix in the feeder, a squad out on the ridge, a few
/// bags on hand and a well-thumbed Visitor Logbook.
abstract final class SeedColony {
  static Map<String, String> settings(DateTime now) => ColonyState(
        hearthFuelUntil: now.add(const Duration(hours: 9)),
        collectorProgress: 0.64,
        collectorCheckedAt: now,
        feederSeed: SeedKind.sunflowerMillet,
        feederUntil: now.add(const Duration(hours: 4)),
        birdCheckedAt: now,
        recent: [
          BirdVisit(BirdSpecies.cardinal, now.subtract(const Duration(minutes: 4)), null),
          BirdVisit(BirdSpecies.chickadee, now.subtract(const Duration(minutes: 12)), null),
        ],
      ).toMap();

  /// A fresh stash starts with a warm Hearth (and nothing else).
  static Map<String, String> freshSettings(DateTime now) => ColonyState(
        hearthFuelUntil: now.add(const Duration(hours: ColonyEconomy.welcomeFuelHours)),
        collectorCheckedAt: now,
      ).toMap();

  static List<Expedition> expeditions(DateTime now) => [
        Expedition(
          id: 'exp_demo_1',
          route: ExpeditionRoute.meadowDash,
          startedAt: now.subtract(const Duration(days: 1, hours: 3)),
          endsAt: now.subtract(const Duration(days: 1, hours: 1)),
          acorns: ExpeditionRoute.meadowDash.acorns,
          collectedAt: now.subtract(const Duration(days: 1)),
        ),
        Expedition(
          id: 'exp_demo_2',
          route: ExpeditionRoute.ridgeTrek,
          startedAt: now.subtract(const Duration(hours: 2)),
          endsAt: now.add(const Duration(hours: 4)),
          acorns: ExpeditionRoute.ridgeTrek.acorns,
        ),
      ];

  static const seedBags = {SeedKind.sunflowerMillet: 2, SeedKind.berryHickory: 1};

  static List<BirdLogEntry> birdLog(DateTime now) {
    BirdLogEntry e(BirdSpecies s, int visits, int firstDaysAgo, int lastHoursAgo, Map<String, int> tally) =>
        BirdLogEntry(
          species: s,
          visits: visits,
          firstSeen: now.subtract(Duration(days: firstDaysAgo)),
          lastSeen: now.subtract(Duration(hours: lastHoursAgo)),
          lureTally: tally,
        );
    return [
      e(BirdSpecies.chickadee, 104, 40, 0, {'none': 80, 'berrySuet': 24}),
      e(BirdSpecies.cardinal, 87, 40, 0, {'none': 70, 'deluxeFeast': 17}),
      e(BirdSpecies.robin, 46, 38, 5, {'none': 46}),
      e(BirdSpecies.blueJay, 29, 35, 7, {'none': 21, 'berrySuet': 8}),
      e(BirdSpecies.waxwing, 18, 20, 30, {'berrySuet': 15, 'none': 3}),
      e(BirdSpecies.woodpecker, 11, 20, 52, {'berrySuet': 9, 'none': 2}),
      e(BirdSpecies.chipmunk, 13, 18, 40, {'none': 13}),
      e(BirdSpecies.oriole, 6, 9, 60, {'berrySuet': 6}),
      e(BirdSpecies.albinoSquirrel, 2, 6, 120, {'none': 2}),
      e(BirdSpecies.peregrine, 1, 6, 130, {'deluxeFeast': 1}),
    ];
  }
}
