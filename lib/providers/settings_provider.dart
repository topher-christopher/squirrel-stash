import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'repository_providers.dart';

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Scalar settings: checking balance, Acorns, Warm Hearth, Cozy Zen, …
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      AppSettings.fromMap(ref.watch(stashSnapshotProvider).settings);

  /// Applies [change] and persists only the keys that actually changed.
  void update(AppSettings Function(AppSettings current) change) {
    final before = state.toMap();
    final next = change(state);
    final after = next.toMap();
    state = next;
    final repo = ref.read(stashRepositoryProvider);
    after.forEach((key, value) {
      if (before[key] != value) persist(repo.putSetting(key, value));
    });
  }

  void addChecking(int deltaCents) => update((s) {
        final next = s.checkingCents + deltaCents;
        return s.copyWith(checkingCents: next < 0 ? 0 : next);
      });

  void setChecking(int cents) =>
      update((s) => s.copyWith(checkingCents: cents < 0 ? 0 : cents));

  void addAcorns(int delta) => update((s) {
        final next = s.acorns + delta;
        return s.copyWith(acorns: next < 0 ? 0 : next);
      });

  void addGolden(int delta) => update((s) {
        final next = s.goldenAcorns + delta;
        return s.copyWith(goldenAcorns: next < 0 ? 0 : next);
      });

  /// Warm Hearth never cools down — it only grows (non-punitive streak).
  void warmHearth() => update(
      (s) => s.copyWith(hearthWarmth: s.hearthWarmth >= 3 ? 3 : s.hearthWarmth + 1));
}
