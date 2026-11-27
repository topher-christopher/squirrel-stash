import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/models/app_settings.dart';
import 'package:squirrel_stash/models/bird.dart';
import 'package:squirrel_stash/models/colony_economy.dart';
import 'package:squirrel_stash/models/colony_state.dart';
import 'package:squirrel_stash/models/expedition.dart';
import 'package:squirrel_stash/providers/colony_actions.dart';
import 'package:squirrel_stash/providers/colony_math.dart';
import 'package:squirrel_stash/providers/colony_provider.dart';
import 'package:squirrel_stash/providers/diorama_snapshot_provider.dart';
import 'package:squirrel_stash/providers/settings_provider.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Granary cap & overflow', () {
    test('gains past the cap wait outside and roll in after spending', () {
      const s = AppSettings(acorns: 2400);
      final full = s.withAcorns(300);
      expect((full.acorns, full.acornsOverflow), (2500, 200));
      final spent = full.spendAcorns(150);
      expect((spent.acorns, spent.acornsOverflow), (2500, 50), reason: 'room refills from the overflow');
      final refund = spent.withAcorns(-80);
      expect((refund.acorns, refund.acornsOverflow), (2470, 0), reason: 'refunds take from the overflow first');
    });

    test('existing balances are grandfathered into a big enough Granary', () {
      final s = AppSettings.fromMap(const {'acorns': '7000'});
      expect((s.granaryLevel, s.granaryCap), (3, 10000));
      expect(AppSettings.fromMap(const {'acorns': '7000', 'granary_level': '1'}).granaryLevel, 1);
    });
  });

  group('pure colony math', () {
    final now = DateTime(2026, 11, 27, 12);

    test('the canopy collector fills in 8h lit and 12h dark', () {
      expect(ColonyMath.advanceCollector(0, now, now.add(const Duration(hours: 8)), now.add(const Duration(days: 1))), 1);
      expect(ColonyMath.advanceCollector(0, now, now.add(const Duration(hours: 6)), null), closeTo(0.5, 1e-9));
      // 4h lit then 6h dark = 0.5 + 0.5
      expect(ColonyMath.advanceCollector(0, now, now.add(const Duration(hours: 10)), now.add(const Duration(hours: 4))),
          closeTo(1.0, 1e-9));
    });

    test('refueling is capped at the burn capacity and priced per hour', () {
      final s = ColonyState(hearthFuelUntil: now.add(const Duration(hours: 10)));
      final until = ColonyMath.refuel(s, now, 12)!;
      expect(until, now.add(const Duration(hours: 12)), reason: 'Lv.1 Hearth holds 12h');
      expect(ColonyMath.fuelCost(s, now, until), 2 * ColonyEconomy.fuelAcornsPerHour);
      expect(ColonyMath.refuel(ColonyState(hearthFuelUntil: until), now, 4), isNull, reason: 'already full');
      final big = ColonyState(hearthLevel: 3, hearthFuelUntil: now);
      expect(ColonyMath.refuel(big, now, 100), now.add(const Duration(hours: 72)));
    });

    test('lit until the latest of fuel, Overdrive and Festival', () {
      final s = ColonyState(
        hearthFuelUntil: now.subtract(const Duration(hours: 1)),
        overdriveUntil: now.add(const Duration(hours: 5)),
      );
      expect(s.isLit(now), isTrue);
      expect(s.isLit(now.add(const Duration(hours: 6))), isFalse);
    });

    test('moonlight oil burns through the next full night', () {
      expect(LureKind.moonOil.endsAt(DateTime(2026, 11, 27, 10)), DateTime(2026, 11, 28, 7));
      expect(LureKind.moonOil.endsAt(DateTime(2026, 11, 27, 3)), DateTime(2026, 11, 28, 7));
      expect(LureKind.berrySuet.endsAt(now), now.add(const Duration(hours: 12)));
    });
  });

  group('bird simulation', () {
    final start = DateTime(2026, 11, 27, 9);

    test('is deterministic, only brings the seed\'s visitors, and stops when the seed runs out', () {
      List<BirdVisit> run() => BirdSim.simulate(
            from: start,
            to: start.add(const Duration(hours: 10)),
            seed: SeedKind.sunflowerMillet,
            feederUntil: start.add(const Duration(hours: 6)),
          );
      final a = run(), b = run();
      expect(a.map((v) => (v.species, v.at)), b.map((v) => (v.species, v.at)));
      expect(a, isNotEmpty);
      expect(a.every((v) => v.species.seed == SeedKind.sunflowerMillet), isTrue);
      expect(a.every((v) => !v.at.isAfter(start.add(const Duration(hours: 6)))), isTrue);
      expect(a.length, lessThanOrEqualTo(36));
    });

    test('the Great Horned Owl only comes at night', () {
      final visits = BirdSim.simulate(
        from: start.subtract(const Duration(days: 3)),
        to: start.add(const Duration(days: 3)),
        seed: SeedKind.goldenHusk,
        feederUntil: start.add(const Duration(days: 3)),
        lure: LureKind.moonOil,
        lureUntil: start.add(const Duration(days: 3)),
      );
      final owls = visits.where((v) => v.species == BirdSpecies.greatHornedOwl).toList();
      expect(owls, isNotEmpty);
      expect(owls.every((v) => BirdSim.isNight(v.at)), isTrue);
      expect(owls.every((v) => v.lure == LureKind.moonOil), isTrue);
    });

    test('keepsakes unlock at a uniform 100 visits and counts keep climbing', () {
      var e = BirdLogEntry.first(BirdVisit(BirdSpecies.cardinal, start, null));
      for (var i = 1; i < 99; i++) {
        e = e.withVisit(BirdVisit(BirdSpecies.cardinal, start.add(Duration(minutes: i * 10)), LureKind.berrySuet));
      }
      expect((e.visits, e.keepsakeUnlocked), (99, false));
      e = e.withVisit(BirdVisit(BirdSpecies.cardinal, start.add(const Duration(days: 2)), null));
      expect((e.visits, e.keepsakeUnlocked), (100, true));
      e = e.withVisit(BirdVisit(BirdSpecies.cardinal, start.add(const Duration(days: 3)), LureKind.berrySuet));
      expect(e.visits, 101);
      expect(e.favoriteLure, LureKind.berrySuet);
      expect(e.lastSeen, start.add(const Duration(days: 3)));
      expect(e.firstSeen, start);
      expect(BirdLogEntry.fromMap(e.toMap())!.lureTally, e.lureTally);
    });
  });

  group('colony flows (fast-forward clock)', () {
    late DateTime now;
    late ProviderContainer container;
    late ColonyActions colony;
    T read<T>(ProviderListenable<T> p) => container.read(p);

    setUp(() {
      now = DateTime(2026, 11, 27, 10);
      final harness = TestHarness(SeedData.fresh(now).copyWith(settings: {
        ...SeedData.fresh(now).settings,
        'acorns': '2000',
        'golden_acorns': '20',
      }), const {}, () => now);
      container = harness.container();
      colony = read(colonyActionsProvider);
    });

    tearDown(() => container.dispose());

    test('a squad returns with a ready-to-pour bag; one squad unless a second is hired', () {
      expect(colony.dispatch(ExpeditionRoute.meadowDash), isTrue);
      expect(read(settingsProvider).acorns, 2000 - 40);
      expect(colony.dispatch(ExpeditionRoute.ridgeTrek), isFalse, reason: 'one squad');
      expect(colony.hireSecondSquad(), isTrue);
      expect(colony.dispatch(ExpeditionRoute.ridgeTrek), isTrue);
      now = now.add(const Duration(hours: 2, minutes: 1));
      colony.tick();
      expect(read(seedBagsProvider)[SeedKind.sunflowerMillet], 1);
      expect(read(expeditionsProvider).where((e) => e.active).single.route, ExpeditionRoute.ridgeTrek);
      now = now.add(const Duration(hours: 5));
      colony.tick();
      expect(read(seedBagsProvider)[SeedKind.berryHickory], 1);
      expect(read(expeditionsProvider).every((e) => e.collected), isTrue);
    });

    test('pouring seed brings visitors into the lifetime logbook over time', () {
      container.read(seedBagsProvider.notifier).add(SeedKind.sunflowerMillet, 2);
      expect(colony.pourSeed(SeedKind.sunflowerMillet), isTrue);
      expect(read(seedBagsProvider)[SeedKind.sunflowerMillet], 1);
      expect(read(dioramaSnapshotProvider).feederSeed, SeedKind.sunflowerMillet);
      now = now.add(const Duration(hours: 5));
      colony.tick();
      final total = container.read(birdLogProvider.notifier).totalVisits;
      expect(total, greaterThan(5));
      now = now.add(const Duration(hours: 5));
      colony.tick();
      expect(container.read(birdLogProvider.notifier).totalVisits, greaterThanOrEqualTo(total),
          reason: 'the bag ran out after 6h, so few or no new visits');
      expect(read(colonyProvider).seedIn(now), isNull);
    });

    test('the Hearth runs dry (the tree dims, money untouched) and fuel wakes it', () {
      final checking = read(settingsProvider).checkingCents;
      expect(read(dioramaSnapshotProvider).lit, isTrue);
      now = now.add(const Duration(hours: 13));
      colony.tick();
      final dark = read(dioramaSnapshotProvider);
      expect((dark.lit, dark.twilight), (false, true));
      expect(read(settingsProvider).checkingCents, checking);
      expect(colony.fuelHearth(4), isTrue);
      expect(read(settingsProvider).acorns, 2000 - 40);
      expect(read(dioramaSnapshotProvider).lit, isTrue);
      expect(colony.overdrive(24), isTrue);
      expect(read(colonyProvider).overdriveOn(now), isTrue);
    });

    test('wild acorn bubbles fill while away and harvest into the Granary', () {
      now = now.add(const Duration(hours: 8));
      colony.tick();
      expect(read(colonyProvider).bubbles, 5);
      final won = colony.harvestBubbles();
      expect(won, 5 * ColonyEconomy.acornsPerBubble);
      expect(read(settingsProvider).acorns, 2000 + won);
      expect(read(colonyProvider).bubbles, 0);
    });

    test('Golden Acorns buy Granary, burn time, pedestals and a festival', () {
      expect(colony.upgradeGranary(), isTrue);
      expect(read(settingsProvider).granaryCap, 5000);
      expect(colony.upgradeHearth(), isTrue);
      expect(read(colonyProvider).hearthCapacity, const Duration(hours: 24));
      expect(colony.addPedestal(), isTrue);
      expect(read(dioramaSnapshotProvider).pedestals.length, 5);
      expect(colony.startFestival(), isTrue);
      expect(read(dioramaSnapshotProvider).festival, isTrue);
      expect(read(settingsProvider).goldenAcorns, 20 - 2 - 3 - 2 - 2);
    });

    test('lures cost Acorns and refuse when there are not enough', () {
      expect(colony.buyLure(LureKind.deluxeFeast), isTrue);
      expect(read(colonyProvider).lureOn(now), LureKind.deluxeFeast);
      container.read(settingsProvider.notifier).update((s) => s.copyWith(acorns: 10));
      expect(colony.buyLure(LureKind.moonOil), isFalse);
      expect(colony.rushHour(), isFalse);
      expect(read(settingsProvider).acorns, 10);
    });
  });
}
