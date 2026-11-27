import '../models/bill.dart';
import '../models/bird.dart';
import '../models/decor.dart';
import '../models/expedition.dart';
import '../models/feat.dart';
import '../models/goal.dart';
import '../models/grocery_trip.dart';
import '../models/habit.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/metro_ride.dart';
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

  Future<void> upsertStatement(BillStatement statement);
  Future<void> deleteStatement(String id);

  Future<void> upsertGoal(Goal goal);
  Future<void> deleteGoal(String id);

  Future<void> upsertTrophy(Trophy trophy);

  Future<void> upsertHabit(Habit habit);
  Future<void> deleteHabit(String id);

  Future<void> upsertLogs(List<ImpulseLog> logs);
  Future<void> deleteLog(String id);

  Future<void> upsertHoldings(List<Holding> holdings);
  Future<void> deleteHolding(String id);

  Future<void> upsertDecor(DecorItemState decor);

  Future<void> upsertGrocery(GroceryTrip trip);
  Future<void> deleteGrocery(String id);

  Future<void> upsertRide(MetroRide ride);
  Future<void> deleteRide(String id);

  Future<void> upsertAwards(List<FeatAward> awards);

  Future<void> upsertExpedition(Expedition expedition);

  /// Sets how many bags of [seed] are on hand.
  Future<void> putSeedBags(SeedKind seed, int bags);

  Future<void> upsertBirdLog(List<BirdLogEntry> entries);

  Future<void> close();
}
