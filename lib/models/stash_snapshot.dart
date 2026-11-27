import 'bill.dart';
import 'decor.dart';
import 'goal.dart';
import 'holding.dart';
import 'impulse.dart';
import 'trophy.dart';

/// Everything persisted on-device, loaded in one pass at startup and used
/// to seed the Riverpod notifiers (and to restore/reset the stash).
class StashSnapshot {
  const StashSnapshot({
    this.settings = const {},
    this.bills = const [],
    this.goals = const [],
    this.trophies = const [],
    this.chips = const [],
    this.logs = const [],
    this.holdings = const [],
    this.decor = const [],
  });

  final Map<String, String> settings;
  final List<Bill> bills;
  final List<Goal> goals;
  final List<Trophy> trophies;
  final List<ImpulseChip> chips;
  final List<ImpulseLog> logs;
  final List<Holding> holdings;
  final List<DecorItemState> decor;

  bool get isEmpty =>
      settings.isEmpty &&
      bills.isEmpty &&
      goals.isEmpty &&
      trophies.isEmpty &&
      chips.isEmpty &&
      logs.isEmpty &&
      holdings.isEmpty &&
      decor.isEmpty;
}
