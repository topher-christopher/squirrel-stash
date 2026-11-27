import '../models/bill.dart';
import '../models/decor.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
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
  final Map<String, Goal> goals = {};
  final Map<String, Trophy> trophies = {};
  final Map<String, ImpulseChip> chips = {};
  final Map<String, ImpulseLog> logs = {};
  final Map<String, Holding> holdings = {};
  final Map<DecorKey, DecorItemState> decor = {};

  void _load(StashSnapshot s) {
    settings
      ..clear()
      ..addAll(s.settings);
    bills
      ..clear()
      ..addEntries(s.bills.map((b) => MapEntry(b.id, b)));
    goals
      ..clear()
      ..addEntries(s.goals.map((g) => MapEntry(g.id, g)));
    trophies
      ..clear()
      ..addEntries(s.trophies.map((t) => MapEntry(t.id, t)));
    chips
      ..clear()
      ..addEntries(s.chips.map((c) => MapEntry(c.id, c)));
    logs
      ..clear()
      ..addEntries(s.logs.map((l) => MapEntry(l.id, l)));
    holdings
      ..clear()
      ..addEntries(s.holdings.map((h) => MapEntry(h.id, h)));
    decor
      ..clear()
      ..addEntries(s.decor.map((d) => MapEntry(d.key, d)));
  }

  @override
  Future<StashSnapshot> loadAll() async => StashSnapshot(
        settings: Map.of(settings),
        bills: bills.values.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        goals: goals.values.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        trophies: trophies.values.toList()
          ..sort((a, b) => b.reclaimedAt.compareTo(a.reclaimedAt)),
        chips: chips.values.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        logs: logs.values.toList()
          ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt)),
        holdings: holdings.values.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        decor: decor.values.toList(),
      );

  @override
  Future<void> replaceAll(StashSnapshot snapshot) async => _load(snapshot);

  @override
  Future<void> putSetting(String key, String value) async =>
      settings[key] = value;

  @override
  Future<void> upsertBill(Bill bill) async => bills[bill.id] = bill;

  @override
  Future<void> deleteBill(String id) async => bills.remove(id);

  @override
  Future<void> upsertGoal(Goal goal) async => goals[goal.id] = goal;

  @override
  Future<void> deleteGoal(String id) async => goals.remove(id);

  @override
  Future<void> upsertTrophy(Trophy trophy) async => trophies[trophy.id] = trophy;

  @override
  Future<void> upsertChip(ImpulseChip chip) async => chips[chip.id] = chip;

  @override
  Future<void> deleteChip(String id) async => chips.remove(id);

  @override
  Future<void> upsertLogs(List<ImpulseLog> items) async {
    for (final l in items) {
      logs[l.id] = l;
    }
  }

  @override
  Future<void> deleteLog(String id) async => logs.remove(id);

  @override
  Future<void> upsertHolding(Holding holding) async =>
      holdings[holding.id] = holding;

  @override
  Future<void> deleteHolding(String id) async => holdings.remove(id);

  @override
  Future<void> upsertDecor(DecorItemState item) async => decor[item.key] = item;

  @override
  Future<void> close() async {}
}
