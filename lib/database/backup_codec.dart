import 'dart:convert';

import '../models/bill.dart';
import '../models/decor.dart';
import '../models/feat.dart';
import '../models/goal.dart';
import '../models/grocery_trip.dart';
import '../models/habit.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/metro_ride.dart';
import '../models/stash_snapshot.dart';
import '../models/trophy.dart';
import 'schema.dart';

/// Thrown when a file is not a SquirrelStash backup this build can restore.
/// [message] is friendly enough to show the user as-is.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// A decoded backup plus the metadata the confirm dialog shows.
class StashBackup {
  const StashBackup({required this.snapshot, required this.schemaVersion, this.exportedAt});

  final StashSnapshot snapshot;
  final int schemaVersion;
  final DateTime? exportedAt;
}

/// Manual backup file: every [StashSnapshot] table as JSON, reusing each
/// model's SQLite row map (`toMap`/`fromMap`) so the file mirrors the schema.
///
/// ```json
/// {"format": "squirrelstash-backup", "formatVersion": 1, "schemaVersion": 2,
///  "exportedAt": "...", "tables": {"settings": {...}, "bills": [...], ...}}
/// ```
///
/// [formatVersion] covers the envelope; [schemaVersion] is the
/// [Schema.version] whose row maps the tables hold. When the schema changes,
/// add a row-map upgrade under the new version in [_upgrades] so older
/// backups still restore.
abstract final class BackupCodec {
  static const format = 'squirrelstash-backup';
  static const formatVersion = 1;

  /// Oldest schema a backup can come from (backups shipped with v2).
  static const minSchemaVersion = 2;

  /// Row-map upgrades keyed by the schema version they upgrade *to*. Each
  /// receives the `tables` object and returns it in that version's shape.
  static const Map<int, Map<String, Object?> Function(Map<String, Object?>)> _upgrades = {};

  static String fileName(DateTime day) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'squirrelstash-backup-${day.year}-${two(day.month)}-${two(day.day)}.json';
  }

  static Map<String, Object?> toJson(StashSnapshot s, {DateTime? exportedAt}) {
    List<Map<String, Object?>> rows<T>(List<T> items, Map<String, Object?> Function(T) toMap) =>
        [for (final item in items) toMap(item)];
    return {
      'format': format,
      'formatVersion': formatVersion,
      'schemaVersion': Schema.version,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'tables': {
        'settings': Map.of(s.settings),
        'bills': rows(s.bills, (e) => e.toMap()),
        'statements': rows(s.statements, (e) => e.toMap()),
        'goals': rows(s.goals, (e) => e.toMap()),
        'trophies': rows(s.trophies, (e) => e.toMap()),
        'habits': rows(s.habits, (e) => e.toMap()),
        'logs': rows(s.logs, (e) => e.toMap()),
        'holdings': rows(s.holdings, (e) => e.toMap()),
        'decor': rows(s.decor, (e) => e.toMap()),
        'groceries': rows(s.groceries, (e) => e.toMap()),
        'rides': rows(s.rides, (e) => e.toMap()),
        'awards': rows(s.awards, (e) => e.toMap()),
      },
    };
  }

  static String encode(StashSnapshot s, {DateTime? exportedAt}) =>
      const JsonEncoder.withIndent('  ').convert(toJson(s, exportedAt: exportedAt));

  /// Parses and validates a backup file's text.
  static StashBackup decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException("This file isn't valid JSON, so it can't be a SquirrelStash backup.");
    }
    return fromJson(json);
  }

  static StashBackup fromJson(Object? json) {
    if (json is! Map<String, Object?> || json['format'] != format) {
      throw const BackupFormatException("This file isn't a SquirrelStash backup.");
    }
    final fv = json['formatVersion'], sv = json['schemaVersion'];
    if (fv is! int || sv is! int) {
      throw const BackupFormatException('This backup is missing its version info.');
    }
    if (fv > formatVersion || sv > Schema.version) {
      throw const BackupFormatException(
          'This backup was made by a newer version of SquirrelStash. Update the app, then try again.');
    }
    if (fv < 1 || sv < minSchemaVersion) {
      throw const BackupFormatException("This backup's version isn't supported.");
    }
    final raw = json['tables'];
    if (raw is! Map<String, Object?>) {
      throw const BackupFormatException('This backup has no data tables.');
    }
    var tables = raw;
    for (var v = sv + 1; v <= Schema.version; v++) {
      tables = _upgrades[v]?.call(tables) ?? tables;
    }
    final exported = json['exportedAt'];
    return StashBackup(
      snapshot: _snapshot(tables),
      schemaVersion: sv,
      exportedAt: exported is String ? DateTime.tryParse(exported) : null,
    );
  }

  static StashSnapshot _snapshot(Map<String, Object?> t) {
    List<T> rows<T>(String table, T Function(Map<String, Object?>) fromMap) {
      final raw = t[table] ?? const <Object?>[];
      if (raw is! List) throw BackupFormatException('The "$table" section is damaged.');
      return [
        for (final (i, row) in raw.indexed)
          if (row is Map<String, Object?>)
            _row(table, i, () => fromMap(row))
          else
            throw BackupFormatException('Row ${i + 1} of "$table" is damaged.'),
      ];
    }

    final settings = t['settings'] ?? const <String, Object?>{};
    if (settings is! Map<String, Object?> || settings.values.any((v) => v is! String)) {
      throw const BackupFormatException('The "settings" section is damaged.');
    }
    return StashSnapshot(
      settings: settings.cast<String, String>(),
      bills: rows('bills', Bill.fromMap),
      statements: rows('statements', BillStatement.fromMap),
      goals: rows('goals', Goal.fromMap),
      trophies: rows('trophies', Trophy.fromMap),
      habits: rows('habits', Habit.fromMap),
      logs: rows('logs', ImpulseLog.fromMap),
      holdings: rows('holdings', Holding.fromMap),
      // Unknown (retired) decor keys are skipped, as in loadAll().
      decor: rows('decor', DecorItemState.fromMap).nonNulls.toList(),
      groceries: rows('groceries', GroceryTrip.fromMap),
      rides: rows('rides', MetroRide.fromMap),
      awards: rows('awards', FeatAward.fromMap),
    );
  }

  /// Runs one model's `fromMap`, turning its cast/parse failures (missing
  /// keys, wrong types, bad dates) into a friendly [BackupFormatException].
  static T _row<T>(String table, int index, T Function() parse) {
    try {
      return parse();
    } on Object {
      throw BackupFormatException('Row ${index + 1} of "$table" is damaged.');
    }
  }

  /// "14 holdings · 230 wins · 6 bills…" for the restore confirmation.
  static String describe(StashSnapshot s) {
    String n(int count, String one, [String? many]) =>
        '$count ${count == 1 ? one : (many ?? '${one}s')}';
    return [
      n(s.holdings.length, 'holding'),
      n(s.logs.length, 'win'),
      n(s.bills.length, 'bill'),
      n(s.statements.length, 'statement'),
      n(s.goals.length, 'goal'),
      n(s.trophies.length, 'trophy', 'trophies'),
      n(s.habits.length, 'habit'),
      n(s.groceries.length, 'grocery trip'),
      n(s.rides.length, 'metro ride'),
      n(s.awards.length, 'award'),
    ].join(' · ');
  }
}
