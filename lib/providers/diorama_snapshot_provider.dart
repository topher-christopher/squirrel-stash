import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../game/diorama_snapshot.dart';
import '../models/decor.dart';
import '../models/room.dart';
import 'bills_provider.dart';
import 'finance_math.dart';
import 'finance_providers.dart';
import 'focus_provider.dart';
import 'goals_provider.dart';
import 'reserves_provider.dart';
import 'rooms_provider.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';

/// Short labels for the Etch A Sketch board.
String etchLabel(String name) {
  final n = name.toLowerCase();
  if (n.contains('southwest')) return 'Southwest';
  if (n.contains('amazon')) return 'Amazon';
  if (n.contains('quicksilver')) return 'Quicksilver';
  if (n.contains('rent')) return 'Rent';
  return name.length > 11 ? '${name.substring(0, 10)}…' : name;
}

/// Combines finance, upgrades, focus and UI state into one tree snapshot.
final dioramaSnapshotProvider = Provider<TreeSnapshot>((ref) {
  final settings = ref.watch(settingsProvider);
  final finance = ref.watch(financeProvider);
  final decor = ref.watch(decorProvider);
  final focus = ref.watch(focusProvider);
  final stats = ref.watch(impulseStatsProvider);
  final treat = ref.watch(treatStatusProvider);
  final goals = ref.watch(goalsProvider);
  final rooms = ref.watch(roomsProvider);
  final bills = ref.watch(billsProvider);
  final holdings = ref.watch(holdingsProvider);
  final ui = ref.watch(uiProvider);
  final now = DateTime.now();

  final preview = ui.previewMax;
  bool on(DecorKey k) => preview || (decor[k]?.active ?? false);

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
    twilight: on(DecorKey.twilightSky),
    fairyLights: on(DecorKey.fairyLights),
    outfits: on(DecorKey.hats),
    beacon: on(DecorKey.lanternBeacon),
    seasonal: on(DecorKey.seasonalFoliage),
    season: Dates.season(now),
    treat: treat.level,
    acornPile: FinanceMath.acornPileCount(finance.freeCashCents),
    focusRunning: focus.running,
    focusProgress: focus.progress,
    roomLevels: {
      for (final r in RoomKey.values) r: preview ? RoomLevels.max : rooms.levelOf(r),
    },
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
    etch: [
      for (final b in bills.take(5)) EtchLine(etchLabel(b.name), b.daysUntilDue(now), b.paid),
    ],
    billCoverage: finance.upcomingBillsCents == 0
        ? 1.4
        : finance.freeCashCents / finance.upcomingBillsCents,
    trophyCount: ref.watch(awardCountProvider) + (preview ? 30 : 0),
    statueCount: ref.watch(trophiesProvider).length + (preview ? 4 : 0),
    oakLevel: finance.oakLevel,
    homeStreak: ref.watch(groceryStatsProvider.select((g) => g.homeStreak)),
    metroRides: ref.watch(metroStatsProvider.select((m) => m.monthRides)),
    pedestals: [for (final p in rooms.pedestals) p.split(':').first],
    pocketGains: gains,
  );
});
