import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_service.dart';
import '../core/dates.dart';
import '../core/haptics.dart';
import '../game/diorama_event.dart';
import '../models/feat.dart';
import 'awards_provider.dart';
import 'economy.dart';
import 'feat_engine.dart';
import 'goals_provider.dart';
import 'impulse_provider.dart';
import 'kitchen_metro_provider.dart';
import 'settings_provider.dart';
import 'ui_provider.dart';

final rewardServiceProvider = Provider<RewardService>(RewardService.new);

/// Pays out the Acorn economy and Trophy Hall feats, and plays the cozy
/// feedback for them. Shared by every action class.
class RewardService {
  RewardService(this._ref);

  final Ref _ref;

  SettingsNotifier get _settings => _ref.read(settingsProvider.notifier);

  void _emit(DioramaEvent e) => _ref.read(dioramaEventsProvider).emit(e);

  void sfx(Sfx sfx) {
    if (_ref.read(settingsProvider).sfxOn) _ref.read(audioServiceProvider).play(sfx);
  }

  void banner(String text, {String icon = '✨'}) =>
      _ref.read(uiProvider.notifier).showBanner(text, icon: icon);

  /// Re-checks the $100 willpower milestones; returns Golden Acorns forged.
  int forgeGoldenFromSavings() {
    final lifetime = _ref.read(impulseLogsProvider).fold<int>(0, (s, l) => s + l.amountCents);
    final reached = Economy.goldenMilestones(lifetime);
    final paid = _ref.read(settingsProvider).goldenSavingsMilestones;
    if (reached <= paid) return 0;
    final forged = reached - paid;
    _settings.update((s) => s.copyWith(
          goldenAcorns: s.goldenAcorns + forged,
          goldenSavingsMilestones: reached,
        ));
    if (_ref.read(settingsProvider).lastPaydayOn == Dates.dayKey(DateTime.now())) {
      grantMystery(Feats.doubleHarvest, quiet: true);
    }
    return forged;
  }

  /// Runs the trophy rules and pays any new awards. Returns them.
  List<FeatAward> evaluateFeats({bool announce = true}) {
    final settings = _ref.read(settingsProvider);
    final fresh = FeatEngine.evaluate(FeatInputs(
      logs: _ref.read(impulseLogsProvider),
      habits: _ref.read(habitsProvider),
      rides: _ref.read(ridesProvider),
      groceries: _ref.read(groceriesProvider),
      awards: _ref.read(awardsProvider),
      focusShifts: settings.focusShiftsCompleted,
      goalsReclaimed: _ref.read(trophiesProvider).length,
      now: DateTime.now(),
    ));
    _pay(fresh, announce: announce);
    return fresh;
  }

  /// Event-driven hidden feats (Cozy Zen, Window Shopper, Double Harvest).
  bool grantMystery(String key, {bool quiet = false}) {
    final award = FeatEngine.mysteryAward(key, _ref.read(awardsProvider), DateTime.now());
    if (award == null) return false;
    _pay([award], announce: !quiet);
    return true;
  }

  void _pay(List<FeatAward> awards, {required bool announce}) {
    if (awards.isEmpty) return;
    _ref.read(awardsProvider.notifier).addAll(awards);
    final acorns = awards.fold<int>(0, (s, a) => s + a.acorns);
    final golden = awards.fold<int>(0, (s, a) => s + a.golden);
    if (acorns > 0 || golden > 0) {
      _settings.update((s) => s.copyWith(
            acorns: s.acorns + acorns,
            goldenAcorns: s.goldenAcorns + golden,
          ));
    }
    final visible = awards.where((a) => a.featKey != Feats.fourSeasonsStage).toList();
    if (visible.isEmpty || !announce) return;
    final def = Feats.byKey(visible.last.featKey);
    final extra = visible.length > 1 ? ' (+${visible.length - 1} more)' : '';
    final reward = [
      if (acorns > 0) '+$acorns Acorns',
      if (golden > 0) '+$golden Golden Acorn${golden == 1 ? '' : 's'}',
    ].join(' • ');
    banner('Trophy earned: ${def?.name ?? 'New feat'}$extra${reward.isEmpty ? '' : ' — $reward'}',
        icon: def?.icon ?? '🏆');
    _emit(const DioramaEvent(DioramaEventKind.trophy));
    Haptics.celebrate();
    sfx(Sfx.chime);
  }
}
