import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_stash/core/dates.dart';
import 'package:squirrel_stash/core/money.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/models/bill.dart';
import 'package:squirrel_stash/models/goal.dart';
import 'package:squirrel_stash/models/holding.dart';
import 'package:squirrel_stash/models/impulse.dart';
import 'package:squirrel_stash/models/treat_status.dart';
import 'package:squirrel_stash/providers/economy.dart';
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

ImpulseLog _log(String id, ImpulseMode mode, int cents, DateTime at, {bool swept = false}) =>
    ImpulseLog(id: id, label: id, mode: mode, amountCents: cents, loggedAt: at, swept: swept);

void main() {
  final now = DateTime(2026, 11, 27, 15);
  final demo = SeedData.demo(now);

  group('FinanceMath.summarize (demo Great Oak)', () {
    final f = FinanceMath.summarize(
      checkingCents: 760000,
      goals: demo.goals,
      bills: demo.bills,
      holdings: demo.holdings,
      trophyCount: demo.trophies.length,
    );

    test('free cash = checking − goal allocations', () {
      expect(f.allocatedCents, 400000);
      expect(f.freeCashCents, 360000);
    });

    test('preset bills: 4 cards + rent are unpaid; no frost while covered', () {
      expect(f.unpaidBillCount, 5);
      expect(f.upcomingBillsCents, (412 + 286 + 198 + 534 + 1650) * 100);
      expect(f.frost, isFalse);
    });

    test('seven vault pockets use live prices for ticker holdings', () {
      expect(f.reserveCents(ReserveKind.brokerage), 1215925 + 388800 + 125000);
      expect(f.reserveCents(ReserveKind.crypto), 405300 + 224250);
      expect(f.reserveCents(ReserveKind.silver), 163280);
      expect(f.reserveCents(ReserveKind.retirement), 6230000);
      expect(f.netWorthCents, 760000 + f.vaultsCents);
    });

    test('no automatic APY: daily yield is zero until an APY is entered', () {
      expect(f.dailyYieldCents, 0);
      const hysa = Holding(id: 'x', reserve: ReserveKind.hysa, label: 'HYSA', valueCents: 800000, apyPercent: 4.6);
      expect(Money.exact(hysa.dailyYieldCents.round()), r'$1.01');
    });

    test('frost when unpaid bills exceed free cash', () {
      final frosty = FinanceMath.summarize(
          checkingCents: 600000, goals: demo.goals, bills: demo.bills, holdings: const [], trophyCount: 0);
      expect(frosty.freeCashCents, 200000);
      expect(frosty.frost, isTrue);
    });

    test('oak level clamps to 1–4', () {
      expect(FinanceMath.oakLevel(0), 1);
      expect(FinanceMath.oakLevel(3), 3);
      expect(FinanceMath.oakLevel(9), 4);
    });
  });

  group('Treat Yourself lantern', () {
    test('red during frost, green with no goals', () {
      expect(FinanceMath.treatStatus(frost: true, goals: const []).level, TreatLevel.red);
      expect(FinanceMath.treatStatus(frost: false, goals: const []).level, TreatLevel.green);
    });
    test('green at ≥45% average, yellow below', () {
      expect(FinanceMath.treatStatus(frost: false, goals: [_goal(45, 100)]).level, TreatLevel.green);
      expect(FinanceMath.treatStatus(frost: false, goals: [_goal(44, 100)]).level, TreatLevel.yellow);
      expect(FinanceMath.treatStatus(frost: false, goals: [_goal(200, 100), _goal(0, 100)]).level, TreatLevel.green);
    });
  });

  test('impulse horizons and silo mix', () {
    final logs = [
      _log('a', ImpulseMode.skip, 2500, DateTime(2026, 11, 3)),
      _log('b', ImpulseMode.downsize, 500, DateTime(2026, 11, 4)),
      _log('c', ImpulseMode.diy, 2000, DateTime(2026, 11, 5), swept: true),
      _log('d', ImpulseMode.skip, 10000, DateTime(2026, 2, 1)),
      _log('e', ImpulseMode.skip, 9000, DateTime(2025, 7, 1)),
    ];
    final s = FinanceMath.impulseStats(logs, now);
    expect(s.monthCents, 5000);
    expect(s.yearCents, 15000);
    expect(s.allTimeCents, 24000);
    expect(s.unsweptMonthCents, 3000);
    expect(s.monthCount, 3);
    expect((s.skipPct, s.downsizePct, s.diyPct), (50, 10, 40));
    expect(FinanceMath.siloFillHeight(0), 0.12);
    expect(FinanceMath.siloFillHeight(999999), 1);
  });

  test('acorn pile: none when empty, 4–15 otherwise', () {
    expect(FinanceMath.acornPileCount(0), 0);
    expect(FinanceMath.acornPileCount(100), 4);
    expect(FinanceMath.acornPileCount(360000), 9);
    expect(FinanceMath.acornPileCount(10000000), 15);
  });

  test('economy: 10 Acorns per \$1, a Golden Acorn per \$100, focus rewards', () {
    expect(Economy.acornsForSavings(1200), 120);
    expect(Economy.acornsForSavings(225), 22);
    expect(Economy.goldenMilestones(19999), 1);
    expect(Economy.goldenMilestones(20000), 2);
    expect(Economy.focusReward(totalSeconds: 10, warmth: 3), 10);
    expect(Economy.focusReward(totalSeconds: 1500, warmth: 1), 50);
    expect(Economy.focusReward(totalSeconds: 1500, warmth: 2), 63);
  });

  test('sweep moves whole unswept month wins, capped by free cash', () {
    final logs = [
      _log('a', ImpulseMode.skip, 1000, DateTime(2026, 11, 2)),
      _log('b', ImpulseMode.skip, 2500, DateTime(2026, 11, 3)),
      _log('c', ImpulseMode.skip, 700, DateTime(2026, 11, 4), swept: true),
      _log('d', ImpulseMode.skip, 900, DateTime(2026, 10, 30)),
    ];
    expect(FinanceMath.planSweep(logs, 999999, now).logIds, {'a', 'b'});
    expect(FinanceMath.planSweep(logs, 2000, now).cents, 1000);
  });

  group('recurring bills', () {
    test('next occurrence clamps short months and rolls past today', () {
      expect(Bill.nextOccurrence(28, DateTime(2026, 11, 27)), DateTime(2026, 11, 28));
      expect(Bill.nextOccurrence(9, DateTime(2026, 11, 27)), DateTime(2026, 12, 9));
      expect(Bill.nextOccurrence(31, DateTime(2027, 2, 3)), DateTime(2027, 2, 28));
    });

    test('days until due and the paid → next cycle rollover', () {
      final bill = Bill(id: 'b', name: 'TD Cash', amountCents: 1, dueDate: DateTime(2026, 12, 1),
          dueDay: 1, kind: BillKind.card);
      expect(bill.daysUntilDue(DateTime(2026, 11, 27, 22)), 4);
      expect(bill.cycleKey, '2026-12');
      final paid = bill.copyWith(paid: true);
      expect(paid.rolledForward(DateTime(2026, 11, 30)).paid, isTrue, reason: 'not due yet');
      final rolled = paid.rolledForward(DateTime(2026, 12, 2));
      expect((rolled.paid, rolled.dueDate), (false, DateTime(2027, 1, 1)));
    });
  });

  test('dates: ISO weeks, seasons and month keys', () {
    expect(Dates.weekKey(DateTime(2026, 11, 27)), '2026-W48');
    expect(Dates.weekKey(DateTime(2027, 1, 1)), '2026-W53');
    expect(Dates.seasonKey(DateTime(2027, 1, 15)), '2026-winter');
    expect(Dates.seasonKey(DateTime(2026, 4, 1)), '2026-spring');
    expect(Dates.monthKey(DateTime(2026, 3, 9)), '2026-03');
  });

  test('Money parsing and formatting', () {
    expect(Money.parse(r' $1,250.50 '), 125050);
    expect(Money.parse('-3'), isNull);
    expect(Money.whole(605000), r'$6,050');
    expect(Money.smart(250), r'$2.50');
    expect(Money.plain(460), '4.6');
  });
}
