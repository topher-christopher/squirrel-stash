import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/models/bill.dart';
import 'package:squirrel_stash/models/feat.dart';
import 'package:squirrel_stash/models/grocery_trip.dart';
import 'package:squirrel_stash/models/impulse.dart';
import 'package:squirrel_stash/models/metro_ride.dart';
import 'package:squirrel_stash/providers/card_insights.dart';
import 'package:squirrel_stash/providers/feat_engine.dart';
import 'package:squirrel_stash/providers/kitchen_metro_math.dart';
import 'package:squirrel_stash/providers/stats_engine.dart';

final _habits = SeedData.defaultHabits;

ImpulseLog _log(int i, DateTime at, {String habit = 'h_icecream', int cents = 700}) =>
    ImpulseLog(id: 'l$i', label: habit, mode: ImpulseMode.skip, amountCents: cents, loggedAt: at, habitId: habit);

List<FeatAward> _eval(List<ImpulseLog> logs,
        {List<MetroRide> rides = const [], List<FeatAward> awards = const [], int focus = 0, int goals = 0}) =>
    FeatEngine.evaluate(FeatInputs(
      logs: logs, habits: _habits, rides: rides, groceries: const [], awards: awards,
      focusShifts: focus, goalsReclaimed: goals, now: DateTime(2026, 11, 27),
    ));

void main() {
  group('card insight badges (neutral, rolling)', () {
    test('near the 6-month average', () {
      expect(CardInsights.badgeFor([380, 455, 402, 498, 365, 430, 412]), 'Near 6-mo average');
    });
    test('lowest / highest runs', () {
      expect(CardInsights.badgeFor([500, 450, 400, 350]), 'Lowest in 4 months');
      expect(CardInsights.badgeFor([100, 200, 300, 400, 500, 600]), 'Highest in 6 months');
      expect(CardInsights.badgeFor([300, 300, 500, 200, 600, 900, 450]), 'Lowest in 3 months');
    });
    test('needs three statements', () => expect(CardInsights.badgeFor([400, 300]), isNull));

    test('per-card MoM, cycle-aligned combined total and spend share', () {
      final now = DateTime(2026, 11, 27);
      final bills = SeedData.presetBills(now);
      final demo = SeedData.demo(now);
      final insights = CardInsights.compute(bills, demo.statements);
      expect(insights.cards.map((c) => c.name), contains('Chase Southwest Rapid Rewards'));
      final td = insights.cards.firstWhere((c) => c.bill!.id == 'b_td');
      expect(td.latest, 41200);
      expect(td.deltaCents, 41200 - 43000);
      expect(td.deltaPercent!.round(), -4);
      expect(insights.combined.latest, (412 + 286 + 198 + 534) * 100);
      expect(insights.combined.previous, (430 + 301 + 225 + 498) * 100);
      expect(insights.shares.fold<double>(0, (s, v) => s + v), closeTo(1, 1e-9));
      expect(insights.cards.any((c) => c.bill!.kind != BillKind.card), isFalse, reason: 'rent is not a card');
    });
  });

  group('trophy engine', () {
    test('Forged Iron Shield stacks per calendar month with 10+ wins', () {
      final nov = [for (var i = 0; i < 10; i++) _log(i, DateTime(2026, 11, 1 + i, 12))];
      final oct = [for (var i = 0; i < 9; i++) _log(100 + i, DateTime(2026, 10, 1 + i, 12))];
      final awards = _eval([...nov, ...oct]);
      final shields = awards.where((a) => a.featKey == Feats.ironShield).toList();
      expect(shields.map((a) => a.periodKey), ['2026-11']);
      expect(shields.single.acorns, 50);
      expect(_eval([...nov, ...oct], awards: awards), isEmpty, reason: 'never pays twice');
    });

    test('Copper Skillet: 10 home-cooked meals in one ISO week', () {
      final meals = [for (var i = 0; i < 10; i++) _log(i, DateTime(2026, 11, 23 + i % 5, 8 + i), habit: 'h_cook')];
      expect(_eval(meals).where((a) => a.featKey == Feats.copperSkillet).map((a) => a.periodKey), ['2026-W48']);
    });

    test('Four-Seasons Forager pays a Golden Acorn per full set', () {
      final logs = [
        _log(1, DateTime(2026, 4, 1)), _log(2, DateTime(2026, 7, 1)),
        _log(3, DateTime(2026, 10, 1)), _log(4, DateTime(2026, 12, 5)),
      ];
      final sets = _eval(logs).where((a) => a.featKey == Feats.fourSeasons).toList();
      expect(sets.single.golden, 1);
    });

    test('lifelong ladders pay every tier reached', () {
      final logs = [for (var i = 0; i < 20; i++) _log(i, DateTime(2026, 6, 1 + i), cents: 2500)];
      final saved = _eval(logs).where((a) => a.featKey == Feats.ladderSaved).map((a) => a.periodKey);
      expect(saved, ['tier1', 'tier2'], reason: '\$500 lifetime');
      final wins = _eval(logs).where((a) => a.featKey == Feats.ladderWins).map((a) => a.periodKey);
      expect(wins, ['tier1']);
      expect(_eval(const [], focus: 25, goals: 3).where((a) => a.featKey == Feats.ladderFocus).length, 2);
    });

    test('data-driven mystery feats', () {
      final keys = _eval([
        _log(1, DateTime(2026, 11, 2, 23, 30)),
        _log(2, DateTime(2026, 11, 3, 5, 10)),
        for (var d = 0; d < 30; d++) _log(10 + d, DateTime(2026, 9, 1 + d, 12)),
      ], rides: [
        for (var i = 0; i < 10; i++)
          MetroRide(id: 'r$i', fare: MetroFare.shortHop, amountCents: 225, rideAt: DateTime(2026, 11, 23, 8 + i)),
      ]).map((a) => a.featKey).toSet();
      expect(keys, containsAll([Feats.nightOwl, Feats.dawnChorus, Feats.rushHour, Feats.unbreakableOak]));
    });

    test('event mystery awards are one-time', () {
      final first = FeatEngine.mysteryAward(Feats.windowShopper, const [], DateTime(2026));
      expect(first!.acorns, 75);
      expect(FeatEngine.mysteryAward(Feats.windowShopper, [first], DateTime(2026)), isNull);
    });
  });

  group('kitchen, metro & stats', () {
    final now = DateTime(2026, 11, 27, 18);
    test('grocery averages and home-cooked streak', () {
      final trips = [
        GroceryTrip(id: 'a', store: 'A', amountCents: 6000, tripAt: DateTime(2026, 11, 20)),
        GroceryTrip(id: 'b', store: 'B', amountCents: 9000, tripAt: DateTime(2026, 11, 25)),
        GroceryTrip(id: 'c', store: 'C', amountCents: 3000, tripAt: DateTime(2026, 11, 10)),
      ];
      final meals = [for (var d = 0; d < 4; d++) _log(d, DateTime(2026, 11, 27 - d, 19), habit: 'h_cook')];
      final g = KitchenMetroMath.grocery(trips: trips, logs: meals, habits: _habits, now: now);
      expect((g.monthCents, g.monthTrips, g.avgPerTripCents), (18000, 3, 6000));
      expect(g.avgDaysBetween, 7.5);
      expect((g.homeMealsMonth, g.homeStreak), (4, 4));
    });

    test('metro fare breakdown counts this month only', () {
      final rides = [
        MetroRide(id: '1', fare: MetroFare.weekdayMax, amountCents: 675, rideAt: DateTime(2026, 11, 3)),
        MetroRide(id: '2', fare: MetroFare.shortHop, amountCents: 225, rideAt: DateTime(2026, 11, 4)),
        MetroRide(id: '3', fare: MetroFare.shortHop, amountCents: 225, rideAt: DateTime(2026, 10, 4)),
      ];
      final m = KitchenMetroMath.metro(rides: rides, logs: const [], habits: _habits, now: now);
      expect((m.monthRides, m.monthCents, m.allRides), (2, 900, 3));
      expect(m.monthByFare[MetroFare.shortHop], (1, 225));
    });

    test('dashboard: per-habit totals, best month and timeframe filters', () {
      final logs = [
        _log(1, DateTime(2026, 11, 2), habit: 'h_water', cents: 900),
        _log(2, DateTime(2026, 11, 3), habit: 'h_water', cents: 1100),
        _log(3, DateTime(2026, 10, 3), habit: 'h_app', cents: 3000),
      ];
      DashboardStats run(StatsRange r) => StatsEngine.compute(range: r, now: now, logs: logs, habits: _habits,
          groceries: const [], rides: const [], trophies: const []);
      final all = run(StatsRange.allTime);
      expect(all.mostUsed!.key, 'h_water');
      expect(all.biggest!.amountCents, 3000);
      expect(all.bestMonth, ('2026-10', 3000));
      expect(all.perHabit.firstWhere((h) => h.key == 'h_water').cents, 2000);
      expect(all.perHabit.length, _habits.length, reason: 'every habit listed, even with zero wins');
      expect(run(StatsRange.lastMonth).totalCents, 3000);
      expect(run(StatsRange.thisMonth).totalCount, 2);
      expect(run(StatsRange.lastYear).totalCount, 0);
    });
  });
}
