import '../models/app_settings.dart';
import '../models/bill.dart';
import '../models/decor.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/stash_snapshot.dart';
import '../models/trophy.dart';

/// Demo hollow from GEMINI_PROTOTYPE.txt (dates relative to install day),
/// plus an empty "start fresh" stash.
abstract final class SeedData {
  static const defaultChips = <ImpulseChip>[
    ImpulseChip(
        id: 'c1',
        label: 'Cooked Dinner vs. 3 Tacos',
        mode: ImpulseMode.diy,
        amountCents: 1200,
        icon: '🌮',
        sortOrder: 0),
    ImpulseChip(
        id: 'c2',
        label: 'Skipped Grocery Ice Cream',
        mode: ImpulseMode.skip,
        amountCents: 700,
        icon: '🍨',
        sortOrder: 1),
    ImpulseChip(
        id: 'c3',
        label: 'Walked Past Pokémon Pack',
        mode: ImpulseMode.skip,
        amountCents: 2500,
        icon: '🃏',
        sortOrder: 2),
    ImpulseChip(
        id: 'c4',
        label: 'Small Coffee Instead of Large',
        mode: ImpulseMode.downsize,
        amountCents: 250,
        icon: '☕',
        sortOrder: 3),
  ];

  static StashSnapshot demo(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, 12);
    final monthStart = DateTime(now.year, now.month, 1, 9);
    DateTime inMonth(int daysAgo) {
      final d = today.subtract(Duration(days: daysAgo));
      return d.isBefore(monthStart) ? monthStart : d;
    }

    final earlierThisYear = now.month > 1
        ? DateTime(now.year, now.month - 1, 10)
        : DateTime(now.year, 1, 1, 8);

    return StashSnapshot(
      settings: const AppSettings(
        checkingCents: 605000,
        goldenLeaves: 45,
        hearthWarmth: 2,
      ).toMap(),
      bills: [
        Bill(id: 'b1', name: 'Apartment Rent', amountCents: 145000,
            dueDate: today.add(const Duration(days: 5)), sortOrder: 0),
        Bill(id: 'b2', name: 'Utilities & Fiber', amountCents: 18500,
            dueDate: today.add(const Duration(days: 8)), sortOrder: 1),
        Bill(id: 'b3', name: 'Auto Insurance', amountCents: 21500,
            dueDate: today.add(const Duration(days: 14)), sortOrder: 2),
        Bill(id: 'b4', name: 'Annual Holiday Travel Flight',
            amountCents: 260000,
            dueDate: today.add(const Duration(days: 19)),
            paid: true, sortOrder: 3),
      ],
      goals: [
        Goal(
          id: 'g1',
          name: 'Japan Trip',
          icon: '✈️',
          savedCents: 320000,
          targetCents: 500000,
          dueDate: today.add(const Duration(days: 140)),
          priority: true,
          note: 'Skipped takeout all winter so we can get ramen in Tokyo '
              'guilt-free!',
          createdAt: today.subtract(const Duration(days: 90)),
        ),
        Goal(
          id: 'g2',
          name: 'New PC Build',
          icon: '💻',
          savedCents: 80000,
          targetCents: 120000,
          dueDate: today.add(const Duration(days: 29)),
          note: 'For late-night creative projects and cozy gaming.',
          createdAt: today.subtract(const Duration(days: 60)),
        ),
      ],
      trophies: [
        Trophy(
          id: 't1',
          name: 'Emergency Starter Fund',
          icon: '🛡️',
          amountCents: 150000,
          reclaimedAt: today.subtract(const Duration(days: 45)),
          note: 'First milestone reclaimed! Unlocked Great Oak Canopy '
              'Lanterns.',
        ),
      ],
      chips: defaultChips,
      logs: [
        ImpulseLog(id: 'l1', label: 'Cooked Dinner vs. 3 Tacos',
            mode: ImpulseMode.diy, amountCents: 1200, loggedAt: today),
        ImpulseLog(id: 'l2', label: 'Walked Past Pokémon Pack',
            mode: ImpulseMode.skip, amountCents: 2500, loggedAt: inMonth(3)),
        ImpulseLog(id: 'l3', label: 'Small Coffee Instead of Large',
            mode: ImpulseMode.downsize, amountCents: 250,
            loggedAt: inMonth(5)),
        ImpulseLog(id: 'l4', label: 'Skipped Grocery Ice Cream',
            mode: ImpulseMode.skip, amountCents: 700, loggedAt: inMonth(7)),
        ImpulseLog(id: 'l5', label: 'Earlier Autumn Willpower Wins',
            mode: ImpulseMode.diy, amountCents: 59350,
            loggedAt: earlierThisYear, swept: true),
        ImpulseLog(id: 'l6', label: 'Summer Stash Foundation',
            mode: ImpulseMode.skip, amountCents: 128000,
            loggedAt: DateTime(now.year - 1, 7, 15), swept: true),
      ],
      holdings: const [
        Holding(id: 'h1', reserve: ReserveKind.amber,
            label: 'Index Fund Brokerage', valueCents: 1650000, sortOrder: 0),
        Holding(id: 'h2', reserve: ReserveKind.amber,
            label: 'High-Yield Savings', valueCents: 800000, sortOrder: 1),
        Holding(id: 'h3', reserve: ReserveKind.curio,
            label: 'Graded Pokémon Slabs', valueCents: 345000, sortOrder: 2),
        Holding(id: 'h4', reserve: ReserveKind.curio,
            label: 'Silver Bullion', valueCents: 165000, sortOrder: 3),
        Holding(id: 'h5', reserve: ReserveKind.treasury,
            label: 'Roth IRA', valueCents: 2830000, sortOrder: 4),
        Holding(id: 'h6', reserve: ReserveKind.treasury,
            label: '401(k)', valueCents: 3400000, sortOrder: 5),
      ],
      decor: const [
        DecorItemState(key: DecorKey.fairyLights, owned: true, enabled: true),
        DecorItemState(key: DecorKey.twilightSky),
        DecorItemState(key: DecorKey.hats, owned: true, enabled: true),
        DecorItemState(key: DecorKey.espressoBar),
      ],
    );
  }

  /// A clean hollow: zero balances, default chips, a few starter leaves.
  static StashSnapshot fresh() => StashSnapshot(
        settings: const AppSettings(goldenLeaves: 10).toMap(),
        chips: defaultChips,
        decor: [for (final k in DecorKey.values) DecorItemState(key: k)],
      );
}
