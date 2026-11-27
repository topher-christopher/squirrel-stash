import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../game/diorama_snapshot.dart';
import '../models/decor.dart';
import '../models/room.dart';
import 'clock_provider.dart';
import 'colony_provider.dart';
import 'finance_math.dart';
import 'finance_providers.dart';
import 'focus_provider.dart';
import 'goals_provider.dart';
import 'reserves_provider.dart';
import 'rooms_provider.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';

/// Combines finance, looks, colony upkeep, focus and UI state into one
/// tree snapshot.
final dioramaSnapshotProvider = Provider<TreeSnapshot>((ref) {
  final settings = ref.watch(settingsProvider);
  final finance = ref.watch(financeProvider);
  final decor = ref.watch(decorProvider);
  final focus = ref.watch(focusProvider);
  final stats = ref.watch(impulseStatsProvider);
  final treat = ref.watch(treatStatusProvider);
  final goals = ref.watch(goalsProvider);
  final rooms = ref.watch(roomsProvider);
  final holdings = ref.watch(holdingsProvider);
  final ui = ref.watch(uiProvider);
  final colony = ref.watch(colonyProvider);
  final expeditions = ref.watch(expeditionsProvider);
  final bags = ref.watch(seedBagsProvider);
  final now = ref.read(clockProvider)();

  bool on(DecorKey k) => decor[k]?.active ?? false;
  final lit = colony.isLit(now);
  final season = Dates.season(now);

  final ordered = [...goals.where((g) => g.priority), ...goals.where((g) => !g.priority)];
  final gains = <RoomKey, bool>{};
  for (final room in RoomKey.values) {
    final kind = room.reserve;
    if (kind == null) continue;
    var gain = 0;
    var tracked = false;
    for (final h in holdings.where((h) => h.reserve == kind)) {
      final g = h.gainCents;
      if (g != null) {
        gain += g;
        tracked = true;
      }
    }
    gains[room] = !tracked || gain >= 0;
  }

  return TreeSnapshot(
    frost: finance.frost,
    twilight: on(DecorKey.twilightSky) || !lit,
    fairyLights: on(DecorKey.fairyLights) && lit,
    outfits: on(DecorKey.hats),
    beacon: on(DecorKey.lanternBeacon),
    seasonal: on(DecorKey.seasonalFoliage),
    season: season,
    treat: treat.level,
    acornPile: FinanceMath.acornPileCount(finance.freeCashCents),
    focusRunning: focus.running,
    focusProgress: focus.progress,
    roomLevels: {for (final r in RoomKey.values) r: rooms.levelOf(r)},
    goals: [
      for (final g in ordered.take(3))
        GoalArt(level: g.roomLevel, percent: g.percent, priority: g.priority),
    ],
    goalCount: goals.length,
    siloFill: stats.siloFillHeight,
    skipFraction: stats.skipPct / 100,
    downsizeFraction: stats.downsizePct / 100,
    diyFraction: stats.diyPct / 100,
    hootHasGift: settings.hootGreetedOn != Dates.dayKey(now),
    paydayBurst: ui.paydayBurst,
    billPressure: finance.upcomingBillsCents == 0
        ? 0
        : (finance.freeCashCents <= 0 ? 2.0 : finance.upcomingBillsCents / finance.freeCashCents),
    trophyCount: ref.watch(awardCountProvider),
    statueCount: ref.watch(trophiesProvider).length,
    oakLevel: finance.oakLevel,
    homeStreak: ref.watch(groceryStatsProvider.select((g) => g.homeStreak)),
    metroRides: ref.watch(metroStatsProvider.select((m) => m.monthRides)),
    pedestals: [for (final p in rooms.pedestals.take(colony.pedestalCount)) p.split(':').first],
    pocketGains: gains,
    lit: lit,
    hearthFuel: colony.fuelFraction(now),
    overdrive: colony.overdriveOn(now),
    festival: colony.festivalOn(now),
    rushHour: colony.rushHourOn(now),
    winter: finance.frost || (on(DecorKey.seasonalFoliage) && season == Season.winter),
    acornBubbles: colony.bubbles,
    feederSeed: colony.seedIn(now),
    feederFill: colony.feederFill(now),
    lure: colony.lureOn(now),
    perched: colony.perched(now),
    squads: colony.squads(now),
    expeditionsOut: expeditions.where((e) => e.active).length,
    seedBags: bags.values.fold(0, (a, b) => a + b),
  );
});
