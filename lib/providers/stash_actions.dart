import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_service.dart';
import '../core/dates.dart';
import '../core/haptics.dart';
import '../core/ids.dart';
import '../core/money.dart';
import '../database/seed_data.dart';
import '../game/diorama_event.dart';
import '../models/decor.dart';
import '../models/goal.dart';
import '../models/impulse.dart';
import '../models/trophy.dart';
import 'finance_math.dart';
import 'finance_providers.dart';
import 'goals_provider.dart';
import 'impulse_provider.dart';
import 'repository_providers.dart';
import 'reserves_provider.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';

final stashActionsProvider = Provider<StashActions>(StashActions.new);

/// User actions that span several domains (cash + goals + trophies + leaves)
/// and carry the cozy feedback: banners, haptics, chimes, diorama effects.
class StashActions {
  StashActions(this._ref);

  final Ref _ref;

  SettingsNotifier get _settings => _ref.read(settingsProvider.notifier);
  GoalsNotifier get _goals => _ref.read(goalsProvider.notifier);
  UiNotifier get _ui => _ref.read(uiProvider.notifier);
  FinanceSummary get _finance => _ref.read(financeProvider);

  void _emit(DioramaEvent e) => _ref.read(dioramaEventsProvider).emit(e);

  void _sfx(Sfx sfx) {
    if (_ref.read(settingsProvider).sfxOn) {
      _ref.read(audioServiceProvider).play(sfx);
    }
  }

  void banner(String text, {String icon = '✨'}) =>
      _ui.showBanner(text, icon: icon);

  // ---------------------------------------------------------------- Cash
  void payday() {
    final amount = _ref.read(settingsProvider).paydayCents;
    _settings.addChecking(amount);
    _ui.startPaydayBurst();
    _emit(const DioramaEvent(DioramaEventKind.payday));
    banner('Payday delivery! Squirrels hauled +${Money.whole(amount)} into '
        'your Free Cash pile!', icon: '🌰');
    Haptics.success();
    _sfx(Sfx.plink);
  }

  /// Spending never dips into cash already reserved inside Goal Chambers.
  void spend(int cents) {
    final f = _finance;
    _settings.setChecking(math.max(f.allocatedCents, f.checkingCents - cents));
    Haptics.tap();
  }

  void setChecking(int cents) {
    _settings.setChecking(cents);
    Haptics.success();
  }

  // ---------------------------------------------------------- Impulse Lab
  bool logWin(String label, ImpulseMode mode, int cents) {
    final clean = label.trim();
    if (clean.isEmpty || cents <= 0) return false;
    _ref
        .read(impulseLogsProvider.notifier)
        .add(label: clean, mode: mode, amountCents: cents);
    _settings.warmHearth();
    _ui.showLabReaction('+${Money.smart(cents)} Saved!');
    _emit(DioramaEvent(DioramaEventKind.impulseWin, mode: mode));
    Haptics.success();
    _sfx(Sfx.plink);
    return true;
  }

  bool addChipAndLog(String label, ImpulseMode mode, int cents) {
    final clean = label.trim();
    if (clean.isEmpty || cents <= 0) return false;
    _ref
        .read(impulseChipsProvider.notifier)
        .add(label: clean, mode: mode, amountCents: cents);
    return logWin(clean, mode, cents);
  }

  void sweepToGoal(String goalId) {
    final goal = _goals.byId(goalId);
    if (goal == null) return;
    final plan = FinanceMath.planSweep(
        _ref.read(impulseLogsProvider), _finance.freeCashCents, DateTime.now());
    if (plan.cents <= 0) {
      final unswept = _ref.read(impulseStatsProvider).unsweptMonthCents;
      banner(
          unswept <= 0
              ? 'No new willpower wins to sweep this month yet.'
              : 'All checking cash is already allocated to goals!',
          icon: '🌰');
      Haptics.warn();
      return;
    }
    _goals.addSaved(goalId, plan.cents);
    _ref.read(impulseLogsProvider.notifier).markSwept(plan.logIds);
    _emitAllocate(goalId);
    banner('Swept ${Money.smart(plan.cents)} of willpower wins straight into '
        '${goal.name}!', icon: '🧹');
    Haptics.success();
  }

  // --------------------------------------------------------------- Goals
  Goal createGoal({
    required String name,
    required String icon,
    required int targetCents,
    required DateTime dueDate,
    required bool priority,
    required String note,
  }) {
    final goal = _goals.add(
      name: name,
      icon: icon,
      targetCents: targetCents,
      dueDate: dueDate,
      priority: priority,
      note: note.isEmpty ? 'Steady acorns fill the chest.' : note,
    );
    final index = _ref.read(goalsProvider).indexWhere((g) => g.id == goal.id);
    _ui.setGoalPage(index ~/ 2);
    banner('Squirrels excavated a new chamber for ${goal.name}!', icon: '⛏️');
    Haptics.success();
    return goal;
  }

  /// Moves free cash into a chamber, capped at what's unallocated.
  int allocate(String goalId, int cents) {
    final actual = math.min(_finance.freeCashCents, cents);
    if (actual <= 0) {
      banner('No free acorns left — every dollar is already stashed.',
          icon: '🌰');
      Haptics.warn();
      return 0;
    }
    _goals.addSaved(goalId, actual);
    _emitAllocate(goalId);
    Haptics.success();
    _sfx(Sfx.plink);
    return actual;
  }

  /// Returns acorns from a chamber back to Free Cash.
  void release(String goalId, int cents) {
    final goal = _goals.byId(goalId);
    if (goal == null) return;
    _goals.addSaved(goalId, -math.min(cents, goal.savedCents));
    Haptics.tap();
  }

  /// Seals a 100% chamber: spends its acorns, places a relic on the Trophy
  /// Stand, grants +25 Golden Leaves and grows the Great Oak.
  Trophy? reclaim(String goalId) {
    final goal = _goals.byId(goalId);
    if (goal == null || !goal.isComplete) return null;
    _settings.addChecking(-goal.savedCents);
    _goals.remove(goal.id);
    final trophy = Trophy(
      id: newId('trophy'),
      name: goal.name,
      icon: goal.icon,
      amountCents: goal.targetCents,
      reclaimedAt: DateTime.now(),
      note: goal.note.isEmpty ? 'Milestone conquered and reclaimed!' : goal.note,
    );
    _ref.read(trophiesProvider.notifier).add(trophy);
    _settings.addLeaves(25);
    _clampGoalPage();
    _emit(const DioramaEvent(DioramaEventKind.reclaim));
    banner('Reclaimed ${goal.name} (${Money.whole(goal.targetCents)})! Added '
        'trophy to your desk & +25 Golden Leaves!', icon: '🏆');
    Haptics.celebrate();
    _sfx(Sfx.chime);
    return trophy;
  }

  /// Fills in a dug chamber; its acorns flow back to Free Cash.
  void dissolveGoal(String goalId) {
    final goal = _goals.byId(goalId);
    if (goal == null) return;
    _goals.remove(goalId);
    _clampGoalPage();
    banner('${goal.name} chamber filled in — ${Money.whole(goal.savedCents)} '
        'returned to Free Cash.', icon: '🪨');
  }

  void _clampGoalPage() {
    final maxPage = FinanceMath.maxGoalPage(_ref.read(goalsProvider).length);
    if (_ref.read(uiProvider).goalPage > maxPage) _ui.setGoalPage(maxPage);
  }

  void _emitAllocate(String goalId) {
    final index = _ref.read(goalsProvider).indexWhere((g) => g.id == goalId);
    final onPage = index >= 0 && index ~/ 2 == _ref.read(uiProvider).goalPage;
    _emit(DioramaEvent(DioramaEventKind.allocate, slot: onPage ? index % 2 : null));
  }

  // ------------------------------------------------------------- Rewards
  /// Professor Hoot gifts +15 Golden Leaves once per day.
  void greetHoot() {
    final today = Dates.dayKey(DateTime.now());
    if (_ref.read(settingsProvider).hootGreetedOn != today) {
      _settings.update((s) => s.copyWith(
          hootGreetedOn: today, goldenLeaves: s.goldenLeaves + 15));
      _emit(const DioramaEvent(DioramaEventKind.hootGift));
      banner('Professor Hoot tapped on your study window and gifted +15 '
          'Golden Leaves!', icon: '🦉');
      Haptics.success();
      _sfx(Sfx.chime);
    } else {
      banner('Professor Hoot hoots approvingly from the oak branch!',
          icon: '🦉');
      Haptics.tap();
    }
  }

  void awardFocus(int totalSeconds) {
    final warmth = _ref.read(settingsProvider).hearthWarmth;
    final earned =
        FinanceMath.focusReward(totalSeconds: totalSeconds, warmth: warmth);
    _settings.addLeaves(earned);
    _settings.warmHearth();
    _emit(const DioramaEvent(DioramaEventKind.focusComplete));
    banner('Focus Shift complete! Your study squirrel gathered +$earned '
        'Golden Leaves!', icon: '🍃');
    Haptics.celebrate();
    _sfx(Sfx.chime);
  }

  /// Owned decor toggles on/off; unowned decor costs Golden Leaves once.
  void buyOrToggleDecor(DecorKey key) {
    final decor = _ref.read(decorProvider.notifier);
    final item = _ref.read(decorProvider)[key]!;
    if (item.owned) {
      decor.put(item.copyWith(enabled: !item.enabled));
      Haptics.tap();
      return;
    }
    final leaves = _ref.read(settingsProvider).goldenLeaves;
    if (leaves < key.cost) {
      banner('${key.cost - leaves} more Golden Leaves needed for '
          '${key.label}.', icon: '🍃');
      Haptics.warn();
      return;
    }
    _settings.addLeaves(-key.cost);
    decor.put(item.copyWith(owned: true, enabled: true));
    _emit(const DioramaEvent(DioramaEventKind.decor));
    banner('Unlocked ${key.label}!', icon: key.emoji);
    Haptics.success();
    _sfx(Sfx.chime);
  }

  // --------------------------------------------------------------- Study
  void cycleScene() {
    _settings.update((s) => s.copyWith(scene: s.scene.next));
    Haptics.tap();
  }

  void toggleZen() {
    _settings.update((s) => s.copyWith(zenMode: !s.zenMode));
    Haptics.light();
  }

  Future<void> restoreDemo() async {
    await _ref
        .read(stashSnapshotProvider.notifier)
        .replace(SeedData.demo(DateTime.now()));
    _ui.setGoalPage(0);
    banner('Demo hollow restored.', icon: '🌳');
  }

  Future<void> startFresh() async {
    await _ref.read(stashSnapshotProvider.notifier).replace(SeedData.fresh());
    _ui.setGoalPage(0);
    banner('A fresh hollow awaits — log your checking balance to begin!',
        icon: '🌱');
  }
}
