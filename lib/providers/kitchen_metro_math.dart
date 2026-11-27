import '../core/dates.dart';
import '../core/streaks.dart';
import '../models/grocery_trip.dart';
import '../models/habit.dart';
import '../models/impulse.dart';
import '../models/metro_ride.dart';

/// Neutral grocery-spend awareness for the Squirrel Kitchen.
class GroceryStats {
  const GroceryStats({
    required this.monthCents,
    required this.yearCents,
    required this.monthTrips,
    required this.yearTrips,
    required this.avgPerTripCents,
    required this.avgDaysBetween,
    required this.homeMealsMonth,
    required this.homeMealsTotal,
    required this.homeStreak,
    required this.bestHomeStreak,
  });

  final int monthCents;
  final int yearCents;
  final int monthTrips;
  final int yearTrips;

  /// Average spend per trip this year (all-time if none this year).
  final int avgPerTripCents;

  /// Mean days between consecutive trips (null with fewer than two trips).
  final double? avgDaysBetween;
  final int homeMealsMonth;
  final int homeMealsTotal;
  final int homeStreak;
  final int bestHomeStreak;
}

/// Transit spend picture for the DC Metro Station.
class MetroStats {
  const MetroStats({
    required this.monthRides,
    required this.monthCents,
    required this.yearRides,
    required this.yearCents,
    required this.allRides,
    required this.monthByFare,
    required this.walkedHopsMonth,
    required this.walkedSavedMonthCents,
  });

  final int monthRides;
  final int monthCents;
  final int yearRides;
  final int yearCents;
  final int allRides;

  /// This month's (count, cents) per fare preset.
  final Map<MetroFare, (int, int)> monthByFare;

  /// Short hops walked or biked instead (willpower habit) this month.
  final int walkedHopsMonth;
  final int walkedSavedMonthCents;
}

abstract final class KitchenMetroMath {
  static int _sum(Iterable<int> cents) => cents.fold(0, (s, c) => s + c);

  static GroceryStats grocery({
    required List<GroceryTrip> trips,
    required List<ImpulseLog> logs,
    required List<Habit> habits,
    required DateTime now,
  }) {
    final month = trips.where((t) => Dates.sameMonth(t.tripAt, now)).toList();
    final year = trips.where((t) => Dates.sameYear(t.tripAt, now)).toList();
    final basis = year.isNotEmpty ? year : trips;
    final sorted = trips.map((t) => t.tripAt).toList()..sort();
    double? gap;
    if (sorted.length >= 2) {
      gap = Dates.daysBetween(sorted.first, sorted.last) / (sorted.length - 1);
    }
    final homeIds = {for (final h in habits) if (h.key == HabitKeys.homeCooked) h.id};
    final meals = logs.where((l) => homeIds.contains(l.habitId)).toList();
    final mealDays = Streaks.days(meals.map((l) => l.loggedAt));
    return GroceryStats(
      monthCents: _sum(month.map((t) => t.amountCents)),
      yearCents: _sum(year.map((t) => t.amountCents)),
      monthTrips: month.length,
      yearTrips: year.length,
      avgPerTripCents: basis.isEmpty
          ? 0
          : (_sum(basis.map((t) => t.amountCents)) / basis.length).round(),
      avgDaysBetween: gap,
      homeMealsMonth: meals.where((l) => Dates.sameMonth(l.loggedAt, now)).length,
      homeMealsTotal: meals.length,
      homeStreak: Streaks.current(mealDays, now),
      bestHomeStreak: Streaks.longest(mealDays),
    );
  }

  static MetroStats metro({
    required List<MetroRide> rides,
    required List<ImpulseLog> logs,
    required List<Habit> habits,
    required DateTime now,
  }) {
    final month = rides.where((r) => Dates.sameMonth(r.rideAt, now)).toList();
    final year = rides.where((r) => Dates.sameYear(r.rideAt, now)).toList();
    final byFare = <MetroFare, (int, int)>{
      for (final f in MetroFare.values)
        f: (
          month.where((r) => r.fare == f).length,
          _sum(month.where((r) => r.fare == f).map((r) => r.amountCents)),
        ),
    };
    final hopIds = {for (final h in habits) if (h.key == HabitKeys.shortHop) h.id};
    final hops = logs
        .where((l) => hopIds.contains(l.habitId) && Dates.sameMonth(l.loggedAt, now))
        .toList();
    return MetroStats(
      monthRides: month.length,
      monthCents: _sum(month.map((r) => r.amountCents)),
      yearRides: year.length,
      yearCents: _sum(year.map((r) => r.amountCents)),
      allRides: rides.length,
      monthByFare: byFare,
      walkedHopsMonth: hops.length,
      walkedSavedMonthCents: _sum(hops.map((l) => l.amountCents)),
    );
  }
}
