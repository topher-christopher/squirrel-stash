import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_stash/core/dates.dart';
import 'package:squirrel_stash/models/decor.dart';
import 'package:squirrel_stash/models/feat.dart';
import 'package:squirrel_stash/models/metro_ride.dart';
import 'package:squirrel_stash/models/room.dart';
import 'package:squirrel_stash/providers/awards_provider.dart';
import 'package:squirrel_stash/providers/bills_provider.dart';
import 'package:squirrel_stash/providers/finance_providers.dart';
import 'package:squirrel_stash/providers/goals_provider.dart';
import 'package:squirrel_stash/providers/impulse_provider.dart';
import 'package:squirrel_stash/providers/kitchen_metro_provider.dart';
import 'package:squirrel_stash/providers/reserves_provider.dart';
import 'package:squirrel_stash/providers/reward_service.dart';
import 'package:squirrel_stash/providers/rooms_provider.dart';
import 'package:squirrel_stash/providers/settings_provider.dart';
import 'package:squirrel_stash/providers/stash_actions.dart';
import 'package:squirrel_stash/providers/ui_provider.dart';
import 'package:squirrel_stash/providers/willpower_actions.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness harness;
  late ProviderContainer container;
  late StashActions actions;
  late WillpowerActions will;

  T read<T>(ProviderListenable<T> p) => container.read(p);

  setUp(() {
    harness = TestHarness(null, const {'VTI': 300.0, 'BTC': 100000.0});
    container = harness.container();
    actions = read(stashActionsProvider);
    will = read(willpowerActionsProvider);
  });

  tearDown(() => container.dispose());

  test('payday adds to checking, stamps the day and starts the sprint', () {
    actions.payday();
    expect(read(settingsProvider).checkingCents, 760000 + 120000);
    expect(read(settingsProvider).lastPaydayOn, Dates.dayKey(DateTime.now()));
    expect(harness.repository.settings['checking_cents'], '880000');
    expect(read(uiProvider).paydayBurst, isTrue);
  });

  test('spending never dips into goal allocations', () {
    actions.spend(99999999);
    expect(read(settingsProvider).checkingCents, 400000);
    expect(read(financeProvider).freeCashCents, 0);
  });

  test('logging a habit pays 10 Acorns per dollar and links the habit', () {
    final before = read(settingsProvider).acorns;
    final icecream = read(habitsProvider).firstWhere((h) => h.id == 'h_icecream');
    expect(will.logHabit(icecream), isTrue);
    final log = read(impulseLogsProvider).first;
    expect((log.habitId, log.amountCents), ('h_icecream', 700));
    expect(read(settingsProvider).acorns, greaterThanOrEqualTo(before + 70));
    expect(read(uiProvider).labReaction, r'+$7 Saved! +70');
    expect(will.logWin('  ', icecream.mode, 450), isFalse);
  });

  test('round-trip short hops double, and undo returns the Acorns', () {
    final hop = read(habitsProvider).firstWhere((h) => h.key == 'short_hop');
    final before = read(settingsProvider).acorns;
    read(awardsProvider.notifier); // ensure built
    will.logHabit(hop, roundTrip: true);
    final log = read(impulseLogsProvider).first;
    expect(log.amountCents, 450);
    final afterLog = read(settingsProvider).acorns;
    will.undoLog(log.id);
    expect(read(settingsProvider).acorns, afterLog - 45);
    expect(afterLog - before, greaterThanOrEqualTo(45));
  });

  test('crossing a \$100 willpower milestone forges exactly one Golden Acorn', () {
    final lifetime = read(impulseStatsProvider).allTimeCents;
    final int toNext = 10000 - lifetime % 10000;
    final golden = read(settingsProvider).goldenAcorns;
    final water = read(habitsProvider).firstWhere((h) => h.id == 'h_water');
    will.logHabit(water, cents: toNext);
    expect(read(settingsProvider).goldenAcorns, greaterThanOrEqualTo(golden + 1));
    final afterForge = read(settingsProvider).goldenAcorns;
    will.undoLog(read(impulseLogsProvider).first.id);
    will.logHabit(water, cents: toNext);
    expect(read(settingsProvider).goldenAcorns, afterForge, reason: 'undo + relog never pays twice');
  });

  test('sweeping moves this month\'s wins into a goal exactly once', () {
    final before = read(goalsProvider).first.savedCents;
    final unswept = read(impulseStatsProvider).unsweptMonthCents;
    will.sweepToGoal('g1');
    expect(read(goalsProvider).first.savedCents, before + unswept);
    will.sweepToGoal('g1');
    expect(read(goalsProvider).first.savedCents, before + unswept);
  });

  test('reclaim raises a statue, pays Acorns + a Golden Acorn, grows the oak', () {
    final s = read(settingsProvider);
    actions.allocate('g2', 40000);
    final trophy = actions.reclaim('g2');
    expect(trophy, isNotNull);
    expect(read(trophiesProvider).length, 3);
    expect(read(financeProvider).oakLevel, 3);
    expect(read(settingsProvider).acorns, greaterThanOrEqualTo(s.acorns + 250));
    expect(read(settingsProvider).goldenAcorns, greaterThanOrEqualTo(s.goldenAcorns + 1));
    expect(actions.reclaim('g1'), isNull, reason: 'unfinished chambers stay');
  });

  test('room themes, the Starter | Max switch and Grand Tree looks are free', () {
    final acorns = read(settingsProvider).acorns;
    final golden = read(settingsProvider).goldenAcorns;
    actions.setRoomTheme(RoomKey.lab, 3);
    expect(read(roomsProvider).levelOf(RoomKey.lab), 3);
    expect(harness.repository.settings['room_lv_lab'], '3');
    actions.toggleDecor(DecorKey.twilightSky);
    expect(read(decorProvider)[DecorKey.twilightSky]!.active, isTrue);
    actions.toggleDecor(DecorKey.twilightSky);
    expect(read(decorProvider)[DecorKey.twilightSky]!.active, isFalse);
    actions.setAllRoomThemes(3);
    expect(read(roomsProvider).allMax, isTrue);
    expect(harness.repository.settings['room_lv_hearth'], '3');
    actions.setAllRoomThemes(1);
    expect(read(roomsProvider).allStarter, isTrue);
    expect((read(settingsProvider).acorns, read(settingsProvider).goldenAcorns), (acorns, golden),
        reason: 'no cosmetic paywalls');
  });

  test('Professor Hoot gifts Acorns once per day; focus pays Acorns', () {
    final acorns = read(settingsProvider).acorns;
    actions.greetHoot();
    actions.greetHoot();
    expect(read(settingsProvider).acorns, acorns + 50);
    actions.awardFocus(1500);
    expect(read(settingsProvider).focusShiftsCompleted, 13);
    expect(read(settingsProvider).acorns, greaterThanOrEqualTo(acorns + 50 + 63));
  });

  test('statement balances update the bill and record monthly history', () {
    final td = read(billsProvider).firstWhere((b) => b.id == 'b_td');
    will.recordStatement(td, 39900);
    expect(read(billsProvider).firstWhere((b) => b.id == 'b_td').amountCents, 39900);
    final history = read(statementsProvider).where((s) => s.billId == 'b_td').toList();
    expect(history.length, 7, reason: 'replaces this cycle instead of adding a row');
    expect(history.last.amountCents, 39900);
  });

  test('kitchen, home meals and metro fares log', () {
    final trips = read(groceriesProvider).length;
    expect(will.logGrocery(store: "Trader Joe's", cents: 6420, itemCount: 14), isTrue);
    expect(read(groceriesProvider).length, trips + 1);
    final meals = read(groceryStatsProvider).homeMealsTotal;
    will.logHomeMeal();
    expect(read(groceryStatsProvider).homeMealsTotal, meals + 1);
    final rides = read(metroStatsProvider).monthRides;
    will.logRide(MetroFare.weekdayMax);
    will.logRide(MetroFare.custom, cents: 380);
    expect(read(metroStatsProvider).monthRides, rides + 2);
    expect(read(ridesProvider).first.amountCents, 380);
  });

  test('feats never double-pay; hidden feats unlock from events', () {
    read(rewardServiceProvider).evaluateFeats();
    expect(read(rewardServiceProvider).evaluateFeats(), isEmpty);
    for (final room in RoomKey.values) {
      actions.visitedRoom(room);
    }
    expect(read(awardsProvider).any((a) => a.featKey == Feats.windowShopper), isTrue);
    actions.finishedStargazing();
    expect(read(awardsProvider).any((a) => a.featKey == Feats.canopyStargazer), isTrue);
  });

  test('live price refresh updates ticker holdings and keeps cached ones', () async {
    final r = await read(holdingsProvider.notifier).refreshPrices();
    expect(r.updated, 2);
    final vti = read(holdingsProvider).firstWhere((h) => h.ticker == 'VTI');
    expect(vti.currentValueCents, 1275000);
    expect(vti.valueCents, 1275000, reason: 'cached for offline');
    final eth = read(holdingsProvider).firstWhere((h) => h.ticker == 'ETH');
    expect(eth.lastFetchedPrice, 3450, reason: 'failed fetch keeps the last price');
  });

  test('start fresh wipes the stash but keeps habits and bill presets', () async {
    await actions.startFresh();
    expect(read(goalsProvider), isEmpty);
    expect(read(financeProvider).checkingCents, 0);
    expect(read(billsProvider).length, 5);
    expect(read(habitsProvider).length, 8);
    await actions.restoreDemo();
    expect(read(goalsProvider).length, 2);
  });
}
