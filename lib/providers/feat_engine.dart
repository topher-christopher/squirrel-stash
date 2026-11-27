import '../core/dates.dart';
import '../core/streaks.dart';
import '../models/feat.dart';
import '../models/grocery_trip.dart';
import '../models/habit.dart';
import '../models/impulse.dart';
import '../models/metro_ride.dart';

/// Everything the trophy rules look at.
class FeatInputs {
  const FeatInputs({
    required this.logs,
    required this.habits,
    required this.rides,
    required this.groceries,
    required this.awards,
    required this.focusShifts,
    required this.goalsReclaimed,
    required this.now,
  });

  final List<ImpulseLog> logs;
  final List<Habit> habits;
  final List<MetroRide> rides;
  final List<GroceryTrip> groceries;
  final List<FeatAward> awards;
  final int focusShifts;
  final int goalsReclaimed;
  final DateTime now;
}

/// Pure trophy rules: returns only the awards not already earned, so it is
/// safe to run after every action (and replays history deterministically).
abstract final class FeatEngine {
  static FeatAward award(String key, String period, DateTime at,
          {int acorns = 0, int golden = 0}) =>
      FeatAward(
        id: 'award_${key}_$period',
        featKey: key,
        periodKey: period,
        awardedAt: at,
        acorns: acorns,
        golden: golden,
      );

  static Set<String> habitIds(List<Habit> habits, String key) =>
      {for (final h in habits) if (h.key == key) h.id};

  static List<FeatAward> evaluate(FeatInputs i) {
    final have = {for (final a in i.awards) a.uniqueKey};
    final out = <FeatAward>[];
    void grant(String key, String period, {int acorns = 0, int golden = 0}) {
      if (have.add('$key|$period')) {
        out.add(award(key, period, i.now, acorns: acorns, golden: golden));
      }
    }

    final homeIds = habitIds(i.habits, HabitKeys.homeCooked);
    final hopIds = habitIds(i.habits, HabitKeys.shortHop);
    final homeLogs = i.logs.where((l) => homeIds.contains(l.habitId)).toList();

    // Repeatables
    final iron = Feats.byKey(Feats.ironShield)!;
    _countBy(i.logs.map((l) => Dates.monthKey(l.loggedAt))).forEach((month, n) {
      if (n >= 10) grant(iron.key, month, acorns: iron.acorns);
    });
    final skillet = Feats.byKey(Feats.copperSkillet)!;
    _countBy(homeLogs.map((l) => Dates.weekKey(l.loggedAt))).forEach((week, n) {
      if (n >= 10) grant(skillet.key, week, acorns: skillet.acorns);
    });

    // Four-Seasons Forager: one stage per active season, a Golden Acorn per
    // completed set of all four seasons.
    final activity = [
      ...i.logs.map((l) => l.loggedAt),
      ...i.rides.map((r) => r.rideAt),
      ...i.groceries.map((g) => g.tripAt),
    ];
    final stages = {
      for (final a in i.awards)
        if (a.featKey == Feats.fourSeasonsStage) a.periodKey,
      for (final d in activity) Dates.seasonKey(d),
    };
    for (final s in stages) {
      grant(Feats.fourSeasonsStage, s);
    }
    final ordered = stages.toList()..sort((a, b) => _seasonOrdinal(a).compareTo(_seasonOrdinal(b)));
    var collected = <String>{};
    var sets = 0;
    for (final s in ordered) {
      collected.add(s.split('-').last);
      if (collected.length == 4) {
        sets++;
        collected = {};
        grant(Feats.fourSeasons, 'set$sets', golden: 1);
      }
    }

    // Lifelong ladders
    final values = <String, int>{
      Feats.ladderSaved: i.logs.fold(0, (s, l) => s + l.amountCents),
      Feats.ladderWins: i.logs.length,
      Feats.ladderMeals: homeLogs.length,
      Feats.ladderHops: i.logs.where((l) => hopIds.contains(l.habitId)).length,
      Feats.ladderFocus: i.focusShifts,
      Feats.ladderGoals: i.goalsReclaimed,
    };
    values.forEach((key, value) {
      final def = Feats.byKey(key)!;
      for (var t = 0; t < def.tiers.length; t++) {
        final tier = def.tiers[t];
        if (value >= tier.threshold) {
          grant(key, 'tier${t + 1}', acorns: tier.acorns, golden: tier.golden);
        }
      }
    });

    // Data-driven mystery feats
    void mystery(String key) {
      final def = Feats.byKey(key)!;
      grant(key, 'once', acorns: def.acorns, golden: def.golden);
    }

    if (i.logs.any((l) => l.loggedAt.hour >= 23)) mystery(Feats.nightOwl);
    if (i.logs.any((l) => l.loggedAt.hour >= 4 && l.loggedAt.hour < 6)) {
      mystery(Feats.dawnChorus);
    }
    if (_countBy(i.rides.map((r) => Dates.weekKey(r.rideAt))).values.any((n) => n >= 10)) {
      mystery(Feats.rushHour);
    }
    if (Streaks.longest(Streaks.days(i.logs.map((l) => l.loggedAt))) >= 30) {
      mystery(Feats.unbreakableOak);
    }
    return out;
  }

  /// Event-driven mystery feats (Cozy Zen, swiping, Double Harvest).
  static FeatAward? mysteryAward(String key, List<FeatAward> existing, DateTime now) {
    if (existing.any((a) => a.featKey == key)) return null;
    final def = Feats.byKey(key);
    if (def == null) return null;
    return award(key, 'once', now, acorns: def.acorns, golden: def.golden);
  }

  static Map<String, int> _countBy(Iterable<String> keys) {
    final counts = <String, int>{};
    for (final k in keys) {
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return counts;
  }

  static int _seasonOrdinal(String key) {
    final parts = key.split('-');
    final idx = Season.values.indexWhere((s) => s.name == parts.last);
    return int.parse(parts.first) * 4 + idx;
  }
}
