import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../models/bird.dart';
import '../models/colony_economy.dart';
import '../models/colony_state.dart';
import '../models/expedition.dart';
import 'clock_provider.dart';
import 'repository_providers.dart';

final colonyProvider = NotifierProvider<ColonyNotifier, ColonyState>(ColonyNotifier.new);

/// Settings-backed upkeep state (Hearth, boosts, collector, feeder).
class ColonyNotifier extends Notifier<ColonyState> {
  @override
  ColonyState build() {
    final saved = ref.watch(stashSnapshotProvider).settings;
    final state = ColonyState.fromMap(saved);
    if (!saved.containsKey('hearth_fuel_until')) {
      // Upgrading from v1.1: the Hearth starts warm, and the collector
      // starts counting from now.
      final now = ref.read(clockProvider)();
      final gift = state.copyWith(
        hearthFuelUntil: now.add(const Duration(hours: ColonyEconomy.welcomeFuelHours)),
        collectorCheckedAt: now,
      );
      Future.microtask(() => _persistAll(gift));
      return gift;
    }
    return state;
  }

  void _persistAll(ColonyState s) {
    final repo = ref.read(stashRepositoryProvider);
    s.toMap().forEach((k, v) => persist(repo.putSetting(k, v)));
  }

  /// Applies [change] and persists only the keys that changed.
  void update(ColonyState Function(ColonyState current) change) {
    final before = state.toMap();
    final next = change(state);
    state = next;
    final repo = ref.read(stashRepositoryProvider);
    next.toMap().forEach((key, value) {
      if (before[key] != value) persist(repo.putSetting(key, value));
    });
  }
}

final expeditionsProvider =
    NotifierProvider<ExpeditionsNotifier, List<Expedition>>(ExpeditionsNotifier.new);

/// Scavenger Burrow squads, oldest first.
class ExpeditionsNotifier extends Notifier<List<Expedition>> {
  @override
  List<Expedition> build() => ref.watch(stashSnapshotProvider).expeditions.toList()
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  List<Expedition> get active => [for (final e in state) if (e.active) e];

  Expedition dispatch(ExpeditionRoute route, DateTime now) {
    final e = Expedition(
      id: newId('exp'),
      route: route,
      startedAt: now,
      endsAt: now.add(route.duration),
      acorns: route.acorns,
    );
    state = [...state, e];
    persist(ref.read(stashRepositoryProvider).upsertExpedition(e));
    return e;
  }

  /// Marks every finished squad as home; returns the ones that just returned.
  List<Expedition> collectFinished(DateTime now) {
    final done = [for (final e in state) if (e.active && e.isDone(now)) e.collect(now)];
    if (done.isEmpty) return const [];
    final byId = {for (final e in done) e.id: e};
    state = [for (final e in state) byId[e.id] ?? e];
    final repo = ref.read(stashRepositoryProvider);
    for (final e in done) {
      persist(repo.upsertExpedition(e));
    }
    return done;
  }
}

final seedBagsProvider = NotifierProvider<SeedBagsNotifier, Map<SeedKind, int>>(SeedBagsNotifier.new);

/// Ready-to-pour seed bags on hand.
class SeedBagsNotifier extends Notifier<Map<SeedKind, int>> {
  @override
  Map<SeedKind, int> build() => {
        for (final s in SeedKind.values) s: ref.watch(stashSnapshotProvider).seedBags[s] ?? 0,
      };

  int get total => state.values.fold(0, (a, b) => a + b);

  void add(SeedKind seed, int delta) {
    final next = ((state[seed] ?? 0) + delta).clamp(0, 999);
    state = {...state, seed: next};
    persist(ref.read(stashRepositoryProvider).putSeedBags(seed, next));
  }
}

final birdLogProvider =
    NotifierProvider<BirdLogNotifier, Map<BirdSpecies, BirdLogEntry>>(BirdLogNotifier.new);

/// Lifetime Bird & Critter Logbook: visit counts grow forever.
class BirdLogNotifier extends Notifier<Map<BirdSpecies, BirdLogEntry>> {
  @override
  Map<BirdSpecies, BirdLogEntry> build() => {
        for (final e in ref.watch(stashSnapshotProvider).birdLog) e.species: e,
      };

  int get totalVisits => state.values.fold(0, (s, e) => s + e.visits);

  /// Records [visits]; returns species whose keepsake these visits unlocked.
  List<BirdSpecies> record(List<BirdVisit> visits) {
    if (visits.isEmpty) return const [];
    final next = Map.of(state);
    final unlocked = <BirdSpecies>[];
    for (final v in visits) {
      final before = next[v.species];
      final after = before == null ? BirdLogEntry.first(v) : before.withVisit(v);
      if (!(before?.keepsakeUnlocked ?? false) && after.keepsakeUnlocked) unlocked.add(v.species);
      next[v.species] = after;
    }
    state = next;
    final touched = {for (final v in visits) v.species};
    persist(ref.read(stashRepositoryProvider).upsertBirdLog([for (final s in touched) next[s]!]));
    return unlocked;
  }
}
