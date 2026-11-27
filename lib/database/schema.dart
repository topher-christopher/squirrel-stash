import 'package:sqflite/sqflite.dart';

/// SQLite schema & migrations. Money columns are integer cents.
///
/// To evolve the schema: bump [version] and add the new statements under
/// that version number in [migrations]. Never edit shipped statements.
abstract final class Schema {
  static const version = 1;

  static const settings = 'settings';
  static const bills = 'bills';
  static const goals = 'goals';
  static const trophies = 'trophies';
  static const chips = 'impulse_chips';
  static const logs = 'impulse_logs';
  static const holdings = 'holdings';
  static const decor = 'decor';

  static const allTables = [
    settings,
    bills,
    goals,
    trophies,
    chips,
    logs,
    holdings,
    decor,
  ];

  static const _v1 = <String>[
    'CREATE TABLE settings ('
        'key TEXT PRIMARY KEY, '
        'value TEXT NOT NULL)',
    'CREATE TABLE bills ('
        'id TEXT PRIMARY KEY, '
        'name TEXT NOT NULL, '
        'amount_cents INTEGER NOT NULL, '
        'due_date TEXT NOT NULL, '
        'paid INTEGER NOT NULL DEFAULT 0, '
        'sort_order INTEGER NOT NULL DEFAULT 0)',
    'CREATE TABLE goals ('
        'id TEXT PRIMARY KEY, '
        'name TEXT NOT NULL, '
        'icon TEXT NOT NULL, '
        'saved_cents INTEGER NOT NULL DEFAULT 0, '
        'target_cents INTEGER NOT NULL, '
        'due_date TEXT NOT NULL, '
        'priority INTEGER NOT NULL DEFAULT 0, '
        "note TEXT NOT NULL DEFAULT '', "
        'created_at TEXT NOT NULL)',
    'CREATE TABLE trophies ('
        'id TEXT PRIMARY KEY, '
        'name TEXT NOT NULL, '
        'icon TEXT NOT NULL, '
        'amount_cents INTEGER NOT NULL, '
        'reclaimed_at TEXT NOT NULL, '
        "note TEXT NOT NULL DEFAULT '')",
    'CREATE TABLE impulse_chips ('
        'id TEXT PRIMARY KEY, '
        'label TEXT NOT NULL, '
        'mode TEXT NOT NULL, '
        'amount_cents INTEGER NOT NULL, '
        'icon TEXT NOT NULL, '
        'sort_order INTEGER NOT NULL DEFAULT 0)',
    'CREATE TABLE impulse_logs ('
        'id TEXT PRIMARY KEY, '
        'label TEXT NOT NULL, '
        'mode TEXT NOT NULL, '
        'amount_cents INTEGER NOT NULL, '
        'logged_at TEXT NOT NULL, '
        'swept INTEGER NOT NULL DEFAULT 0)',
    'CREATE INDEX idx_impulse_logs_logged_at ON impulse_logs(logged_at)',
    'CREATE TABLE holdings ('
        'id TEXT PRIMARY KEY, '
        'reserve TEXT NOT NULL, '
        'label TEXT NOT NULL, '
        'value_cents INTEGER NOT NULL, '
        'sort_order INTEGER NOT NULL DEFAULT 0)',
    'CREATE TABLE decor ('
        'key TEXT PRIMARY KEY, '
        'owned INTEGER NOT NULL DEFAULT 0, '
        'enabled INTEGER NOT NULL DEFAULT 0)',
  ];

  /// Statements to run when upgrading *to* the keyed version.
  static const Map<int, List<String>> migrations = {};

  static Future<void> create(Database db, int version) async {
    final batch = db.batch();
    for (final statement in _v1) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
    await upgrade(db, 1, version);
  }

  static Future<void> upgrade(Database db, int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      for (final statement in migrations[v] ?? const <String>[]) {
        await db.execute(statement);
      }
    }
  }
}
