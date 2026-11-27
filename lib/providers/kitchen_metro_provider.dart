import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../models/grocery_trip.dart';
import '../models/metro_ride.dart';
import 'repository_providers.dart';

final groceriesProvider =
    NotifierProvider<GroceriesNotifier, List<GroceryTrip>>(GroceriesNotifier.new);

/// Grocery runs logged in the Squirrel Kitchen, newest first.
class GroceriesNotifier extends Notifier<List<GroceryTrip>> {
  @override
  List<GroceryTrip> build() => ref.watch(stashSnapshotProvider).groceries.toList()
    ..sort((a, b) => b.tripAt.compareTo(a.tripAt));

  GroceryTrip add({required String store, required int amountCents, int? itemCount}) {
    final trip = GroceryTrip(
      id: newId('trip'),
      store: store,
      amountCents: amountCents,
      itemCount: itemCount,
      tripAt: DateTime.now(),
    );
    state = [trip, ...state];
    persist(ref.read(stashRepositoryProvider).upsertGrocery(trip));
    return trip;
  }

  void remove(String id) {
    state = [for (final t in state) if (t.id != id) t];
    persist(ref.read(stashRepositoryProvider).deleteGrocery(id));
  }
}

final ridesProvider =
    NotifierProvider<RidesNotifier, List<MetroRide>>(RidesNotifier.new);

/// Paid Metro rides, newest first.
class RidesNotifier extends Notifier<List<MetroRide>> {
  @override
  List<MetroRide> build() => ref.watch(stashSnapshotProvider).rides.toList()
    ..sort((a, b) => b.rideAt.compareTo(a.rideAt));

  MetroRide add(MetroFare fare, int amountCents) {
    final ride = MetroRide(
      id: newId('ride'),
      fare: fare,
      amountCents: amountCents,
      rideAt: DateTime.now(),
    );
    state = [ride, ...state];
    persist(ref.read(stashRepositoryProvider).upsertRide(ride));
    return ride;
  }

  void remove(String id) {
    state = [for (final r in state) if (r.id != id) r];
    persist(ref.read(stashRepositoryProvider).deleteRide(id));
  }
}
