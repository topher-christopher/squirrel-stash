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
import '../models/feat.dart';
import '../models/goal.dart';
import '../models/room.dart';
import '../models/trophy.dart';
import 'economy.dart';
import 'finance_math.dart';
import 'finance_providers.dart';
import 'goals_provider.dart';
import 'repository_providers.dart';
import 'reserves_provider.dart';
import 'reward_service.dart';
import 'rooms_provider.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';

final stashActionsProvider = Provider<StashActions>(StashActions.new);

/// User actions that span several domains (cash + goals + trophies +
/// Acorns) and carry the cozy feedback: banners, haptics, chimes, effects.
/// Willpower, Kitchen and Metro logging live in `WillpowerActions`.
class StashActions {
  StashActions(this._ref);

  final Ref _ref;

  SettingsNotifier get _settings => _ref.read(settingsProvider.notifier);
  GoalsNotifier get _goals => _ref.read(goalsProvider.notifier);
  UiNotifier get _ui => _ref.read(uiProvider.notifier);
  RewardService get _rewards => _ref.read(rewardServiceProvider);
  FinanceSummary get _finance => _ref.read(financeProvider);

  void _emit(DioramaEvent e) => _ref.read(dioramaEventsProvider).emit(e);

  void banner(String text, {String icon = '✨'}) => _ui.showBanner(text, icon: icon);

  // ---------------------------------------------------------------- Cash
  void payday() {
    final amount = _ref.read(settingsProvider).paydayCents;
    _settings.update((s) => s.copyWith(
        checkingCents: s.checkingCents + amount, lastPaydayOn: Dates.dayKey(DateTime.now())));
    _ui.startPaydayBurst();
    _emit(const DioramaEvent(DioramaEventKind.payday, room: RoomKey.treasury));
    banner('Payday delivery! Squirrels hauled +${Money.whole(amount)} up to the '
        'Canopy Treasury!', icon: '🌰');
    Haptics.success();
    _rewards.sfx(Sfx.plink);
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
    banner('Squirrels excavated a new chamber for ${goal.name}!', icon: '⛏️');
    Haptics.success();
    return goal;
  }

  /// Moves free cash into a chamber, capped at what's unallocated.
  int allocate(String goalId, int cents) {
    final actual = math.min(_finance.freeCashCents, cents);
    if (actual <= 0) {
      banner('No free acorns left — every dollar is already stashed.', icon: '🌰');
      Haptics.warn();
      return 0;
    }
    _goals.addSaved(goalId, actual);
    _emit(const DioramaEvent(DioramaEventKind.allocate, room: RoomKey.goals));
    Haptics.success();
    _rewards.sfx(Sfx.plink);
    return actual;
  }

  /// Returns acorns from a chamber back to Free Cash.
  void release(String goalId, int cents) {
    final goal = _goals.byId(goalId);
    if (goal == null) return;
    _goals.addSaved(goalId, -math.min(cents, goal.savedCents));
    Haptics.tap();
  }

  /// Seals a 100% chamber: spends its cash, raises a themed statue in the
  /// Trophy Hall, pays Acorns + a Golden Acorn and grows the Great Oak.
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
    _settings.update((s) => s.copyWith(
          acorns: s.acorns + Economy.goalReclaimAcorns,
          goldenAcorns: s.goldenAcorns + Economy.goalReclaimGolden,
        ));
    _emit(const DioramaEvent(DioramaEventKind.reclaim, room: RoomKey.trophyHall));
    banner('Reclaimed ${goal.name} (${Money.whole(goal.targetCents)})! A statue joins the '
        'Trophy Hall • +${Economy.goalReclaimAcorns} Acorns & +1 Golden Acorn', icon: '🏆');
    Haptics.celebrate();
    _rewards.sfx(Sfx.chime);
    _rewards.evaluateFeats(announce: false);
    return trophy;
  }

  /// Fills in a dug chamber; its acorns flow back to Free Cash.
  void dissolveGoal(String goalId) {
    final goal = _goals.byId(goalId);
    if (goal == null) return;
    _goals.remove(goalId);
    banner('${goal.name} chamber filled in — ${Money.whole(goal.savedCents)} returned to '
        'Free Cash.', icon: '🪨');
  }

  // ------------------------------------------------------------- Rewards
  /// Professor Hoot gifts Acorns once per day.
  void greetHoot() {
    final today = Dates.dayKey(DateTime.now());
    if (_ref.read(settingsProvider).hootGreetedOn != today) {
      _settings.update((s) =>
          s.copyWith(hootGreetedOn: today, acorns: s.acorns + Economy.hootGiftAcorns));
      _emit(const DioramaEvent(DioramaEventKind.hootGift));
      banner('Professor Hoot dropped +${Economy.hootGiftAcorns} Acorns from the canopy!',
          icon: '🦉');
      Haptics.success();
      _rewards.sfx(Sfx.chime);
    } else {
      banner('Professor Hoot hoots approvingly from his branch!', icon: '🦉');
      Haptics.tap();
    }
  }

  void awardFocus(int totalSeconds) {
    final warmth = _ref.read(settingsProvider).hearthWarmth;
    final earned = Economy.focusReward(totalSeconds: totalSeconds, warmth: warmth);
    _settings.update((s) => s.copyWith(
          acorns: s.acorns + earned,
          focusShiftsCompleted: s.focusShiftsCompleted + 1,
          focusMinutesTotal: s.focusMinutesTotal + (totalSeconds / 60).round(),
        ));
    _settings.warmHearth();
    _emit(const DioramaEvent(DioramaEventKind.focusComplete));
    banner('Focus Shift complete! Your study squirrel gathered +$earned Acorns!', icon: '⏳');
    Haptics.celebrate();
    _rewards.sfx(Sfx.chime);
    _rewards.evaluateFeats();
  }

  /// Owned Grand Tree upgrades toggle; unowned ones cost Acorns + Golden.
  void buyOrToggleDecor(DecorKey key) {
    final decor = _ref.read(decorProvider.notifier);
    final item = _ref.read(decorProvider)[key]!;
    if (item.owned) {
      decor.put(item.copyWith(enabled: !item.enabled));
      Haptics.tap();
      return;
    }
    final s = _ref.read(settingsProvider);
    if (s.acorns < key.acornCost || s.goldenAcorns < key.goldenCost) {
      banner('Not enough yet for ${key.label} — keep foraging!', icon: '🌰');
      Haptics.warn();
      return;
    }
    _settings.update((x) => x.copyWith(
        acorns: x.acorns - key.acornCost, goldenAcorns: x.goldenAcorns - key.goldenCost));
    decor.put(item.copyWith(owned: true, enabled: true));
    _emit(const DioramaEvent(DioramaEventKind.upgrade));
    banner('Grand Tree upgrade unlocked: ${key.label}!', icon: '🌳');
    Haptics.success();
    _rewards.sfx(Sfx.chime);
  }

  /// Spends Acorns to raise one room's visual level.
  bool upgradeRoom(RoomKey room) {
    final rooms = _ref.read(roomsProvider);
    final level = rooms.levelOf(room);
    if (level >= RoomLevels.max) return false;
    final cost = RoomLevels.costFor(level + 1);
    if (_ref.read(settingsProvider).acorns < cost) {
      banner('${cost - _ref.read(settingsProvider).acorns} more Acorns to upgrade ${room.title}.',
          icon: '🌰');
      Haptics.warn();
      return false;
    }
    _settings.addAcorns(-cost);
    _ref.read(roomsProvider.notifier).setLevel(room, level + 1);
    _emit(DioramaEvent(DioramaEventKind.upgrade, room: room));
    banner('${room.title} upgraded to ${RoomLevels.name(level + 1)}!', icon: '🔨');
    Haptics.success();
    _rewards.sfx(Sfx.chime);
    return true;
  }

  // --------------------------------------------------------------- Study
  void toggleZen() {
    _settings.update((s) => s.copyWith(zenMode: !s.zenMode));
    Haptics.light();
  }

  void togglePrivacy() {
    _settings.update((s) => s.copyWith(privacyMode: !s.privacyMode));
    Haptics.light();
  }

  /// Canopy Stargazer: 60 seconds of uninterrupted Cozy Zen.
  void finishedStargazing() => _rewards.grantMystery(Feats.canopyStargazer);

  /// Window Shopper: swiped through every room in the drawer.
  void visitedRoom(RoomKey room) {
    if (_ui.visitRoom(room)) _rewards.grantMystery(Feats.windowShopper);
  }

  Future<void> restoreDemo() async {
    await _ref.read(stashSnapshotProvider.notifier).replace(SeedData.demo(DateTime.now()));
    banner('Demo Great Oak restored.', icon: '🌳');
  }

  Future<void> startFresh() async {
    await _ref.read(stashSnapshotProvider.notifier).replace(SeedData.fresh());
    banner('A fresh oak awaits — log your checking balance to begin!', icon: '🌱');
  }
}
