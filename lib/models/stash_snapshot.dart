import 'bill.dart';
import 'bird.dart';
import 'decor.dart';
import 'expedition.dart';
import 'feat.dart';
import 'goal.dart';
import 'grocery_trip.dart';
import 'habit.dart';
import 'holding.dart';
import 'impulse.dart';
import 'metro_ride.dart';
import 'trophy.dart';

/// Everything persisted on-device, loaded in one pass at startup and used
/// to seed the Riverpod notifiers (and to restore/reset the stash).
class StashSnapshot {
  const StashSnapshot({
    this.settings = const {},
    this.bills = const [],
    this.statements = const [],
    this.goals = const [],
    this.trophies = const [],
    this.habits = const [],
    this.logs = const [],
    this.holdings = const [],
    this.decor = const [],
    this.groceries = const [],
    this.rides = const [],
    this.awards = const [],
    this.expeditions = const [],
    this.seedBags = const {},
    this.birdLog = const [],
  });

  final Map<String, String> settings;
  final List<Bill> bills;
  final List<BillStatement> statements;
  final List<Goal> goals;

  /// Goal statues from reclaimed chambers.
  final List<Trophy> trophies;
  final List<Habit> habits;
  final List<ImpulseLog> logs;
  final List<Holding> holdings;
  final List<DecorItemState> decor;
  final List<GroceryTrip> groceries;
  final List<MetroRide> rides;
  final List<FeatAward> awards;

  /// Scavenger Burrow squads (active and returned).
  final List<Expedition> expeditions;

  /// Ready-to-pour seed bags on hand.
  final Map<SeedKind, int> seedBags;

  /// Lifetime Bird & Critter Logbook.
  final List<BirdLogEntry> birdLog;

  bool get isEmpty =>
      settings.isEmpty &&
      bills.isEmpty &&
      statements.isEmpty &&
      goals.isEmpty &&
      trophies.isEmpty &&
      habits.isEmpty &&
      logs.isEmpty &&
      holdings.isEmpty &&
      decor.isEmpty &&
      groceries.isEmpty &&
      rides.isEmpty &&
      awards.isEmpty &&
      expeditions.isEmpty &&
      seedBags.isEmpty &&
      birdLog.isEmpty;

  StashSnapshot copyWith({
    Map<String, String>? settings,
    List<Bill>? bills,
    List<BillStatement>? statements,
    List<Goal>? goals,
    List<Trophy>? trophies,
    List<Habit>? habits,
    List<ImpulseLog>? logs,
    List<Holding>? holdings,
    List<DecorItemState>? decor,
    List<GroceryTrip>? groceries,
    List<MetroRide>? rides,
    List<FeatAward>? awards,
    List<Expedition>? expeditions,
    Map<SeedKind, int>? seedBags,
    List<BirdLogEntry>? birdLog,
  }) =>
      StashSnapshot(
        settings: settings ?? this.settings,
        bills: bills ?? this.bills,
        statements: statements ?? this.statements,
        goals: goals ?? this.goals,
        trophies: trophies ?? this.trophies,
        habits: habits ?? this.habits,
        logs: logs ?? this.logs,
        holdings: holdings ?? this.holdings,
        decor: decor ?? this.decor,
        groceries: groceries ?? this.groceries,
        rides: rides ?? this.rides,
        awards: awards ?? this.awards,
        expeditions: expeditions ?? this.expeditions,
        seedBags: seedBags ?? this.seedBags,
        birdLog: birdLog ?? this.birdLog,
      );
}
