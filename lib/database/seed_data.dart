import '../models/app_settings.dart';
import '../models/bill.dart';
import '../models/decor.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/holding.dart';
import '../models/impulse.dart';
import '../models/stash_snapshot.dart';
import '../models/trophy.dart';
import '../providers/economy.dart';
import '../providers/feat_engine.dart';
import 'seed_colony.dart';
import 'seed_history.dart';

/// The demo Great Oak (dates relative to install day) plus an empty
/// "start fresh" stash. Both share the built-in habits and bill presets.
abstract final class SeedData {
  static const defaultHabits = <Habit>[
    Habit(id: 'h_water', label: 'Water / Soda Instead of Alcohol', mode: ImpulseMode.diy,
        amountCents: 900, icon: '🥤', entry: HabitEntry.prompt, pinned: true,
        key: HabitKeys.waterSoda, sortOrder: 0),
    Habit(id: 'h_app', label: 'Skipped Restaurant Appetizer', mode: ImpulseMode.skip,
        amountCents: 1200, icon: '🍤', entry: HabitEntry.prompt, pinned: true,
        key: HabitKeys.skipAppetizer, sortOrder: 1),
    Habit(id: 'h_pickup', label: 'Picked Up Instead of Delivery', mode: ImpulseMode.diy,
        amountCents: 600, icon: '🛍️', entry: HabitEntry.both, pinned: true,
        key: HabitKeys.pickup, sortOrder: 2),
    Habit(id: 'h_hop', label: 'Walked / Biked Short-Hop Metro', mode: ImpulseMode.skip,
        amountCents: 225, icon: '🚲', roundTrip: true, pinned: true,
        key: HabitKeys.shortHop, sortOrder: 3),
    Habit(id: 'h_cook', label: 'Cooked at Home', mode: ImpulseMode.diy,
        amountCents: 1200, icon: '🍲', key: HabitKeys.homeCooked, sortOrder: 4),
    Habit(id: 'h_icecream', label: 'Skipped Grocery Ice Cream', mode: ImpulseMode.skip,
        amountCents: 700, icon: '🍨', sortOrder: 5),
    Habit(id: 'h_pokemon', label: 'Walked Past Pokémon Pack', mode: ImpulseMode.skip,
        amountCents: 2500, icon: '🃏', sortOrder: 6),
    Habit(id: 'h_coffee', label: 'Small Coffee Instead of Large', mode: ImpulseMode.downsize,
        amountCents: 250, icon: '☕', sortOrder: 7),
  ];

  /// TD Cash (1st), Quicksilver (9th), Chase Amazon (12th), Chase Southwest
  /// (28th) and a fixed Monthly Rent, each on its next due date.
  static List<Bill> presetBills(DateTime now, {bool withAmounts = true}) {
    Bill card(String id, String name, int day, int dollars, int order) => Bill(
          id: id,
          name: name,
          amountCents: withAmounts ? dollars * 100 : 0,
          dueDate: Bill.nextOccurrence(day, now),
          dueDay: day,
          kind: BillKind.card,
          sortOrder: order,
        );
    return [
      card('b_td', 'TD Cash', 1, 412, 0),
      card('b_qs', 'Capital One Quicksilver', 9, 286, 1),
      card('b_amz', 'Chase Amazon', 12, 198, 2),
      card('b_sw', 'Chase Southwest Rapid Rewards', 28, 534, 3),
      Bill(
        id: 'b_rent',
        name: 'Monthly Rent',
        amountCents: withAmounts ? 165000 : 0,
        dueDate: Bill.nextOccurrence(1, now),
        dueDay: 1,
        kind: BillKind.rent,
        sortOrder: 4,
      ),
    ];
  }

  static StashSnapshot demo(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, 12);
    final bills = presetBills(now);
    final logs = SeedHistory.logs(defaultHabits, now);
    final groceries = SeedHistory.groceries(now);
    final rides = SeedHistory.rides(now);
    final trophies = [
      Trophy(id: 't1', name: 'Emergency Starter Fund', icon: '🛡️', amountCents: 150000,
          reclaimedAt: today.subtract(const Duration(days: 45)),
          note: 'First milestone reclaimed! Unlocked Great Oak Canopy Lanterns.'),
      Trophy(id: 't2', name: 'Noise-Cancelling Headphones', icon: '🎧', amountCents: 32000,
          reclaimedAt: today.subtract(const Duration(days: 160)),
          note: 'Quiet focus for the long study nights.'),
    ];
    final awards = FeatEngine.evaluate(FeatInputs(
      logs: logs, habits: defaultHabits, rides: rides, groceries: groceries,
      awards: const [], focusShifts: 12, goalsReclaimed: trophies.length, now: now,
    ));
    final lifetime = logs.fold<int>(0, (s, l) => s + l.amountCents);
    return StashSnapshot(
      settings: {
        ...AppSettings(
          checkingCents: 760000,
          acorns: 1850,
          goldenAcorns: 6,
          goldenSavingsMilestones: Economy.goldenMilestones(lifetime),
          hearthWarmth: 2,
          focusShiftsCompleted: 12,
          focusMinutesTotal: 340,
        ).toMap(),
        ...SeedColony.settings(now),
        'room_lv_outfitter': '2',
        'room_lv_trophyHall': '3',
        'room_lv_kitchen': '2',
        'room_lv_treasury': '2',
        'room_lv_birdFeeder': '2',
        'pedestals': 'statue:t1,feat:iron_shield,trinket:penny_gong,trinket:card_wall',
      },
      bills: bills,
      statements: SeedHistory.statements(bills, now),
      goals: [
        Goal(id: 'g1', name: 'Japan Trip', icon: '✈️', savedCents: 320000, targetCents: 500000,
            dueDate: today.add(const Duration(days: 140)), priority: true,
            note: 'Skipped takeout all winter so we can get ramen in Tokyo guilt-free!',
            createdAt: today.subtract(const Duration(days: 90))),
        Goal(id: 'g2', name: 'New PC Build', icon: '💻', savedCents: 80000, targetCents: 120000,
            dueDate: today.add(const Duration(days: 29)),
            note: 'For late-night creative projects and cozy gaming.',
            createdAt: today.subtract(const Duration(days: 60))),
      ],
      trophies: trophies,
      habits: defaultHabits,
      logs: logs,
      holdings: _demoHoldings(today),
      decor: const [
        DecorItemState(key: DecorKey.lanternBeacon, enabled: true),
        DecorItemState(key: DecorKey.fairyLights, enabled: true),
        DecorItemState(key: DecorKey.twilightSky),
        DecorItemState(key: DecorKey.seasonalFoliage),
        DecorItemState(key: DecorKey.hats, enabled: true),
      ],
      groceries: groceries,
      rides: rides,
      awards: awards,
      expeditions: SeedColony.expeditions(now),
      seedBags: SeedColony.seedBags,
      birdLog: SeedColony.birdLog(now),
    );
  }

  static List<Holding> _demoHoldings(DateTime at) => [
        Holding(id: 'v_vti', reserve: ReserveKind.brokerage, label: 'Vanguard Total Market',
            valueCents: 1215925, trackingMode: TrackingMode.ticker, ticker: 'VTI',
            quantity: 42.5, costBasisPerUnit: 228.40, lastFetchedPrice: 286.10,
            lastUpdatedAt: at, sortOrder: 0),
        Holding(id: 'v_vxus', reserve: ReserveKind.brokerage, label: 'Vanguard Intl',
            valueCents: 388800, trackingMode: TrackingMode.ticker, ticker: 'VXUS',
            quantity: 60, costBasisPerUnit: 58.20, lastFetchedPrice: 64.80,
            lastUpdatedAt: at, sortOrder: 1),
        const Holding(id: 'v_cash', reserve: ReserveKind.brokerage, label: 'Settlement Cash',
            valueCents: 125000, sortOrder: 2),
        const Holding(id: 'p_zard', reserve: ReserveKind.pokemon, label: 'Charizard PSA 10',
            valueCents: 185000, quantity: 1, costBasisPerUnit: 1200, sortOrder: 3),
        const Holding(id: 'p_box', reserve: ReserveKind.pokemon, label: 'Evolving Skies Booster Box',
            valueCents: 95000, quantity: 1, costBasisPerUnit: 380, sortOrder: 4),
        const Holding(id: 'p_slabs', reserve: ReserveKind.pokemon, label: 'Graded Slab Binder',
            valueCents: 65000, sortOrder: 5),
        Holding(id: 'c_btc', reserve: ReserveKind.crypto, label: 'Bitcoin',
            valueCents: 405300, trackingMode: TrackingMode.ticker, ticker: 'BTC',
            quantity: 0.042, costBasisPerUnit: 61000, lastFetchedPrice: 96500,
            lastUpdatedAt: at, sortOrder: 6),
        Holding(id: 'c_eth', reserve: ReserveKind.crypto, label: 'Ethereum',
            valueCents: 224250, trackingMode: TrackingMode.ticker, ticker: 'ETH',
            quantity: 0.65, costBasisPerUnit: 2400, lastFetchedPrice: 3450,
            lastUpdatedAt: at, sortOrder: 7),
        const Holding(id: 'e_shares', reserve: ReserveKind.espp, label: 'Employer Shares',
            valueCents: 1565980, quantity: 38, costBasisPerUnit: 327.25,
            esppDiscountPercent: 15, esppCashPotCents: 184000, recurringCents: 23000,
            sortOrder: 8),
        const Holding(id: 's_hysa', reserve: ReserveKind.hysa, label: 'High-Yield Savings',
            valueCents: 800000, recurringCents: 25000, sortOrder: 9),
        const Holding(id: 's_ef', reserve: ReserveKind.hysa, label: 'Emergency Fund',
            valueCents: 420000, sortOrder: 10),
        const Holding(id: 'r_roth', reserve: ReserveKind.retirement, label: 'Roth IRA',
            valueCents: 2830000, sortOrder: 11),
        const Holding(id: 'r_401k', reserve: ReserveKind.retirement, label: '401(k)',
            valueCents: 3400000, sortOrder: 12),
        Holding(id: 'ag_bullion', reserve: ReserveKind.silver, label: 'Silver Eagles & Bars',
            valueCents: 163280, trackingMode: TrackingMode.ticker, ticker: 'SI=F',
            quantity: 52, costBasisPerUnit: 24.80, lastFetchedPrice: 31.40,
            lastUpdatedAt: at, sortOrder: 13),
      ];

  /// A clean hollow: zero balances, default habits, the bill presets with
  /// empty amounts, a few starter Acorns and a warm Hearth.
  static StashSnapshot fresh([DateTime? now]) => StashSnapshot(
        settings: {
          ...const AppSettings(acorns: 100).toMap(),
          ...SeedColony.freshSettings(now ?? DateTime.now()),
        },
        bills: presetBills(now ?? DateTime.now(), withAmounts: false),
        habits: defaultHabits,
        decor: [for (final k in DecorKey.values) DecorItemState(key: k)],
      );
}
