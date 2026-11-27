import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:squirrel_stash/database/schema.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/database/sqlite_stash_repository.dart';
import 'package:squirrel_stash/models/app_settings.dart';
import 'package:squirrel_stash/models/bill.dart';
import 'package:squirrel_stash/models/bird.dart';
import 'package:squirrel_stash/models/expedition.dart';
import 'package:squirrel_stash/models/feat.dart';
import 'package:squirrel_stash/models/holding.dart';
import 'package:squirrel_stash/models/impulse.dart';

/// Exercises the real SQL schema through sqflite's FFI driver (host SQLite).
void main() {
  sqfliteFfiInit();

  Future<Database> open(int version) => databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: version, onCreate: Schema.create, singleInstance: false),
      );

  group('current schema', () {
    late SqliteStashRepository repo;
    setUp(() async => repo = SqliteStashRepository(await open(Schema.version)));
    tearDown(() => repo.close());

    test('a brand-new database starts empty (so the demo seeds)', () async {
      expect((await repo.loadAll()).isEmpty, isTrue);
    });

    test('demo Great Oak round-trips through SQLite', () async {
      final demo = SeedData.demo(DateTime(2026, 11, 27));
      await repo.replaceAll(demo);
      final loaded = await repo.loadAll();
      expect(loaded.settings['checking_cents'], '760000');
      expect(loaded.bills.map((b) => b.name), contains('Chase Southwest Rapid Rewards'));
      expect(loaded.bills.firstWhere((b) => b.id == 'b_sw').dueDay, 28);
      expect(loaded.statements.length, 28);
      expect(loaded.habits.where((h) => h.pinned).length, 4);
      expect(loaded.logs.where((l) => l.habitId == 'h_cook'), isNotEmpty);
      final btc = loaded.holdings.firstWhere((h) => h.ticker == 'BTC');
      expect((btc.reserve, btc.trackingMode, btc.quantity, btc.lastFetchedPrice),
          (ReserveKind.crypto, TrackingMode.ticker, 0.042, 96500.0));
      expect(loaded.holdings.firstWhere((h) => h.reserve == ReserveKind.espp).esppDiscountPercent, 15);
      expect(loaded.groceries.length, demo.groceries.length);
      expect(loaded.rides.length, demo.rides.length);
      expect(loaded.awards.length, demo.awards.length);
      expect(loaded.expeditions.where((e) => e.active).single.route, ExpeditionRoute.ridgeTrek);
      expect(loaded.seedBags[SeedKind.sunflowerMillet], 2);
      expect(loaded.birdLog.firstWhere((b) => b.species == BirdSpecies.chickadee).visits, 104);
      expect(loaded.decor.every((d) => d.owned), isTrue);
    });

    test('expeditions, seed bags and the logbook upsert in place', () async {
      final now = DateTime(2026, 11, 27, 10);
      await repo.replaceAll(SeedData.fresh(now));
      final e = Expedition(id: 'exp_1', route: ExpeditionRoute.meadowDash, startedAt: now,
          endsAt: now.add(const Duration(hours: 2)), acorns: 40);
      await repo.upsertExpedition(e);
      await repo.upsertExpedition(e.collect(now.add(const Duration(hours: 2))));
      await repo.putSeedBags(SeedKind.goldenHusk, 3);
      await repo.putSeedBags(SeedKind.goldenHusk, 2);
      final visit = BirdVisit(BirdSpecies.baldEagle, now, LureKind.deluxeFeast);
      await repo.upsertBirdLog([BirdLogEntry.first(visit)]);
      await repo.upsertBirdLog([BirdLogEntry.first(visit).withVisit(visit)]);
      final loaded = await repo.loadAll();
      expect(loaded.expeditions.single.collected, isTrue);
      expect(loaded.seedBags, {SeedKind.goldenHusk: 2});
      final eagle = loaded.birdLog.single;
      expect((eagle.visits, eagle.favoriteLure), (2, LureKind.deluxeFeast));
    });

    test('statements are unique per bill & month; awards per feat & period', () async {
      await repo.replaceAll(SeedData.fresh(DateTime(2026, 11, 27)));
      BillStatement s(int cents) => BillStatement(
          id: 'stmt_b_td_2026-12', billId: 'b_td', yearMonth: '2026-12', amountCents: cents, recordedAt: DateTime(2026, 12, 1));
      await repo.upsertStatement(s(40000));
      await repo.upsertStatement(s(41200));
      final award = FeatAward(id: 'award_iron_shield_2026-11', featKey: 'iron_shield', periodKey: '2026-11',
          awardedAt: DateTime(2026, 11, 20), acorns: 50);
      await repo.upsertAwards([award, award]);
      final loaded = await repo.loadAll();
      expect(loaded.statements.single.amountCents, 41200);
      expect(loaded.awards.single.acorns, 50);
      await repo.deleteBill('b_td');
      expect((await repo.loadAll()).statements, isEmpty, reason: 'history goes with the bill');
    });
  });

  test('v1 → v2 → current migration keeps data and splits the reserves', () async {
    final db = await open(1);
    await db.insert('settings', {'key': 'golden_leaves', 'value': '45'});
    await db.insert('settings', {'key': 'checking_cents', 'value': '605000'});
    await db.insert('settings', {'key': 'window_scene', 'value': 'alpine'});
    for (final (id, reserve, label) in const [
      ('h1', 'amber', 'Index Fund Brokerage'),
      ('h2', 'amber', 'High-Yield Savings'),
      ('h3', 'curio', 'Graded Pokémon Slabs'),
      ('h4', 'curio', 'Silver Bullion'),
      ('h5', 'treasury', 'Roth IRA'),
    ]) {
      await db.insert('holdings', {'id': id, 'reserve': reserve, 'label': label, 'value_cents': 1000, 'sort_order': 0});
    }
    await db.insert('bills', {'id': 'b1', 'name': 'Rent', 'amount_cents': 145000, 'due_date': '2026-12-01T00:00:00.000', 'paid': 0, 'sort_order': 0});
    await db.insert('impulse_chips', {'id': 'c1', 'label': 'Tacos', 'mode': 'diy', 'amount_cents': 1200, 'icon': '🌮', 'sort_order': 0});
    await db.insert('impulse_logs', {'id': 'l1', 'label': 'Tacos', 'mode': 'diy', 'amount_cents': 1200, 'logged_at': '2026-11-01T12:00:00.000', 'swept': 0});
    await db.insert('impulse_logs', {'id': 'l0', 'label': 'Summer', 'mode': 'skip', 'amount_cents': 128000, 'logged_at': '2025-07-01T12:00:00.000', 'swept': 1});

    await Schema.upgrade(db, 1, Schema.version);
    final repo = SqliteStashRepository(db);
    final loaded = await repo.loadAll();
    final reserves = {for (final h in loaded.holdings) h.id: h.reserve};
    expect(reserves, {
      'h1': ReserveKind.brokerage,
      'h2': ReserveKind.hysa,
      'h3': ReserveKind.pokemon,
      'h4': ReserveKind.silver,
      'h5': ReserveKind.retirement,
    });
    expect(loaded.holdings.first.apyPercent, isNull, reason: 'no automatic APY');
    final settings = AppSettings.fromMap(loaded.settings);
    expect(settings.acorns, 450, reason: 'Golden Leaves → Acorns at 10:1');
    expect((settings.goldenAcorns, settings.goldenSavingsMilestones), (12, 12), reason: '\$1,292 of past willpower');
    expect(loaded.settings.containsKey('window_scene'), isFalse);
    expect(loaded.bills.single.kind, BillKind.other);
    expect(loaded.habits.single.pinned, isFalse);
    final tacos = loaded.logs.firstWhere((l) => l.id == 'l1');
    expect(tacos.habitId, isNull);
    expect(tacos.groupKey, 'label:Tacos');
    await repo.upsertLogs([
      ImpulseLog(id: 'l2', label: 'x', mode: ImpulseMode.skip, amountCents: 1, loggedAt: DateTime(2026), habitId: 'c1'),
    ]);
    expect((await repo.loadAll()).logs.any((l) => l.habitId == 'c1'), isTrue);
    await repo.close();
  });

  test('v2 → v3 migration frees the looks, grandfathers the Granary, adds colony tables', () async {
    final db = await open(2);
    await db.insert('settings', {'key': 'acorns', 'value': '7000'});
    await db.insert('settings', {'key': 'ambient_track', 'value': 'breeze'});
    await db.insert('decor', {'key': 'fairyLights', 'owned': 0, 'enabled': 0});
    await db.insert('decor', {'key': 'hats', 'owned': 1, 'enabled': 1});
    await Schema.upgrade(db, 2, 3);
    final repo = SqliteStashRepository(db);
    final loaded = await repo.loadAll();
    expect(loaded.decor.every((d) => d.owned), isTrue);
    expect(loaded.decor.firstWhere((d) => d.key.name == 'fairyLights').enabled, isFalse, reason: 'free, not forced on');
    final settings = AppSettings.fromMap(loaded.settings);
    expect((settings.granaryLevel, settings.granaryCap), (3, 10000));
    expect(settings.acorns, 7000, reason: 'nothing is taken away');
    expect(loaded.settings.containsKey('ambient_track'), isFalse);
    expect(loaded.expeditions, isEmpty);
    expect(loaded.seedBags, isEmpty);
    expect(loaded.birdLog, isEmpty);
    await repo.putSeedBags(SeedKind.berryHickory, 1);
    expect((await repo.loadAll()).seedBags, {SeedKind.berryHickory: 1});
    await repo.close();
  });
}
