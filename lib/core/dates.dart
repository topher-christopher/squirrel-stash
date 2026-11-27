import 'package:intl/intl.dart';

abstract final class Dates {
  static final DateFormat _monthDay = DateFormat('MMM d');

  /// `Dec 1`
  static String short(DateTime d) => _monthDay.format(d);

  static DateTime today([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool sameYear(DateTime a, DateTime b) => a.year == b.year;

  /// Stable `yyyy-mm-dd` key for once-per-day mechanics.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// `Today`, `Yesterday`, or `Nov 23`.
  static String relative(DateTime d, {DateTime? now}) {
    final t = today(now);
    final day = DateTime(d.year, d.month, d.day);
    final diff = t.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return short(d);
  }

  /// Adds calendar months, clamping the day (Jan 31 + 1 → Feb 28/29).
  static DateTime addMonths(DateTime d, int months) {
    final totalMonths = d.year * 12 + (d.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, d.day > lastDay ? lastDay : d.day);
  }
}
