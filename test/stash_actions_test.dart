import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_stash/core/dates.dart';
import 'package:squirrel_stash/models/decor.dart';
import 'package:squirrel_stash/models/impulse.dart';
import 'package:squirrel_stash/providers/finance_providers.dart';
import 'package:squirrel_stash/providers/goals_provider.dart';
import 'package:squirrel_stash/providers/impulse_provider.dart';
import 'package:squirrel_stash/providers/reserves_provider.dart';
import 'package:squirrel_stash/providers/settings_provider.dart';
import 'package:squirrel_stash/providers/stash_actions.dart';
import 'package:squirrel_stash/providers/ui_provider.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness harness;
  late StashActions actions;
  late ProviderContainer container;

  setUp(() {
    harness = TestHarness();
    container = harness.container();
    actions = container.read(stashActionsProvider);
  });

  tearDown(() => container.dispose());

  test('payday adds to checking, persists, and starts the delivery sprint', () {
    actions.payday();
    expect(container.read(settingsProvider).checkingCents, 605000 + 120000);
    expect(harness.repository.settings['checking_cents'], '725000');
    expect(container.read(uiProvider).paydayBurst, isTrue);
    expect(container.read(uiProvider).banner?.text, contains(r'+$1,200'));
  });

  test('spending never dips into goal allocations', () {
    actions.spend(99999999);
    expect(container.read(settingsProvider).checkingCents, 400000);
    expect(container.read(financeProvider).freeCashCents, 0);
  });

  test('logging a win records it, warms the hearth and shows the reaction', () {
    final ok = actions.logWin('Brewed coffee at home', ImpulseMode.diy, 450);
    expect(ok, isTrue);
    expect(container.read(impulseLogsProvider).first.label, 'Brewed coffee at home');
    expect(container.read(settingsProvider).hearthWarmth, 3);
    expect(container.read(uiProvider).labReaction, r'+$4.50 Saved!');
    expect(actions.logWin('  ', ImpulseMode.diy, 450), isFalse);
    expect(actions.logWin('x', ImpulseMode.diy, 0), isFalse);
  });

  test('sweeping moves this month\'s wins into a goal exactly once', () {
    final before = container.read(goalsProvider).first.savedCents;
    actions.sweepToGoal('g1');
    expect(container.read(goalsProvider).first.savedCents, before + 4650);
    expect(container.read(impulseStatsProvider).unsweptMonthCents, 0);
    actions.sweepToGoal('g1');
    expect(container.read(goalsProvider).first.savedCents, before + 4650);
  });

  test('allocation is capped by free cash', () {
    final moved = actions.allocate('g2', 99999999);
    expect(moved, 205000);
    expect(container.read(financeProvider).freeCashCents, 0);
    expect(actions.allocate('g2', 100), 0);
  });

  test('reclaim spends the chamber, adds a trophy, leaves and an oak level', () {
    actions.allocate('g2', 40000); // PC Build reaches 100%
    final trophy = actions.reclaim('g2');
    expect(trophy, isNotNull);
    expect(trophy!.note, contains('cozy gaming'));
    expect(container.read(goalsProvider).map((g) => g.id), ['g1']);
    expect(container.read(trophiesProvider).length, 2);
    expect(container.read(financeProvider).oakLevel, 2);
    expect(container.read(settingsProvider).goldenLeaves, 45 + 25);
    expect(container.read(settingsProvider).checkingCents, 605000 - 120000);
    expect(harness.repository.goals.containsKey('g2'), isFalse);
    expect(harness.repository.trophies.length, 2);
  });

  test('cannot reclaim an unfinished chamber', () {
    expect(actions.reclaim('g1'), isNull);
  });

  test('decor costs leaves once, then toggles for free', () {
    actions.buyOrToggleDecor(DecorKey.twilightSky);
    expect(container.read(settingsProvider).goldenLeaves, 10);
    expect(container.read(decorProvider)[DecorKey.twilightSky]!.active, isTrue);
    actions.buyOrToggleDecor(DecorKey.twilightSky);
    expect(container.read(decorProvider)[DecorKey.twilightSky]!.active, isFalse);
    actions.buyOrToggleDecor(DecorKey.twilightSky);
    expect(container.read(settingsProvider).goldenLeaves, 10, reason: 'no double charge');
    actions.buyOrToggleDecor(DecorKey.espressoBar);
    expect(container.read(decorProvider)[DecorKey.espressoBar]!.owned, isFalse, reason: 'too few leaves');
  });

  test('Professor Hoot gifts leaves once per day', () {
    actions.greetHoot();
    actions.greetHoot();
    expect(container.read(settingsProvider).goldenLeaves, 60);
    expect(container.read(settingsProvider).hootGreetedOn, Dates.dayKey(DateTime.now()));
  });

  test('focus reward uses the hearth multiplier and warms it', () {
    actions.awardFocus(1500);
    expect(container.read(settingsProvider).goldenLeaves, 45 + 31);
    expect(container.read(settingsProvider).hearthWarmth, 3);
  });

  test('start fresh wipes the stash; restore brings the demo back', () async {
    await actions.startFresh();
    expect(container.read(goalsProvider), isEmpty);
    expect(container.read(financeProvider).checkingCents, 0);
    expect(harness.repository.goals, isEmpty);
    await actions.restoreDemo();
    expect(container.read(goalsProvider).length, 2);
    expect(container.read(financeProvider).checkingCents, 605000);
  });
}
