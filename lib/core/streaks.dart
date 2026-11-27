import 'dates.dart';

/// Day-streak math over a set of active days (`yyyy-mm-dd` keys).
abstract final class Streaks {
  static Set<String> days(Iterable<DateTime> dates) => {for (final d in dates) Dates.dayKey(d)};

  /// Longest run of consecutive active days.
  static int longest(Set<String> dayKeys) {
    if (dayKeys.isEmpty) return 0;
    final sorted = dayKeys.map(DateTime.parse).toList()..sort();
    var best = 1, run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final gap = Dates.daysBetween(sorted[i - 1], sorted[i]);
      if (gap == 1) {
        run++;
        if (run > best) best = run;
      } else if (gap > 1) {
        run = 1;
      }
    }
    return best;
  }

  /// Current run ending today — or yesterday, so an evening-logger's streak
  /// doesn't look broken first thing in the morning (non-punitive).
  static int current(Set<String> dayKeys, DateTime now) {
    var day = Dates.today(now);
    if (!dayKeys.contains(Dates.dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
      if (!dayKeys.contains(Dates.dayKey(day))) return 0;
    }
    var run = 0;
    while (dayKeys.contains(Dates.dayKey(day))) {
      run++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return run;
  }
}
