import '../models/bill.dart';
import '../models/grocery_trip.dart';
import '../models/habit.dart';
import '../models/impulse.dart';
import '../models/metro_ride.dart';

/// Deterministic demo history (dates relative to install day) so the
/// Trophy Hall, Kitchen, Metro and card trends have something to show.
abstract final class SeedHistory {
  /// Statement history per card, oldest → current cycle (dollars).
  static const cardHistory = <String, List<int>>{
    'b_td': [380, 455, 402, 498, 365, 430, 412],
    'b_qs': [210, 245, 260, 230, 312, 301, 286],
    'b_amz': [150, 320, 175, 160, 240, 225, 198],
    'b_sw': [610, 480, 520, 575, 440, 498, 534],
  };

  static List<BillStatement> statements(List<Bill> bills, DateTime now) {
    final out = <BillStatement>[];
    for (final bill in bills) {
      final history = cardHistory[bill.id];
      if (history == null) continue;
      for (var i = 0; i < history.length; i++) {
        final monthsBack = history.length - 1 - i;
        final cycle = DateTime(bill.dueDate.year, bill.dueDate.month - monthsBack);
        final key = '${cycle.year.toString().padLeft(4, '0')}-${cycle.month.toString().padLeft(2, '0')}';
        out.add(BillStatement(
          id: 'stmt_${bill.id}_$key',
          billId: bill.id,
          yearMonth: key,
          amountCents: history[i] * 100,
          recordedAt: DateTime(cycle.year, cycle.month, 1, 9),
        ));
      }
    }
    return out;
  }

  /// ~10 weeks of willpower wins across the built-in habits.
  static List<ImpulseLog> logs(List<Habit> habits, DateTime now) {
    final byKey = {for (final h in habits) h.id: h};
    final today = DateTime(now.year, now.month, now.day);
    final out = <ImpulseLog>[];
    void add(int day, String habitId, int cents, int hour) {
      final h = byKey[habitId]!;
      final at = today.subtract(Duration(days: day)).add(Duration(hours: hour, minutes: (day * 7) % 60));
      if (at.isAfter(now)) return;
      out.add(ImpulseLog(
        id: 'seed_${habitId}_$day',
        label: h.label,
        mode: h.mode,
        amountCents: cents,
        loggedAt: at,
        habitId: habitId,
        swept: !(at.year == now.year && at.month == now.month),
      ));
    }

    for (var d = 0; d < 72; d++) {
      if (d < 10 || d % 2 == 0) add(d, 'h_cook', 1200, 19);
      if (d % 3 == 0) add(d, 'h_water', 850 + (d % 4) * 100, 21);
      if (d % 5 == 1) add(d, 'h_hop', d % 10 == 1 ? 450 : 225, 8);
      if (d % 7 == 2) add(d, 'h_pickup', 600 + (d % 3) * 150, 18);
      if (d % 9 == 4) add(d, 'h_app', 1100 + (d % 2) * 300, 20);
      if (d % 11 == 3) add(d, 'h_pokemon', 2500, 15);
      if (d % 4 == 1) add(d, 'h_coffee', 250, 9);
      if (d % 13 == 6) add(d, 'h_icecream', 700, 17);
    }
    return out..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  static List<GroceryTrip> groceries(DateTime now) {
    const stores = ["Trader Joe's", 'Giant', 'Whole Foods', 'H Mart', 'Farmers Market', 'Aldi'];
    const amounts = [6420, 11850, 4275, 9310, 3890, 14220, 7605, 5240, 10480, 6930, 8815, 4560];
    final today = DateTime(now.year, now.month, now.day);
    return [
      for (var i = 0; i < amounts.length; i++)
        GroceryTrip(
          id: 'seed_trip_$i',
          store: stores[i % stores.length],
          amountCents: amounts[i],
          itemCount: 8 + (amounts[i] ~/ 900),
          tripAt: today.subtract(Duration(days: 1 + i * 5)).add(const Duration(hours: 11)),
        ),
    ];
  }

  static List<MetroRide> rides(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final out = <MetroRide>[];
    for (var d = 1; d < 40; d++) {
      final day = today.subtract(Duration(days: d));
      final weekend = day.weekday >= 6;
      if (weekend) {
        if (d % 3 == 0) {
          out.add(MetroRide(id: 'seed_ride_${d}_w', fare: MetroFare.weekendMax,
              amountCents: 250, rideAt: day.add(const Duration(hours: 13))));
        }
        continue;
      }
      if (d % 2 == 0) {
        out.add(MetroRide(id: 'seed_ride_${d}_am', fare: MetroFare.weekdayMax,
            amountCents: 675, rideAt: day.add(const Duration(hours: 8))));
        out.add(MetroRide(id: 'seed_ride_${d}_pm', fare: MetroFare.weekdayMax,
            amountCents: 675, rideAt: day.add(const Duration(hours: 17, minutes: 40))));
      } else if (d % 3 == 0) {
        out.add(MetroRide(id: 'seed_ride_${d}_hop', fare: MetroFare.shortHop,
            amountCents: 225, rideAt: day.add(const Duration(hours: 12))));
      }
    }
    return out;
  }
}
