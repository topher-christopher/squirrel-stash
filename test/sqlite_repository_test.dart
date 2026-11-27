import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:squirrel_stash/database/schema.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/database/sqlite_stash_repository.dart';
import 'package:squirrel_stash/models/impulse.dart';

/// Exercises the real SQL schema through sqflite's FFI driver (host SQLite).
void main() {
  sqfliteFfiInit();

  late SqliteStashRepository repo;

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: Schema.version, onCreate: Schema.create),
    );
    repo = SqliteStashRepository(db);
  });

  tearDown(() => repo.close());

  test('demo snapshot round-trips through SQLite', () async {
    final demo = SeedData.demo(DateTime(2026, 11, 26));
    await repo.replaceAll(demo);
    final loaded = await repo.loadAll();
    expect(loaded.settings['checking_cents'], '605000');
    expect(loaded.bills.length, 4);
    expect(loaded.goals.map((g) => g.name), ['Japan Trip', 'New PC Build']);
    expect(loaded.goals.first.note, contains('ramen in Tokyo'));
    expect(loaded.trophies.single.icon, '🛡️');
    expect(loaded.chips.length, 4);
    expect(loaded.logs.first.loggedAt.isAfter(loaded.logs.last.loggedAt), isTrue);
    expect(loaded.holdings.fold<int>(0, (s, h) => s + h.valueCents), 2450000 + 510000 + 6230000);
    expect(loaded.decor.where((d) => d.active).length, 2);
  });

  test('upserts and deletes persist', () async {
    await repo.replaceAll(SeedData.fresh());
    await repo.putSetting('golden_leaves', '99');
    await repo.upsertLogs([
      ImpulseLog(id: 'x', label: 'Skipped snacks', mode: ImpulseMode.skip, amountCents: 500, loggedAt: DateTime(2026, 11, 1)),
    ]);
    await repo.upsertLogs([
      ImpulseLog(id: 'x', label: 'Skipped snacks', mode: ImpulseMode.skip, amountCents: 500, loggedAt: DateTime(2026, 11, 1), swept: true),
    ]);
    final loaded = await repo.loadAll();
    expect(loaded.settings['golden_leaves'], '99');
    expect(loaded.logs.single.swept, isTrue);
    await repo.deleteLog('x');
    expect((await repo.loadAll()).logs, isEmpty);
  });
}
