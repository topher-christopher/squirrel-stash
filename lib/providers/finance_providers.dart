import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feat.dart';
import '../models/treat_status.dart';
import 'awards_provider.dart';
import 'bills_provider.dart';
import 'card_insights.dart';
import 'finance_math.dart';
import 'goals_provider.dart';
import 'impulse_provider.dart';
import 'kitchen_metro_math.dart';
import 'kitchen_metro_provider.dart';
import 'reserves_provider.dart';
import 'settings_provider.dart';
import 'stats_engine.dart';

/// Free cash, frostline, vault pockets, net worth, oak level.
final financeProvider = Provider<FinanceSummary>((ref) {
  return FinanceMath.summarize(
    checkingCents: ref.watch(settingsProvider.select((s) => s.checkingCents)),
    goals: ref.watch(goalsProvider),
    bills: ref.watch(billsProvider),
    holdings: ref.watch(holdingsProvider),
    trophyCount: ref.watch(trophiesProvider).length,
  );
});

/// Green / Yellow / Red "Treat Yourself!" lantern.
final treatStatusProvider = Provider<TreatStatus>((ref) {
  return FinanceMath.treatStatus(
    frost: ref.watch(financeProvider.select((f) => f.frost)),
    goals: ref.watch(goalsProvider),
  );
});

/// Month / Year / All-Time willpower totals and silo mix.
final impulseStatsProvider = Provider<ImpulseStats>((ref) {
  return FinanceMath.impulseStats(ref.watch(impulseLogsProvider), DateTime.now());
});

/// Per-card and combined statement trends (Hollow Log Bill Vault).
final cardInsightsProvider = Provider<CardInsights>((ref) {
  return CardInsights.compute(ref.watch(billsProvider), ref.watch(statementsProvider));
});

final groceryStatsProvider = Provider<GroceryStats>((ref) {
  return KitchenMetroMath.grocery(
    trips: ref.watch(groceriesProvider),
    logs: ref.watch(impulseLogsProvider),
    habits: ref.watch(habitsProvider),
    now: DateTime.now(),
  );
});

final metroStatsProvider = Provider<MetroStats>((ref) {
  return KitchenMetroMath.metro(
    rides: ref.watch(ridesProvider),
    logs: ref.watch(impulseLogsProvider),
    habits: ref.watch(habitsProvider),
    now: DateTime.now(),
  );
});

/// Trophy Hall dashboard for one timeframe pill.
final dashboardStatsProvider = Provider.family<DashboardStats, StatsRange>((ref, range) {
  return StatsEngine.compute(
    range: range,
    now: DateTime.now(),
    logs: ref.watch(impulseLogsProvider),
    habits: ref.watch(habitsProvider),
    groceries: ref.watch(groceriesProvider),
    rides: ref.watch(ridesProvider),
    trophies: ref.watch(trophiesProvider),
  );
});

/// Number of earned feat rows (drives Trophy Hall shelf fill).
final awardCountProvider = Provider<int>((ref) =>
    ref.watch(awardsProvider).where((a) => a.featKey != Feats.fourSeasonsStage).length);
