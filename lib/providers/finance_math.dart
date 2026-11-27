import 'dart:math' as math;

import '../core/dates.dart';
import '../models/bill.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/treat_status.dart';

/// Derived money picture shown in the HUD, drawers and diorama.
class FinanceSummary {
  const FinanceSummary({
    required this.checkingCents,
    required this.allocatedCents,
    required this.freeCashCents,
    required this.upcomingBillsCents,
    required this.unpaidBillCount,
    required this.frost,
    required this.amberCents,
    required this.curioCents,
    required this.treasuryCents,
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
  final int amberCents;
  final int curioCents;
  final int treasuryCents;
  final int netWorthCents;
  final double dailyYieldCents;
  final int oakLevel;

  int reserveCents(ReserveKind kind) => switch (kind) {
        ReserveKind.amber => amberCents,
        ReserveKind.curio => curioCents,
        ReserveKind.treasury => treasuryCents,
      };
}

/// Multi-horizon willpower stats + Sand-Art Silo mix.
class ImpulseStats {
  const ImpulseStats({
    required this.monthCents,
    required this.yearCents,
    required this.allTimeCents,
    required this.unsweptMonthCents,
    required this.skipPct,
    required this.downsizePct,
    required this.diyPct,
  });

  final int monthCents;
  final int yearCents;
  final int allTimeCents;
  final int unsweptMonthCents;
  final int skipPct;
  final int downsizePct;
  final int diyPct;

  /// Silver acorn forged for every $25 saved (all-time).
  int get silverAcorns => allTimeCents ~/ 2500;

  /// Royal Gold acorn forged for every $100 saved (all-time).
  int get goldAcorns => allTimeCents ~/ 10000;

  double get siloFillHeight => FinanceMath.siloFillHeight(monthCents);
}

/// A planned "Sweep to Goal": exactly these unswept wins move into the goal.
class SweepPlan {
  const SweepPlan(this.cents, this.logIds);
  final int cents;
  final Set<String> logIds;
}

/// Pure financial formulas from the blueprint. No Flutter, fully testable.
abstract final class FinanceMath {
  static FinanceSummary summarize({
    required int checkingCents,
    required List<Goal> goals,
    required List<Bill> bills,
    required List<Holding> holdings,
    required int trophyCount,
    required int apyBps,
  }) {
    final allocated = goals.fold<int>(0, (sum, g) => sum + g.savedCents);
    final free = math.max(0, checkingCents - allocated);
    final unpaid = bills.where((b) => !b.paid).toList();
    final upcoming = unpaid.fold<int>(0, (sum, b) => sum + b.amountCents);
    int reserve(ReserveKind k) => holdings
        .where((h) => h.reserve == k)
        .fold<int>(0, (sum, h) => sum + h.valueCents);
    final amber = reserve(ReserveKind.amber);
    final curio = reserve(ReserveKind.curio);
    final treasury = reserve(ReserveKind.treasury);
    return FinanceSummary(
      checkingCents: checkingCents,
      allocatedCents: allocated,
      freeCashCents: free,
      upcomingBillsCents: upcoming,
      unpaidBillCount: unpaid.length,
      frost: upcoming > free,
      amberCents: amber,
      curioCents: curio,
      treasuryCents: treasury,
      netWorthCents: checkingCents + amber + curio + treasury,
      dailyYieldCents: dailyYieldCents(amber, apyBps),
      oakLevel: oakLevel(trophyCount),
    );
  }

  /// Amber Reserve passive yield: balance × APY / 365.
  static double dailyYieldCents(int balanceCents, int apyBps) =>
      balanceCents * (apyBps / 10000) / 365;

  /// Great Oak level: one level per reclaimed trophy, clamped to Lv.1–4.
  static int oakLevel(int trophyCount) => trophyCount.clamp(1, 4);

  /// Green: bills covered and goals empty or ≥45% funded on average.
  /// Yellow: bills covered, goals warming up. Red: frost.
  static TreatStatus treatStatus({
    required bool frost,
    required List<Goal> goals,
  }) {
    if (frost) return TreatStatus.frostAlert;
    if (goals.isEmpty) return TreatStatus.greenlight(hasGoals: false);
    final avg =
        goals.fold<double>(0, (sum, g) => sum + g.progress) / goals.length;
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
      skipPct: skipPct,
      downsizePct: downPct,
      diyPct: math.max(0, 100 - skipPct - downPct),
    );
  }

  /// Silo sand height in diorama units: 14..70 for $0..$150 per month.
  static double siloFillHeight(int monthCents) =>
      math.min(70, math.max(14, monthCents / 100 / 150 * 70)).toDouble();

  /// Free Cash Acorn Pile: 4–15 acorns, one per $400 (none when empty).
  static int acornPileCount(int freeCashCents) {
    if (freeCashCents <= 0) return 0;
    return math.min(15, math.max(4, (freeCashCents / 100 / 400).ceil()));
  }

  /// Golden Leaves for a finished Focus Shift: max(5, minutes × hearth).
  static int focusReward({required int totalSeconds, required int warmth}) {
    final mult = warmth >= 3 ? 1.5 : (warmth == 2 ? 1.25 : 1.0);
    return math.max(5, (totalSeconds / 60 * mult).round());
  }

  /// Two chambers per page plus the "Dig New Goal Room" slot.
  static int maxGoalPage(int goalCount) =>
      math.max(0, ((goalCount + 1) / 2).ceil() - 1);

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
