import '../models/bill.dart';
import '../models/decor.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/stash_snapshot.dart';
import '../models/trophy.dart';

/// Persistence boundary. Notifiers update their in-memory state first and
/// then write through to the repository, so the UI never waits on disk.
abstract interface class StashRepository {
  Future<StashSnapshot> loadAll();

  /// Atomically replaces every table (used for "Start fresh" / demo restore).
  Future<void> replaceAll(StashSnapshot snapshot);

  Future<void> putSetting(String key, String value);

  Future<void> upsertBill(Bill bill);
  Future<void> deleteBill(String id);

  Future<void> upsertGoal(Goal goal);
  Future<void> deleteGoal(String id);

  Future<void> upsertTrophy(Trophy trophy);

  Future<void> upsertChip(ImpulseChip chip);
  Future<void> deleteChip(String id);

  Future<void> upsertLogs(List<ImpulseLog> logs);
  Future<void> deleteLog(String id);

  Future<void> upsertHolding(Holding holding);
  Future<void> deleteHolding(String id);

  Future<void> upsertDecor(DecorItemState decor);

  Future<void> close();
}
