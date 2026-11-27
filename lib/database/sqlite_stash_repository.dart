import 'package:sqflite/sqflite.dart';

import '../models/bill.dart';
import '../models/decor.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/stash_snapshot.dart';
import '../models/trophy.dart';
import 'schema.dart';
import 'stash_repository.dart';

/// SQLite-backed [StashRepository] (sqflite on mobile/macOS, FFI on desktop).
class SqliteStashRepository implements StashRepository {
  SqliteStashRepository(this._db);

  final Database _db;

  @override
  Future<StashSnapshot> loadAll() async {
    final settingsRows = await _db.query(Schema.settings);
    final decor = <DecorItemState>[];
    for (final row in await _db.query(Schema.decor)) {
      final item = DecorItemState.fromMap(row);
      if (item != null) decor.add(item);
    }
    return StashSnapshot(
      settings: {
        for (final r in settingsRows) r['key']! as String: r['value']! as String,
      },
      bills: (await _db.query(Schema.bills, orderBy: 'sort_order, due_date'))
          .map(Bill.fromMap)
          .toList(),
      goals: (await _db.query(Schema.goals, orderBy: 'created_at'))
          .map(Goal.fromMap)
          .toList(),
      trophies: (await _db.query(Schema.trophies, orderBy: 'reclaimed_at DESC'))
          .map(Trophy.fromMap)
          .toList(),
      chips: (await _db.query(Schema.chips, orderBy: 'sort_order'))
          .map(ImpulseChip.fromMap)
          .toList(),
      logs: (await _db.query(Schema.logs, orderBy: 'logged_at DESC'))
          .map(ImpulseLog.fromMap)
          .toList(),
      holdings: (await _db.query(Schema.holdings, orderBy: 'sort_order'))
          .map(Holding.fromMap)
          .toList(),
      decor: decor,
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
      for (final b in s.bills) {
        batch.insert(Schema.bills, b.toMap());
      }
      for (final g in s.goals) {
        batch.insert(Schema.goals, g.toMap());
      }
      for (final t in s.trophies) {
        batch.insert(Schema.trophies, t.toMap());
      }
      for (final c in s.chips) {
        batch.insert(Schema.chips, c.toMap());
      }
      for (final l in s.logs) {
        batch.insert(Schema.logs, l.toMap());
      }
      for (final h in s.holdings) {
        batch.insert(Schema.holdings, h.toMap());
      }
      for (final d in s.decor) {
        batch.insert(Schema.decor, d.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> _upsert(String table, Map<String, Object?> row) =>
      _db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> _delete(String table, String id) =>
      _db.delete(table, where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> putSetting(String key, String value) =>
      _upsert(Schema.settings, {'key': key, 'value': value});

  @override
  Future<void> upsertBill(Bill bill) => _upsert(Schema.bills, bill.toMap());

  @override
  Future<void> deleteBill(String id) => _delete(Schema.bills, id);

  @override
  Future<void> upsertGoal(Goal goal) => _upsert(Schema.goals, goal.toMap());

  @override
  Future<void> deleteGoal(String id) => _delete(Schema.goals, id);

  @override
  Future<void> upsertTrophy(Trophy trophy) =>
      _upsert(Schema.trophies, trophy.toMap());

  @override
  Future<void> upsertChip(ImpulseChip chip) =>
      _upsert(Schema.chips, chip.toMap());

  @override
  Future<void> deleteChip(String id) => _delete(Schema.chips, id);

  @override
  Future<void> upsertLogs(List<ImpulseLog> logs) async {
    final batch = _db.batch();
    for (final log in logs) {
      batch.insert(Schema.logs, log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteLog(String id) => _delete(Schema.logs, id);

  @override
  Future<void> upsertHolding(Holding holding) =>
      _upsert(Schema.holdings, holding.toMap());

  @override
  Future<void> deleteHolding(String id) => _delete(Schema.holdings, id);

  @override
  Future<void> upsertDecor(DecorItemState decor) =>
      _upsert(Schema.decor, decor.toMap());

  @override
  Future<void> close() => _db.close();
}
