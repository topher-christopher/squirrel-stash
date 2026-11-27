import '../models/bill.dart';
import '../models/decor.dart';
import '../models/feat.dart';
import '../models/goal.dart';
import '../models/grocery_trip.dart';
import '../models/habit.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/metro_ride.dart';
import '../models/stash_snapshot.dart';
import '../models/trophy.dart';
import 'stash_repository.dart';

/// Volatile [StashRepository] for tests, previews, or as a fallback when the
/// on-device database cannot be opened.
class MemoryStashRepository implements StashRepository {
  MemoryStashRepository([StashSnapshot initial = const StashSnapshot()]) {
    _load(initial);
  }

  final Map<String, String> settings = {};
  final Map<String, Bill> bills = {};
  final Map<String, BillStatement> statements = {};
  final Map<String, Goal> goals = {};
  final Map<String, Trophy> trophies = {};
  final Map<String, Habit> habits = {};
  final Map<String, ImpulseLog> logs = {};
  final Map<String, Holding> holdings = {};
  final Map<DecorKey, DecorItemState> decor = {};
  final Map<String, GroceryTrip> groceries = {};
  final Map<String, MetroRide> rides = {};
  final Map<String, FeatAward> awards = {};

  static void _fill<K, V>(Map<K, V> target, Iterable<V> items, K Function(V) key) {
    target
      ..clear()
      ..addEntries(items.map((v) => MapEntry(key(v), v)));
  }

  void _load(StashSnapshot s) {
    settings
      ..clear()
      ..addAll(s.settings);
    _fill(bills, s.bills, (b) => b.id);
    _fill(statements, s.statements, (b) => b.id);
    _fill(goals, s.goals, (g) => g.id);
    _fill(trophies, s.trophies, (t) => t.id);
    _fill(habits, s.habits, (h) => h.id);
    _fill(logs, s.logs, (l) => l.id);
    _fill(holdings, s.holdings, (h) => h.id);
    _fill(decor, s.decor, (d) => d.key);
    _fill(groceries, s.groceries, (g) => g.id);
    _fill(rides, s.rides, (r) => r.id);
    _fill(awards, s.awards, (a) => a.uniqueKey);
  }

  @override
  Future<StashSnapshot> loadAll() async => StashSnapshot(
        settings: Map.of(settings),
        bills: bills.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        statements: statements.values.toList()..sort((a, b) => a.yearMonth.compareTo(b.yearMonth)),
        goals: goals.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        trophies: trophies.values.toList()..sort((a, b) => b.reclaimedAt.compareTo(a.reclaimedAt)),
        habits: habits.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        logs: logs.values.toList()..sort((a, b) => b.loggedAt.compareTo(a.loggedAt)),
        holdings: holdings.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        decor: decor.values.toList(),
        groceries: groceries.values.toList()..sort((a, b) => b.tripAt.compareTo(a.tripAt)),
        rides: rides.values.toList()..sort((a, b) => b.rideAt.compareTo(a.rideAt)),
        awards: awards.values.toList()..sort((a, b) => a.awardedAt.compareTo(b.awardedAt)),
      );

  @override
  Future<void> replaceAll(StashSnapshot snapshot) async => _load(snapshot);

  @override
  Future<void> putSetting(String key, String value) async => settings[key] = value;

  @override
  Future<void> upsertBill(Bill bill) async => bills[bill.id] = bill;

  @override
  Future<void> deleteBill(String id) async {
    bills.remove(id);
    statements.removeWhere((_, s) => s.billId == id);
  }

  @override
  Future<void> upsertStatement(BillStatement s) async {
    statements.removeWhere((_, x) => x.billId == s.billId && x.yearMonth == s.yearMonth);
    statements[s.id] = s;
  }

  @override
  Future<void> deleteStatement(String id) async => statements.remove(id);

  @override
  Future<void> upsertGoal(Goal goal) async => goals[goal.id] = goal;

  @override
  Future<void> deleteGoal(String id) async => goals.remove(id);

  @override
  Future<void> upsertTrophy(Trophy trophy) async => trophies[trophy.id] = trophy;

  @override
  Future<void> upsertHabit(Habit habit) async => habits[habit.id] = habit;

  @override
  Future<void> deleteHabit(String id) async => habits.remove(id);

  @override
  Future<void> upsertLogs(List<ImpulseLog> items) async {
    for (final l in items) {
      logs[l.id] = l;
    }
  }

  @override
  Future<void> deleteLog(String id) async => logs.remove(id);

  @override
  Future<void> upsertHoldings(List<Holding> items) async {
    for (final h in items) {
      holdings[h.id] = h;
    }
  }

  @override
  Future<void> deleteHolding(String id) async => holdings.remove(id);

  @override
  Future<void> upsertDecor(DecorItemState item) async => decor[item.key] = item;

  @override
  Future<void> upsertGrocery(GroceryTrip trip) async => groceries[trip.id] = trip;

  @override
  Future<void> deleteGrocery(String id) async => groceries.remove(id);

  @override
  Future<void> upsertRide(MetroRide ride) async => rides[ride.id] = ride;

  @override
  Future<void> deleteRide(String id) async => rides.remove(id);

  @override
  Future<void> upsertAwards(List<FeatAward> items) async {
    for (final a in items) {
      awards[a.uniqueKey] = a;
    }
  }

  @override
  Future<void> close() async {}
}
