import 'package:sqflite/sqflite.dart';

/// SQLite schema & migrations. Money columns are integer cents (per-unit
/// market prices are REAL dollars for sub-cent precision).
///
/// To evolve the schema: bump [version] and add the new statements under
/// that version number in [migrations]. Never edit shipped statements.
abstract final class Schema {
  static const version = 2;

  static const settings = 'settings';
  static const bills = 'bills';
  static const statements = 'bill_statements';
  static const goals = 'goals';
  static const trophies = 'trophies';

  /// Willpower habits (named before habits existed).
  static const habits = 'impulse_chips';
  static const logs = 'impulse_logs';
  static const holdings = 'holdings';
  static const decor = 'decor';
  static const groceries = 'grocery_trips';
  static const rides = 'metro_rides';
  static const awards = 'trophy_awards';

  static const allTables = [
    settings,
    bills,
    statements,
    goals,
    trophies,
    habits,
    logs,
    holdings,
    decor,
    groceries,
    rides,
    awards,
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

  /// v1.1: Great Oak colony, bill statements, habits, kitchen, metro,
  /// live-priced holdings and repeatable trophies.
  static const _v2 = <String>[
    // Recurring bills & card statement history
    "ALTER TABLE bills ADD COLUMN kind TEXT NOT NULL DEFAULT 'other'",
    'ALTER TABLE bills ADD COLUMN due_day INTEGER',
    'CREATE TABLE bill_statements ('
        'id TEXT PRIMARY KEY, '
        'bill_id TEXT NOT NULL, '
        'year_month TEXT NOT NULL, '
        'amount_cents INTEGER NOT NULL, '
        'recorded_at TEXT NOT NULL, '
        'UNIQUE(bill_id, year_month))',
    'CREATE INDEX idx_statements_bill ON bill_statements(bill_id, year_month)',
    // Pinnable, editable habits
    "ALTER TABLE impulse_chips ADD COLUMN entry TEXT NOT NULL DEFAULT 'fixed'",
    'ALTER TABLE impulse_chips ADD COLUMN round_trip INTEGER NOT NULL DEFAULT 0',
    'ALTER TABLE impulse_chips ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0',
    'ALTER TABLE impulse_chips ADD COLUMN habit_key TEXT',
    'ALTER TABLE impulse_logs ADD COLUMN habit_id TEXT',
    'CREATE INDEX idx_impulse_logs_habit ON impulse_logs(habit_id)',
    // Live market tracking
    "ALTER TABLE holdings ADD COLUMN tracking_mode TEXT NOT NULL DEFAULT 'manual'",
    'ALTER TABLE holdings ADD COLUMN ticker TEXT',
    'ALTER TABLE holdings ADD COLUMN quantity REAL',
    'ALTER TABLE holdings ADD COLUMN cost_basis_per_unit REAL',
    'ALTER TABLE holdings ADD COLUMN last_fetched_price REAL',
    'ALTER TABLE holdings ADD COLUMN last_updated_at TEXT',
    'ALTER TABLE holdings ADD COLUMN apy_percent REAL',
    'ALTER TABLE holdings ADD COLUMN espp_discount_percent REAL',
    'ALTER TABLE holdings ADD COLUMN espp_cash_pot_cents INTEGER',
    'ALTER TABLE holdings ADD COLUMN recurring_cents INTEGER',
    // The three v1 reserves split into seven vault pockets
    "UPDATE holdings SET reserve = 'hysa' WHERE reserve = 'amber' AND "
        "(lower(label) LIKE '%saving%' OR lower(label) LIKE '%hysa%')",
    "UPDATE holdings SET reserve = 'brokerage' WHERE reserve = 'amber'",
    "UPDATE holdings SET reserve = 'silver' WHERE reserve = 'curio' AND "
        "(lower(label) LIKE '%silver%' OR lower(label) LIKE '%bullion%')",
    "UPDATE holdings SET reserve = 'pokemon' WHERE reserve = 'curio'",
    "UPDATE holdings SET reserve = 'retirement' WHERE reserve = 'treasury'",
    // Kitchen, Metro, Trophy Hall
    'CREATE TABLE grocery_trips ('
        'id TEXT PRIMARY KEY, '
        "store TEXT NOT NULL DEFAULT '', "
        'amount_cents INTEGER NOT NULL, '
        'item_count INTEGER, '
        'trip_at TEXT NOT NULL)',
    'CREATE INDEX idx_grocery_trip_at ON grocery_trips(trip_at)',
    'CREATE TABLE metro_rides ('
        'id TEXT PRIMARY KEY, '
        'fare TEXT NOT NULL, '
        'amount_cents INTEGER NOT NULL, '
        'ride_at TEXT NOT NULL)',
    'CREATE INDEX idx_metro_ride_at ON metro_rides(ride_at)',
    'CREATE TABLE trophy_awards ('
        'id TEXT PRIMARY KEY, '
        'feat_key TEXT NOT NULL, '
        'period_key TEXT NOT NULL, '
        'awarded_at TEXT NOT NULL, '
        'acorns INTEGER NOT NULL DEFAULT 0, '
        'golden INTEGER NOT NULL DEFAULT 0, '
        'UNIQUE(feat_key, period_key))',
    // Retired Golden Leaves become Acorns (10 : 1) for existing stashes.
    'INSERT OR IGNORE INTO settings (key, value) '
        "SELECT 'acorns', CAST(CAST(value AS INTEGER) * 10 AS TEXT) "
        "FROM settings WHERE key = 'golden_leaves'",
    // Golden Acorns already earned by past willpower ($100 each). HAVING keeps
    // a brand-new install empty so the demo still seeds on first launch.
    'INSERT OR IGNORE INTO settings (key, value) '
        "SELECT 'golden_acorns', CAST(SUM(amount_cents) / 10000 AS TEXT) FROM impulse_logs "
        'HAVING COUNT(*) > 0',
    'INSERT OR IGNORE INTO settings (key, value) '
        "SELECT 'golden_savings_milestones', CAST(SUM(amount_cents) / 10000 AS TEXT) "
        'FROM impulse_logs HAVING COUNT(*) > 0',
    "DELETE FROM settings WHERE key IN ('golden_leaves', 'window_scene', "
        "'brokerage_apy_bps')",
  ];

  /// Statements to run when upgrading *to* the keyed version.
  static const Map<int, List<String>> migrations = {2: _v2};

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
