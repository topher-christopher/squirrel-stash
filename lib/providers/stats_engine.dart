import '../core/dates.dart';
import '../core/streaks.dart';
import '../models/grocery_trip.dart';
import '../models/habit.dart';
import '../models/impulse.dart';
import '../models/metro_ride.dart';
import '../models/trophy.dart';

/// Trophy Hall timeframe filter pills.
enum StatsRange {
  allTime('All-Time'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisYear('This Year'),
  lastYear('Last Year');

  const StatsRange(this.label);
  final String label;

  bool contains(DateTime d, DateTime now) {
    switch (this) {
      case allTime:
        return true;
      case thisMonth:
        return Dates.sameMonth(d, now);
      case lastMonth:
        return Dates.sameMonth(d, DateTime(now.year, now.month - 1));
      case thisYear:
        return d.year == now.year;
      case lastYear:
        return d.year == now.year - 1;
    }
  }
}

/// Count + dollars for one willpower habit.
class HabitStat {
  const HabitStat({
    required this.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.cents,
  });

  final String key;
  final String label;
  final String icon;
  final int count;
  final int cents;
}

/// Everything the Rocket League-style dashboard shows for one timeframe.
class DashboardStats {
  const DashboardStats({
    required this.range,
    required this.totalCents,
    required this.totalCount,
    required this.perHabit,
    required this.mostUsed,
    required this.bestWeek,
    required this.bestMonth,
    required this.biggest,
    required this.longestStreak,
    required this.groceryCents,
    required this.groceryTrips,
    required this.metroRides,
    required this.metroCents,
    required this.goalsReclaimed,
    required this.goalsReclaimedCents,
  });

  final StatsRange range;
  final int totalCents;
  final int totalCount;
  final List<HabitStat> perHabit;
  final HabitStat? mostUsed;

  /// (week starting Monday, cents)
  final (DateTime, int)? bestWeek;

  /// (`yyyy-mm`, cents)
  final (String, int)? bestMonth;
  final ImpulseLog? biggest;
  final int longestStreak;
  final int groceryCents;
  final int groceryTrips;
  final int metroRides;
  final int metroCents;
  final int goalsReclaimed;
  final int goalsReclaimedCents;

  int get groceryAvgCents => groceryTrips == 0 ? 0 : (groceryCents / groceryTrips).round();
}

abstract final class StatsEngine {
  static DashboardStats compute({
    required StatsRange range,
    required DateTime now,
    required List<ImpulseLog> logs,
    required List<Habit> habits,
    required List<GroceryTrip> groceries,
    required List<MetroRide> rides,
    required List<Trophy> trophies,
  }) {
    final inRange = logs.where((l) => range.contains(l.loggedAt, now)).toList();
    final byId = {for (final h in habits) h.id: h};

    final groups = <String, List<ImpulseLog>>{};
    for (final l in inRange) {
      groups.putIfAbsent(l.groupKey, () => []).add(l);
    }
    final perHabit = <HabitStat>[
      for (final MapEntry(:key, :value) in groups.entries)
        HabitStat(
          key: key,
          label: byId[value.first.habitId]?.label ?? value.first.label,
          icon: byId[value.first.habitId]?.icon ?? value.first.mode.defaultIcon,
          count: value.length,
          cents: value.fold(0, (s, l) => s + l.amountCents),
        ),
    ]..sort((a, b) => b.cents.compareTo(a.cents));
    // Habits with no wins in range still show (zeroed) so every impulse is listed.
    for (final h in habits) {
      if (!groups.containsKey(h.id)) {
        perHabit.add(HabitStat(key: h.id, label: h.label, icon: h.icon, count: 0, cents: 0));
      }
    }

    HabitStat? mostUsed;
    for (final s in perHabit) {
      if (s.count > 0 && (mostUsed == null || s.count > mostUsed.count)) mostUsed = s;
    }

    final weeks = <DateTime, int>{};
    final months = <String, int>{};
    ImpulseLog? biggest;
    for (final l in inRange) {
      final w = Dates.weekStart(l.loggedAt);
      weeks[w] = (weeks[w] ?? 0) + l.amountCents;
      final m = Dates.monthKey(l.loggedAt);
      months[m] = (months[m] ?? 0) + l.amountCents;
      if (biggest == null || l.amountCents > biggest.amountCents) biggest = l;
    }
    (K, int)? best<K>(Map<K, int> m) {
      (K, int)? top;
      m.forEach((k, v) {
        if (top == null || v > top!.$2) top = (k, v);
      });
      return top;
    }

    final groc = groceries.where((g) => range.contains(g.tripAt, now)).toList();
    final ride = rides.where((r) => range.contains(r.rideAt, now)).toList();
    final reclaimed = trophies.where((t) => range.contains(t.reclaimedAt, now)).toList();

    return DashboardStats(
      range: range,
      totalCents: inRange.fold(0, (s, l) => s + l.amountCents),
      totalCount: inRange.length,
      perHabit: perHabit,
      mostUsed: mostUsed,
      bestWeek: best(weeks),
      bestMonth: best(months),
      biggest: biggest,
      longestStreak: Streaks.longest(Streaks.days(inRange.map((l) => l.loggedAt))),
      groceryCents: groc.fold(0, (s, g) => s + g.amountCents),
      groceryTrips: groc.length,
      metroRides: ride.length,
      metroCents: ride.fold(0, (s, r) => s + r.amountCents),
      goalsReclaimed: reclaimed.length,
      goalsReclaimedCents: reclaimed.fold(0, (s, t) => s + t.amountCents),
    );
  }
}
