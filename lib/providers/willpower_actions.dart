import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_service.dart';
import '../core/haptics.dart';
import '../core/money.dart';
import '../game/diorama_event.dart';
import '../models/bill.dart';
import '../models/habit.dart';
import '../models/impulse.dart';
import '../models/metro_ride.dart';
import '../models/room.dart';
import 'bills_provider.dart';
import 'economy.dart';
import 'finance_math.dart';
import 'finance_providers.dart';
import 'goals_provider.dart';
import 'impulse_provider.dart';
import 'kitchen_metro_provider.dart';
import 'reward_service.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';

final willpowerActionsProvider = Provider<WillpowerActions>(WillpowerActions.new);

/// Logging actions: willpower wins, grocery trips, home-cooked meals, Metro
/// fares and card statements. Each pays Acorns where it earns them and
/// re-checks the Trophy Hall.
class WillpowerActions {
  WillpowerActions(this._ref);

  final Ref _ref;

  RewardService get _rewards => _ref.read(rewardServiceProvider);
  SettingsNotifier get _settings => _ref.read(settingsProvider.notifier);
  UiNotifier get _ui => _ref.read(uiProvider.notifier);

  void _emit(DioramaEvent e) => _ref.read(dioramaEventsProvider).emit(e);

  // ----------------------------------------------------------- Willpower
  /// Logs a win for [habit] (doubling for a round trip). Returns false when
  /// the amount is invalid.
  bool logHabit(Habit habit, {int? cents, bool roundTrip = false}) {
    final base = cents ?? habit.amountCents;
    final amount = roundTrip && habit.roundTrip ? base * 2 : base;
    final label = roundTrip && habit.roundTrip ? '${habit.label} (round trip)' : habit.label;
    return logWin(label, habit.mode, amount, habitId: habit.id);
  }

  bool logWin(String label, ImpulseMode mode, int cents, {String? habitId}) {
    final clean = label.trim();
    if (clean.isEmpty || cents <= 0) return false;
    _ref.read(impulseLogsProvider.notifier).add(
        label: clean, mode: mode, amountCents: cents, habitId: habitId);
    final acorns = Economy.acornsForSavings(cents);
    _settings.addAcorns(acorns);
    _settings.warmHearth();
    _ui.showLabReaction('+${Money.smart(cents)} Saved! +$acorns');
    _emit(DioramaEvent(DioramaEventKind.impulseWin, mode: mode, room: RoomKey.lab));
    Haptics.success();
    _rewards.sfx(Sfx.plink);
    final golden = _rewards.forgeGoldenFromSavings();
    if (golden > 0) {
      _rewards.banner('Your willpower forged ${golden == 1 ? 'a Golden Acorn' : '$golden Golden Acorns'}!',
          icon: '🌟');
    }
    _rewards.evaluateFeats();
    return true;
  }

  bool addHabitAndLog({
    required String label,
    required ImpulseMode mode,
    required int cents,
    HabitEntry entry = HabitEntry.fixed,
  }) {
    final clean = label.trim();
    if (clean.isEmpty || cents <= 0) return false;
    final habit = _ref.read(habitsProvider.notifier).add(
        label: clean, mode: mode, amountCents: cents, entry: entry);
    return logHabit(habit);
  }

  /// Undoes a mistaken log and returns its Acorns (Golden Acorns already
  /// forged stay forged, so re-logging never pays twice).
  void undoLog(String id) {
    final log = _ref.read(impulseLogsProvider.notifier).remove(id);
    if (log == null) return;
    _settings.addAcorns(-Economy.acornsForSavings(log.amountCents));
    Haptics.tap();
  }

  void sweepToGoal(String goalId) {
    final goals = _ref.read(goalsProvider.notifier);
    final goal = goals.byId(goalId);
    if (goal == null) return;
    final plan = FinanceMath.planSweep(
        _ref.read(impulseLogsProvider), _ref.read(financeProvider).freeCashCents, DateTime.now());
    if (plan.cents <= 0) {
      final unswept = _ref.read(impulseStatsProvider).unsweptMonthCents;
      _rewards.banner(
          unswept <= 0
              ? 'No new willpower wins to sweep this month yet.'
              : 'All checking cash is already allocated to goals!',
          icon: '🌰');
      Haptics.warn();
      return;
    }
    goals.addSaved(goalId, plan.cents);
    _ref.read(impulseLogsProvider.notifier).markSwept(plan.logIds);
    _emit(const DioramaEvent(DioramaEventKind.allocate, room: RoomKey.goals));
    _rewards.banner('Swept ${Money.smart(plan.cents)} of willpower wins into ${goal.name}!',
        icon: '🧹');
    Haptics.success();
  }

  // -------------------------------------------------------------- Kitchen
  bool logGrocery({required String store, required int cents, int? itemCount}) {
    if (cents <= 0) return false;
    _ref.read(groceriesProvider.notifier).add(
        store: store.trim().isEmpty ? 'Grocery run' : store.trim(),
        amountCents: cents,
        itemCount: itemCount);
    _emit(const DioramaEvent(DioramaEventKind.kitchen, room: RoomKey.kitchen));
    _rewards.banner('Grocery trip logged: ${Money.smart(cents)}. The chefs are restocking!',
        icon: '🧺');
    Haptics.success();
    _rewards.evaluateFeats();
    return true;
  }

  /// Logs the built-in "Cooked at Home" habit.
  bool logHomeMeal() {
    final habit = _ref.read(habitsProvider.notifier).byKey(HabitKeys.homeCooked) ??
        _ref.read(habitsProvider.notifier).add(
            label: 'Cooked at Home', mode: ImpulseMode.diy, amountCents: 1200, icon: '🍲');
    _emit(const DioramaEvent(DioramaEventKind.kitchen, room: RoomKey.kitchen));
    return logHabit(habit);
  }

  // ---------------------------------------------------------------- Metro
  bool logRide(MetroFare fare, {int? cents}) {
    final amount = cents ?? fare.cents;
    if (amount <= 0) return false;
    _ref.read(ridesProvider.notifier).add(fare, amount);
    _emit(const DioramaEvent(DioramaEventKind.metroRide, room: RoomKey.metro));
    _rewards.banner('${fare.label} logged: ${Money.smart(amount)}. Doors closing!', icon: '🚇');
    Haptics.success();
    _rewards.evaluateFeats();
    return true;
  }

  // ---------------------------------------------------------------- Bills
  /// Saves [bill]'s statement balance for this cycle (and records history).
  void recordStatement(Bill bill, int cents, {bool markPaid = false}) {
    _ref.read(statementsProvider.notifier).record(bill, cents);
    var next = bill.copyWith(amountCents: cents);
    if (markPaid) next = next.copyWith(paid: true).rolledForward(DateTime.now());
    _ref.read(billsProvider.notifier).upsert(next);
    _rewards.banner('${bill.name} statement saved: ${Money.smart(cents)}${markPaid ? ' • paid' : ''}.',
        icon: '🧾');
    Haptics.success();
  }
}
