import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/treat_status.dart';
import 'bills_provider.dart';
import 'finance_math.dart';
import 'goals_provider.dart';
import 'impulse_provider.dart';
import 'reserves_provider.dart';
import 'settings_provider.dart';

/// Free cash, frostline, reserves, net worth, oak level.
final financeProvider = Provider<FinanceSummary>((ref) {
  final settings = ref.watch(settingsProvider);
  return FinanceMath.summarize(
    checkingCents: settings.checkingCents,
    goals: ref.watch(goalsProvider),
    bills: ref.watch(billsProvider),
    holdings: ref.watch(holdingsProvider),
    trophyCount: ref.watch(trophiesProvider).length,
    apyBps: settings.brokerageApyBps,
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
  return FinanceMath.impulseStats(
      ref.watch(impulseLogsProvider), DateTime.now());
});
