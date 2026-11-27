import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:squirrel_stash/database/backup_codec.dart';
import 'package:squirrel_stash/database/schema.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/database/sqlite_stash_repository.dart';
import 'package:squirrel_stash/models/holding.dart';
import 'package:squirrel_stash/models/stash_snapshot.dart';
import 'package:squirrel_stash/providers/repository_providers.dart';

import 'helpers/test_harness.dart';

/// Every table, every column: compares the SQLite row maps.
void expectSameStash(StashSnapshot actual, StashSnapshot expected) {
  List<Map<String, Object?>> rows<T>(List<T> items, Map<String, Object?> Function(T) toMap) =>
      items.map(toMap).toList();
  expect(actual.settings, expected.settings);
  expect(rows(actual.bills, (e) => e.toMap()), rows(expected.bills, (e) => e.toMap()));
  expect(rows(actual.statements, (e) => e.toMap()), rows(expected.statements, (e) => e.toMap()));
  expect(rows(actual.goals, (e) => e.toMap()), rows(expected.goals, (e) => e.toMap()));
  expect(rows(actual.trophies, (e) => e.toMap()), rows(expected.trophies, (e) => e.toMap()));
  expect(rows(actual.habits, (e) => e.toMap()), rows(expected.habits, (e) => e.toMap()));
  expect(rows(actual.logs, (e) => e.toMap()), rows(expected.logs, (e) => e.toMap()));
  expect(rows(actual.holdings, (e) => e.toMap()), rows(expected.holdings, (e) => e.toMap()));
  expect(rows(actual.decor, (e) => e.toMap()), rows(expected.decor, (e) => e.toMap()));
  expect(rows(actual.groceries, (e) => e.toMap()), rows(expected.groceries, (e) => e.toMap()));
  expect(rows(actual.rides, (e) => e.toMap()), rows(expected.rides, (e) => e.toMap()));
  expect(rows(actual.awards, (e) => e.toMap()), rows(expected.awards, (e) => e.toMap()));
}

void main() {
  final now = DateTime(2026, 11, 27, 9, 30);

  /// The demo plus a holding with every optional column filled in.
  StashSnapshot stash() {
    final demo = SeedData.demo(now);
    return demo.copyWith(holdings: [
      ...demo.holdings,
      Holding(
        id: 'h_espp', reserve: ReserveKind.espp, label: 'Company ESPP', valueCents: 1234567,
        sortOrder: 9, trackingMode: TrackingMode.ticker, ticker: 'MSFT', quantity: 12.3456789,
        costBasisPerUnit: 301.125, lastFetchedPrice: 415.0, lastUpdatedAt: DateTime.utc(2026, 11, 26, 21, 0, 5, 123, 456),
        apyPercent: 4.35, esppDiscountPercent: 15, esppCashPotCents: 98765, recurringCents: 25000,
      ),
    ]);
  }

  StashBackup roundTrip(StashSnapshot s) => BackupCodec.decode(BackupCodec.encode(s, exportedAt: now));

  group('round trip', () {
    test('the demo stash survives export → import unchanged', () {
      final original = stash();
      final backup = roundTrip(original);
      expect(backup.schemaVersion, Schema.version);
      expect(backup.exportedAt, now);
      expectSameStash(backup.snapshot, original);
    });

    test('holdings keep ticker, quantity and price fields', () {
      final original = stash();
      final restored = roundTrip(original).snapshot;
      final btc = restored.holdings.firstWhere((h) => h.ticker == 'BTC');
      expect((btc.reserve, btc.trackingMode, btc.quantity, btc.lastFetchedPrice),
          (ReserveKind.crypto, TrackingMode.ticker, 0.042, 96500.0));
      final espp = restored.holdings.firstWhere((h) => h.id == 'h_espp');
      final want = original.holdings.firstWhere((h) => h.id == 'h_espp');
      expect(espp.ticker, 'MSFT');
      expect(espp.quantity, want.quantity);
      expect(espp.costBasisPerUnit, 301.125);
      expect(espp.lastFetchedPrice, 415.0);
      expect(espp.lastUpdatedAt, want.lastUpdatedAt);
      expect(espp.lastUpdatedAt!.isUtc, isTrue);
      expect((espp.apyPercent, espp.esppDiscountPercent), (4.35, 15.0));
      expect((espp.esppCashPotCents, espp.recurringCents), (98765, 25000));
      expect(espp.currentValueCents, want.currentValueCents);
    });

    test('bill statements and bills keep every field', () {
      final original = stash();
      final restored = roundTrip(original).snapshot;
      expect(restored.statements, hasLength(original.statements.length));
      for (final (i, s) in restored.statements.indexed) {
        final o = original.statements[i];
        expect((s.id, s.billId, s.yearMonth, s.amountCents, s.recordedAt),
            (o.id, o.billId, o.yearMonth, o.amountCents, o.recordedAt));
      }
      final sw = restored.bills.firstWhere((b) => b.id == 'b_sw');
      final osw = original.bills.firstWhere((b) => b.id == 'b_sw');
      expect((sw.name, sw.kind, sw.dueDay, sw.dueDate, sw.paid, sw.amountCents),
          (osw.name, osw.kind, osw.dueDay, osw.dueDate, osw.paid, osw.amountCents));
    });

    test('an empty stash round-trips', () {
      expectSameStash(roundTrip(const StashSnapshot()).snapshot, const StashSnapshot());
    });

    test('a restored backup writes cleanly into SQLite', () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(version: Schema.version, onCreate: Schema.create, singleInstance: false));
      final repo = SqliteStashRepository(db);
      addTearDown(repo.close);
      final original = stash();
      await repo.replaceAll(original);
      final exported = await repo.loadAll();
      await repo.replaceAll(SeedData.fresh(now));
      await repo.replaceAll(roundTrip(exported).snapshot);
      expectSameStash(await repo.loadAll(), exported);
    });

    test('importing replaces the live stash and the repository', () async {
      final harness = TestHarness(SeedData.fresh(now));
      final container = harness.container();
      addTearDown(container.dispose);
      final backup = roundTrip(stash());
      await container.read(stashSnapshotProvider.notifier).replace(backup.snapshot);
      expect(container.read(stashSnapshotProvider), same(backup.snapshot));
      final saved = await harness.repository.loadAll();
      expect(saved.holdings.map((h) => h.id), unorderedEquals(backup.snapshot.holdings.map((h) => h.id)));
      expect(saved.logs, hasLength(backup.snapshot.logs.length));
      expect(saved.statements, hasLength(backup.snapshot.statements.length));
      expect(saved.settings, backup.snapshot.settings);
    });

    test('the file name and summary read naturally', () {
      expect(BackupCodec.fileName(DateTime(2026, 3, 7)), 'squirrelstash-backup-2026-03-07.json');
      final s = stash();
      final summary = BackupCodec.describe(s);
      expect(summary, startsWith('${s.holdings.length} holdings · ${s.logs.length} wins · '));
      expect(summary, contains('${s.trophies.length} trophies'));
    });
  });

  group('rejects', () {
    Map<String, Object?> valid() =>
        jsonDecode(BackupCodec.encode(stash(), exportedAt: now)) as Map<String, Object?>;

    void expectRejected(Object? json, Matcher message) => expect(
          () => BackupCodec.decode(json is String ? json : jsonEncode(json)),
          throwsA(isA<BackupFormatException>().having((e) => e.message, 'message', message)),
        );

    test('text that is not JSON', () {
      expectRejected('{"format": "squirrelstash-backup", ', contains('valid JSON'));
      expectRejected('', contains('valid JSON'));
    });

    test('JSON that is not a backup', () {
      expectRejected([1, 2, 3], contains("isn't a SquirrelStash backup"));
      expectRejected({'hello': 'world'}, contains("isn't a SquirrelStash backup"));
    });

    test('backups from a newer app', () {
      expectRejected(valid()..['formatVersion'] = BackupCodec.formatVersion + 1, contains('newer version'));
      expectRejected(valid()..['schemaVersion'] = Schema.version + 1, contains('newer version'));
    });

    test('missing or unsupported versions', () {
      expectRejected(valid()..remove('schemaVersion'), contains('version info'));
      expectRejected(valid()..['formatVersion'] = '1', contains('version info'));
      expectRejected(valid()..['schemaVersion'] = 1, contains("isn't supported"));
    });

    test('damaged tables and rows', () {
      expectRejected(valid()..remove('tables'), contains('no data tables'));
      Map<String, Object?> withTables(void Function(Map<String, Object?>) edit) {
        final json = valid();
        edit(json['tables']! as Map<String, Object?>);
        return json;
      }

      expectRejected(withTables((t) => t['holdings'] = 'lots'), contains('"holdings"'));
      expectRejected(withTables((t) => (t['holdings']! as List)[0] = 42), contains('Row 1 of "holdings"'));
      expectRejected(withTables((t) => ((t['holdings']! as List)[1] as Map).remove('id')), contains('Row 2 of "holdings"'));
      expectRejected(withTables((t) => ((t['statements']! as List)[0] as Map)['recorded_at'] = 'last tuesday'),
          contains('"statements"'));
      expectRejected(withTables((t) => ((t['bills']! as List)[0] as Map)['amount_cents'] = '12.00'), contains('"bills"'));
      expectRejected(withTables((t) => (t['settings']! as Map)['checking_cents'] = 760000), contains('"settings"'));
    });
  });
}
