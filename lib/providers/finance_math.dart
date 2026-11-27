import 'dart:math' as math;

import '../core/dates.dart';
import '../models/bill.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/treat_status.dart';

/// Derived money picture shown in the HUD, drawers and the Great Oak.
class FinanceSummary {
  const FinanceSummary({
    required this.checkingCents,
    required this.allocatedCents,
    required this.freeCashCents,
    required this.upcomingBillsCents,
    required this.unpaidBillCount,
    required this.frost,
    required this.reserves,
    required this.netWorthCents,
    required this.dailyYieldCents,
    required this.oakLevel,
  });

  final int checkingCents;
  final int allocatedCents;
  final int freeCashCents;
  final int upcomingBillsCents;
  final int unpaidBillCount;
  final bool frost;

  /// Current value of each deep-root vault pocket.
  final Map<ReserveKind, int> reserves;
  final int netWorthCents;

  /// Passive yield from holdings that have a manually entered APY.
  final double dailyYieldCents;
  final int oakLevel;

  int reserveCents(ReserveKind kind) => reserves[kind] ?? 0;

  int get vaultsCents => reserves.values.fold(0, (s, v) => s + v);
}

/// Willpower totals + the Foraging Lab silo sand mix.
class ImpulseStats {
  const ImpulseStats({
    required this.monthCents,
    required this.yearCents,
    required this.allTimeCents,
    required this.unsweptMonthCents,
    required this.monthCount,
    required this.skipPct,
    required this.downsizePct,
    required this.diyPct,
  });

  final int monthCents;
  final int yearCents;
  final int allTimeCents;
  final int unsweptMonthCents;
  final int monthCount;
  final int skipPct;
  final int downsizePct;
  final int diyPct;

  double get siloFillHeight => FinanceMath.siloFillHeight(monthCents);
}

/// A planned "Sweep to Goal": exactly these unswept wins move into the goal.
class SweepPlan {
  const SweepPlan(this.cents, this.logIds);
  final int cents;
  final Set<String> logIds;
}

/// Pure financial formulas. No Flutter, fully testable.
abstract final class FinanceMath {
  static FinanceSummary summarize({
    required int checkingCents,
    required List<Goal> goals,
    required List<Bill> bills,
    required List<Holding> holdings,
    required int trophyCount,
  }) {
    final allocated = goals.fold<int>(0, (sum, g) => sum + g.savedCents);
    final free = math.max(0, checkingCents - allocated);
    final unpaid = bills.where((b) => !b.paid).toList();
    final upcoming = unpaid.fold<int>(0, (sum, b) => sum + b.amountCents);
    final reserves = {for (final k in ReserveKind.values) k: 0};
    var yield = 0.0;
    for (final h in holdings) {
      reserves[h.reserve] = reserves[h.reserve]! + h.currentValueCents;
      yield += h.dailyYieldCents;
    }
    final vaults = reserves.values.fold<int>(0, (s, v) => s + v);
    return FinanceSummary(
      checkingCents: checkingCents,
      allocatedCents: allocated,
      freeCashCents: free,
      upcomingBillsCents: upcoming,
      unpaidBillCount: unpaid.length,
      frost: upcoming > free,
      reserves: reserves,
      netWorthCents: checkingCents + vaults,
      dailyYieldCents: yield,
      oakLevel: oakLevel(trophyCount),
    );
  }

  /// Passive yield: balance × APY / 365.
  static double dailyYieldCents(int balanceCents, double apyPercent) =>
      balanceCents * apyPercent / 100 / 365;

  /// Great Oak level: one level per reclaimed goal, clamped to Lv.1–4.
  static int oakLevel(int trophyCount) => trophyCount.clamp(1, 4);

  /// Green: bills covered and goals empty or ≥45% funded on average.
  /// Yellow: bills covered, goals warming up. Red: frost.
  static TreatStatus treatStatus({
    required bool frost,
    required List<Goal> goals,
  }) {
    if (frost) return TreatStatus.frostAlert;
    if (goals.isEmpty) return TreatStatus.greenlight(hasGoals: false);
    final avg = goals.fold<double>(0, (sum, g) => sum + g.progress) / goals.length;
    return avg >= 0.45
        ? TreatStatus.greenlight(hasGoals: true)
        : TreatStatus.mindfulPace;
  }

  static ImpulseStats impulseStats(List<ImpulseLog> logs, DateTime now) {
    final month = logs.where((l) => Dates.sameMonth(l.loggedAt, now)).toList();
    int sum(Iterable<ImpulseLog> items) =>
        items.fold<int>(0, (s, l) => s + l.amountCents);
    final monthTotal = sum(month);
    final denominator = math.max(1, monthTotal);
    int modeSum(ImpulseMode m) => sum(month.where((l) => l.mode == m));
    final skipPct = (modeSum(ImpulseMode.skip) / denominator * 100).round();
    final downPct = (modeSum(ImpulseMode.downsize) / denominator * 100).round();
    return ImpulseStats(
      monthCents: monthTotal,
      yearCents: sum(logs.where((l) => Dates.sameYear(l.loggedAt, now))),
      allTimeCents: sum(logs),
      unsweptMonthCents: sum(month.where((l) => !l.swept)),
      monthCount: month.length,
      skipPct: skipPct,
      downsizePct: downPct,
      diyPct: monthTotal == 0 ? 0 : math.max(0, 100 - skipPct - downPct),
    );
  }

  /// Silo sand height in room units: 0..1 for $0..$150 per month.
  static double siloFillHeight(int monthCents) =>
      math.min(1, math.max(0.12, monthCents / 100 / 150)).toDouble();

  /// Free Cash Acorn Pile: 4–15 acorns, one per $400 (none when empty).
  static int acornPileCount(int freeCashCents) {
    if (freeCashCents <= 0) return 0;
    return math.min(15, math.max(4, (freeCashCents / 100 / 400).ceil()));
  }

  /// Sweeps this month's unswept wins (oldest first) into a goal, capped by
  /// free cash. Only whole wins move, so nothing is ever swept twice.
  static SweepPlan planSweep(
    List<ImpulseLog> logs,
    int freeCashCents,
    DateTime now,
  ) {
    final candidates = logs
        .where((l) => !l.swept && Dates.sameMonth(l.loggedAt, now))
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    var total = 0;
    final ids = <String>{};
    for (final log in candidates) {
      if (total + log.amountCents > freeCashCents) break;
      total += log.amountCents;
      ids.add(log.id);
    }
    return SweepPlan(total, ids);
  }
}
