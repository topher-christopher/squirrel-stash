import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/haptics.dart';
import '../models/focus_state.dart';
import 'repository_providers.dart';
import 'stash_actions.dart';

final focusProvider =
    NotifierProvider<FocusNotifier, FocusState>(FocusNotifier.new);

/// Brass Focus Shift clock. Wall-clock based: the end time is persisted so
/// a shift keeps counting (and pays out) across backgrounding and restarts.
class FocusNotifier extends Notifier<FocusState> {
  static const _kTotal = 'focus_total_seconds';
  static const _kEndsAt = 'focus_ends_at';
  static const _kPausedLeft = 'focus_paused_left';

  Timer? _ticker;

  @override
  FocusState build() {
    ref.onDispose(() => _ticker?.cancel());
    final saved = ref.watch(stashSnapshotProvider).settings;
    final total = int.tryParse(saved[_kTotal] ?? '') ?? 1500;
    final endsAt = DateTime.tryParse(saved[_kEndsAt] ?? '');
    final pausedLeft = int.tryParse(saved[_kPausedLeft] ?? '');

    if (endsAt != null) {
      final left = _secondsUntil(endsAt);
      if (left > 0) {
        _startTicker();
        return FocusState(
            totalSeconds: total,
            remainingSeconds: left,
            running: true,
            endsAt: endsAt);
      }
      // Finished while the app was closed — pay out right after build.
      Future.microtask(() => _complete(total));
      return FocusState(totalSeconds: total, remainingSeconds: total);
    }
    if (pausedLeft != null && pausedLeft > 0 && pausedLeft < total) {
      return FocusState(totalSeconds: total, remainingSeconds: pausedLeft);
    }
    return FocusState(totalSeconds: total, remainingSeconds: total);
  }

  static int _secondsUntil(DateTime t) {
    final ms = t.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _persist({required int total, DateTime? endsAt, int? pausedLeft}) {
    final repo = ref.read(stashRepositoryProvider);
    persist(repo.putSetting(_kTotal, '$total'));
    persist(repo.putSetting(_kEndsAt, endsAt?.toIso8601String() ?? ''));
    persist(repo.putSetting(_kPausedLeft, pausedLeft?.toString() ?? ''));
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    final endsAt = state.endsAt;
    if (!state.running || endsAt == null) return;
    final left = _secondsUntil(endsAt);
    if (left <= 0) {
      _complete(state.totalSeconds);
    } else if (left != state.remainingSeconds) {
      state = state.copyWith(remainingSeconds: left);
    }
  }

  void start(int seconds) {
    final endsAt = DateTime.now().add(Duration(seconds: seconds));
    state = FocusState(
        totalSeconds: seconds,
        remainingSeconds: seconds,
        running: true,
        endsAt: endsAt);
    _persist(total: seconds, endsAt: endsAt);
    _startTicker();
    ref.read(stashActionsProvider).banner(
        'Focus Shift started! Your study squirrel is working beside you.',
        icon: '⏳');
    Haptics.success();
  }

  void pause() {
    if (!state.running) return;
    _ticker?.cancel();
    final left = state.endsAt == null
        ? state.remainingSeconds
        : _secondsUntil(state.endsAt!);
    state = state.copyWith(running: false, remainingSeconds: left, clearEndsAt: true);
    _persist(total: state.totalSeconds, pausedLeft: left);
    Haptics.tap();
  }

  void resume() {
    if (state.running || state.remainingSeconds <= 0) return;
    final endsAt =
        DateTime.now().add(Duration(seconds: state.remainingSeconds));
    state = state.copyWith(running: true, endsAt: endsAt);
    _persist(total: state.totalSeconds, endsAt: endsAt);
    _startTicker();
    Haptics.tap();
  }

  /// Abandons the current shift without a reward (non-punitive: no streak loss).
  void reset() {
    _ticker?.cancel();
    state = FocusState(
        totalSeconds: state.totalSeconds,
        remainingSeconds: state.totalSeconds);
    _persist(total: state.totalSeconds);
    Haptics.tap();
  }

  void _complete(int total) {
    _ticker?.cancel();
    state = FocusState(totalSeconds: total, remainingSeconds: total);
    _persist(total: total);
    ref.read(stashActionsProvider).awardFocus(total);
  }
}
