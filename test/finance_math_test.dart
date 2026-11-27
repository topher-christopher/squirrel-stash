import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_stash/core/money.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/models/goal.dart';
import 'package:squirrel_stash/models/impulse.dart';
import 'package:squirrel_stash/models/treat_status.dart';
import 'package:squirrel_stash/providers/finance_math.dart';

Goal _goal(int saved, int target) => Goal(
      id: 'g$saved',
      name: 'G',
      icon: '🎯',
      savedCents: saved,
      targetCents: target,
      dueDate: DateTime(2027),
      createdAt: DateTime(2026),
    );

void main() {
  final now = DateTime(2026, 11, 26, 15);
  final demo = SeedData.demo(now);

  group('FinanceMath.summarize (blueprint demo numbers)', () {
    final f = FinanceMath.summarize(
      checkingCents: 605000,
      goals: demo.goals,
      bills: demo.bills,
      holdings: demo.holdings,
      trophyCount: demo.trophies.length,
      apyBps: 460,
    );

    test('free cash = checking − goal allocations', () {
      expect(f.allocatedCents, 400000);
      expect(f.freeCashCents, 205000);
    });

    test('upcoming bills exclude paid ones; no frost while covered', () {
      expect(f.upcomingBillsCents, 185000);
      expect(f.frost, isFalse);
    });

    test('net worth = checking + reserves', () {
      expect(f.amberCents, 2450000);
      expect(f.curioCents, 510000);
      expect(f.treasuryCents, 6230000);
      expect(f.netWorthCents, 605000 + 2450000 + 510000 + 6230000);
    });

    test('daily passive yield = balance × APY / 365', () {
      expect(Money.exact(f.dailyYieldCents.round()), r'$3.09');
    });

    test('oak level clamps to 1–4', () {
      expect(FinanceMath.oakLevel(0), 1);
      expect(FinanceMath.oakLevel(3), 3);
      expect(FinanceMath.oakLevel(9), 4);
    });

    test('frost when unpaid bills exceed free cash', () {
      final frosty = FinanceMath.summarize(
        checkingCents: 500000,
        goals: demo.goals,
        bills: demo.bills,
        holdings: const [],
        trophyCount: 0,
        apyBps: 460,
      );
      expect(frosty.freeCashCents, 100000);
      expect(frosty.frost, isTrue);
    });
  });

  group('Treat Yourself lantern', () {
    test('red during frost', () {
      expect(FinanceMath.treatStatus(frost: true, goals: const []).level, TreatLevel.red);
    });
    test('green with no goals', () {
      expect(FinanceMath.treatStatus(frost: false, goals: const []).level, TreatLevel.green);
    });
    test('green at ≥45% average, yellow below', () {
      expect(FinanceMath.treatStatus(frost: false, goals: [_goal(45, 100)]).level, TreatLevel.green);
      expect(FinanceMath.treatStatus(frost: false, goals: [_goal(44, 100)]).level, TreatLevel.yellow);
      expect(FinanceMath.treatStatus(frost: false, goals: [_goal(200, 100), _goal(0, 100)]).level,
          TreatLevel.green, reason: 'progress is capped at 100% per goal → avg 50%');
    });
  });

  group('Impulse silo', () {
    final stats = FinanceMath.impulseStats(demo.logs, now);

    test('month / year / all-time horizons', () {
      expect(stats.monthCents, 4650);
      expect(stats.yearCents, 4650 + 59350);
      expect(stats.allTimeCents, 192000);
    });

    test('forged acorns: silver per \$25, gold per \$100', () {
      expect(stats.silverAcorns, 76);
      expect(stats.goldAcorns, 19);
    });

    test('sand mix sums to 100 with DIY taking the remainder', () {
      expect(stats.skipPct, 69);
      expect(stats.downsizePct, 5);
      expect(stats.diyPct, 26);
    });

    test('silo fill height clamps to 14..70', () {
      expect(FinanceMath.siloFillHeight(0), 14);
      expect(FinanceMath.siloFillHeight(7500), closeTo(35, 0.001));
      expect(FinanceMath.siloFillHeight(999999), 70);
    });
  });

  test('acorn pile: none when empty, 4–15 otherwise', () {
    expect(FinanceMath.acornPileCount(0), 0);
    expect(FinanceMath.acornPileCount(100), 4);
    expect(FinanceMath.acornPileCount(205000), 6);
    expect(FinanceMath.acornPileCount(10000000), 15);
  });

  test('focus reward: max(5, minutes × hearth multiplier)', () {
    expect(FinanceMath.focusReward(totalSeconds: 10, warmth: 3), 5);
    expect(FinanceMath.focusReward(totalSeconds: 1500, warmth: 1), 25);
    expect(FinanceMath.focusReward(totalSeconds: 1500, warmth: 2), 31);
    expect(FinanceMath.focusReward(totalSeconds: 2700, warmth: 3), 68);
  });

  test('goal paging reserves a slot for "Dig New Goal Room"', () {
    expect(FinanceMath.maxGoalPage(0), 0);
    expect(FinanceMath.maxGoalPage(1), 0);
    expect(FinanceMath.maxGoalPage(2), 1);
    expect(FinanceMath.maxGoalPage(3), 1);
    expect(FinanceMath.maxGoalPage(4), 2);
  });

  test('sweep moves whole unswept month wins, capped by free cash', () {
    final logs = [
      ImpulseLog(id: 'a', label: 'a', mode: ImpulseMode.skip, amountCents: 1000, loggedAt: DateTime(2026, 11, 2)),
      ImpulseLog(id: 'b', label: 'b', mode: ImpulseMode.skip, amountCents: 2500, loggedAt: DateTime(2026, 11, 3)),
      ImpulseLog(id: 'c', label: 'c', mode: ImpulseMode.skip, amountCents: 700, loggedAt: DateTime(2026, 11, 4), swept: true),
      ImpulseLog(id: 'd', label: 'd', mode: ImpulseMode.skip, amountCents: 900, loggedAt: DateTime(2026, 10, 30)),
    ];
    final all = FinanceMath.planSweep(logs, 999999, now);
    expect(all.cents, 3500);
    expect(all.logIds, {'a', 'b'});
    final capped = FinanceMath.planSweep(logs, 2000, now);
    expect(capped.cents, 1000);
    expect(capped.logIds, {'a'});
  });

  test('Money parsing and formatting', () {
    expect(Money.parse(r' $1,250.50 '), 125050);
    expect(Money.parse('7.5'), 750);
    expect(Money.parse('-3'), isNull);
    expect(Money.parse('abc'), isNull);
    expect(Money.whole(605000), r'$6,050');
    expect(Money.smart(250), r'$2.50');
    expect(Money.smart(1200), r'$12');
    expect(Money.plain(460), '4.6');
  });
}
