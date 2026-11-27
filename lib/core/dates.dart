import 'package:intl/intl.dart';

enum Season {
  spring('Spring'),
  summer('Summer'),
  fall('Fall'),
  winter('Winter');

  const Season(this.label);
  final String label;
}

abstract final class Dates {
  static final DateFormat _monthDay = DateFormat('MMM d');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _monthShort = DateFormat('MMM');

  /// `Dec 1`
  static String short(DateTime d) => _monthDay.format(d);

  /// `Dec 2026`
  static String monthYear(DateTime d) => _monthYear.format(d);

  /// `Dec 2026` from a `2026-12` key.
  static String monthKeyLabel(String key) => _monthYear.format(parseMonthKey(key));

  /// `Dec` from a `2026-12` key.
  static String monthKeyShort(String key) => _monthShort.format(parseMonthKey(key));

  static DateTime today([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool sameYear(DateTime a, DateTime b) => a.year == b.year;

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Stable `yyyy-mm-dd` key for once-per-day mechanics.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// `yyyy-mm`
  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static DateTime parseMonthKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// ISO-8601 week key, e.g. `2026-W48` (weeks start Monday).
  static String weekKey(DateTime d) {
    final date = DateTime.utc(d.year, d.month, d.day);
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final yearStart = DateTime.utc(thursday.year, 1, 1);
    final week = thursday.difference(yearStart).inDays ~/ 7 + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Monday of [d]'s week (local midnight).
  static DateTime weekStart(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  /// Meteorological season (northern hemisphere).
  static Season season(DateTime d) => switch (d.month) {
        3 || 4 || 5 => Season.spring,
        6 || 7 || 8 => Season.summer,
        9 || 10 || 11 => Season.fall,
        _ => Season.winter,
      };

  /// `2026-fall`; winter belongs to the year its December falls in.
  static String seasonKey(DateTime d) {
    final s = season(d);
    final year = (s == Season.winter && d.month <= 2) ? d.year - 1 : d.year;
    return '$year-${s.name}';
  }

  /// Whole calendar days from [a] to [b] (DST-safe).
  static int daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  /// `Today`, `Yesterday`, or `Nov 23`.
  static String relative(DateTime d, {DateTime? now}) {
    final diff = daysBetween(d, now ?? DateTime.now());
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
