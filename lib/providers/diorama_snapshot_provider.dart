import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../game/diorama_snapshot.dart';
import '../models/decor.dart';
import '../models/goal.dart';
import 'finance_math.dart';
import 'finance_providers.dart';
import 'focus_provider.dart';
import 'goals_provider.dart';
import 'reserves_provider.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';

/// Goals visible on the current cellar page (two per page).
final visibleGoalsProvider = Provider<List<Goal>>((ref) {
  final goals = ref.watch(goalsProvider);
  final maxPage = FinanceMath.maxGoalPage(goals.length);
  final page = ref.watch(uiProvider.select((u) => u.goalPage)).clamp(0, maxPage);
  final start = page * 2;
  if (start >= goals.length) return const [];
  return goals.sublist(start, (start + 2).clamp(0, goals.length));
});

/// Combines finance, decor, focus and UI state into one diorama snapshot.
final dioramaSnapshotProvider = Provider<DioramaSnapshot>((ref) {
  final settings = ref.watch(settingsProvider);
  final finance = ref.watch(financeProvider);
  final decor = ref.watch(decorProvider);
  final focus = ref.watch(focusProvider);
  final stats = ref.watch(impulseStatsProvider);
  final treat = ref.watch(treatStatusProvider);
  final visible = ref.watch(visibleGoalsProvider);
  final ui = ref.watch(uiProvider);

  bool on(DecorKey k) => decor[k]?.active ?? false;

  final chambers = <ChamberArt?>[
    for (var i = 0; i < 2; i++)
      if (i < visible.length)
        ChamberArt(
          level: visible[i].roomLevel,
          percent: visible[i].percent,
          priority: visible[i].priority,
        )
      else if (i == visible.length)
        const ChamberArt.dig()
      else
        null,
  ];

  return DioramaSnapshot(
    scene: settings.scene,
    frost: finance.frost,
    twilight: on(DecorKey.twilightSky),
    fairyLights: on(DecorKey.fairyLights),
    hats: on(DecorKey.hats),
    espresso: on(DecorKey.espressoBar),
    acornCount: FinanceMath.acornPileCount(finance.freeCashCents),
    oakLevel: finance.oakLevel,
    focusRunning: focus.running,
    focusProgress: focus.progress,
    siloFill: stats.siloFillHeight,
    skipFraction: stats.skipPct / 100,
    downsizeFraction: stats.downsizePct / 100,
    diyFraction: stats.diyPct / 100,
    treat: treat.level,
    forgedSilver: stats.silverAcorns,
    forgedGold: stats.goldAcorns,
    chambers: chambers,
    hootHasGift: settings.hootGreetedOn != Dates.dayKey(DateTime.now()),
    paydayBurst: ui.paydayBurst,
  );
});
