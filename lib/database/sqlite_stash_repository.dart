import 'package:sqflite/sqflite.dart';

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
import 'stash_repository.dart';

/// SQLite-backed [StashRepository] (sqflite on mobile/macOS, FFI on desktop).
class SqliteStashRepository implements StashRepository {
  SqliteStashRepository(this._db);

  final Database _db;

  Future<List<T>> _all<T>(String table, T Function(Map<String, Object?>) map,
          [String? orderBy]) async =>
      (await _db.query(table, orderBy: orderBy)).map(map).toList();

  @override
  Future<StashSnapshot> loadAll() async {
    final decor = <DecorItemState>[];
    for (final row in await _db.query(Schema.decor)) {
      final item = DecorItemState.fromMap(row);
      if (item != null) decor.add(item);
    }
    return StashSnapshot(
      settings: {
        for (final r in await _db.query(Schema.settings))
          r['key']! as String: r['value']! as String,
      },
      bills: await _all(Schema.bills, Bill.fromMap, 'sort_order, due_date'),
      statements: await _all(Schema.statements, BillStatement.fromMap, 'year_month'),
      goals: await _all(Schema.goals, Goal.fromMap, 'created_at'),
      trophies: await _all(Schema.trophies, Trophy.fromMap, 'reclaimed_at DESC'),
      habits: await _all(Schema.habits, Habit.fromMap, 'sort_order'),
      logs: await _all(Schema.logs, ImpulseLog.fromMap, 'logged_at DESC'),
      holdings: await _all(Schema.holdings, Holding.fromMap, 'sort_order'),
      decor: decor,
      groceries: await _all(Schema.groceries, GroceryTrip.fromMap, 'trip_at DESC'),
      rides: await _all(Schema.rides, MetroRide.fromMap, 'ride_at DESC'),
      awards: await _all(Schema.awards, FeatAward.fromMap, 'awarded_at'),
    );
  }

  @override
  Future<void> replaceAll(StashSnapshot s) async {
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final table in Schema.allTables) {
        batch.delete(table);
      }
      s.settings.forEach((key, value) {
        batch.insert(Schema.settings, {'key': key, 'value': value});
      });
      void insertAll(String table, Iterable<Map<String, Object?>> rows) {
        for (final row in rows) {
          batch.insert(table, row);
        }
      }

      insertAll(Schema.bills, s.bills.map((e) => e.toMap()));
      insertAll(Schema.statements, s.statements.map((e) => e.toMap()));
      insertAll(Schema.goals, s.goals.map((e) => e.toMap()));
      insertAll(Schema.trophies, s.trophies.map((e) => e.toMap()));
      insertAll(Schema.habits, s.habits.map((e) => e.toMap()));
      insertAll(Schema.logs, s.logs.map((e) => e.toMap()));
      insertAll(Schema.holdings, s.holdings.map((e) => e.toMap()));
      insertAll(Schema.decor, s.decor.map((e) => e.toMap()));
      insertAll(Schema.groceries, s.groceries.map((e) => e.toMap()));
      insertAll(Schema.rides, s.rides.map((e) => e.toMap()));
      insertAll(Schema.awards, s.awards.map((e) => e.toMap()));
      await batch.commit(noResult: true);
    });
  }

  Future<void> _upsert(String table, Map<String, Object?> row) =>
      _db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> _upsertMany(String table, Iterable<Map<String, Object?>> rows) async {
    final batch = _db.batch();
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _delete(String table, String id) =>
      _db.delete(table, where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> putSetting(String key, String value) =>
      _upsert(Schema.settings, {'key': key, 'value': value});

  @override
  Future<void> upsertBill(Bill bill) => _upsert(Schema.bills, bill.toMap());

  @override
  Future<void> deleteBill(String id) async {
    await _delete(Schema.bills, id);
    await _db.delete(Schema.statements, where: 'bill_id = ?', whereArgs: [id]);
  }

  @override
  Future<void> upsertStatement(BillStatement s) => _upsert(Schema.statements, s.toMap());

  @override
  Future<void> deleteStatement(String id) => _delete(Schema.statements, id);

  @override
  Future<void> upsertGoal(Goal goal) => _upsert(Schema.goals, goal.toMap());

  @override
  Future<void> deleteGoal(String id) => _delete(Schema.goals, id);

  @override
  Future<void> upsertTrophy(Trophy trophy) => _upsert(Schema.trophies, trophy.toMap());

  @override
  Future<void> upsertHabit(Habit habit) => _upsert(Schema.habits, habit.toMap());

  @override
  Future<void> deleteHabit(String id) => _delete(Schema.habits, id);

  @override
  Future<void> upsertLogs(List<ImpulseLog> logs) =>
      _upsertMany(Schema.logs, logs.map((l) => l.toMap()));

  @override
  Future<void> deleteLog(String id) => _delete(Schema.logs, id);

  @override
  Future<void> upsertHoldings(List<Holding> holdings) =>
      _upsertMany(Schema.holdings, holdings.map((h) => h.toMap()));

  @override
  Future<void> deleteHolding(String id) => _delete(Schema.holdings, id);

  @override
  Future<void> upsertDecor(DecorItemState decor) => _upsert(Schema.decor, decor.toMap());

  @override
  Future<void> upsertGrocery(GroceryTrip trip) => _upsert(Schema.groceries, trip.toMap());

  @override
  Future<void> deleteGrocery(String id) => _delete(Schema.groceries, id);

  @override
  Future<void> upsertRide(MetroRide ride) => _upsert(Schema.rides, ride.toMap());

  @override
  Future<void> deleteRide(String id) => _delete(Schema.rides, id);

  @override
  Future<void> upsertAwards(List<FeatAward> awards) =>
      _upsertMany(Schema.awards, awards.map((a) => a.toMap()));

  @override
  Future<void> close() => _db.close();
}
