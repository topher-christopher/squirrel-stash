import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../models/decor.dart';
import '../models/holding.dart';
import 'repository_providers.dart';

final holdingsProvider =
    NotifierProvider<HoldingsNotifier, List<Holding>>(HoldingsNotifier.new);

/// Line items inside the Amber Reserve, Curio Vault and Deep Treasury.
class HoldingsNotifier extends Notifier<List<Holding>> {
  @override
  List<Holding> build() => ref.watch(stashSnapshotProvider).holdings.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void _save(Holding h) =>
      persist(ref.read(stashRepositoryProvider).upsertHolding(h));

  List<Holding> inReserve(ReserveKind kind) =>
      state.where((h) => h.reserve == kind).toList();

  Holding add(ReserveKind reserve, String label, int valueCents) {
    final nextOrder = state.isEmpty
        ? 0
        : state.map((h) => h.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final holding = Holding(
      id: newId('hold'),
      reserve: reserve,
      label: label,
      valueCents: valueCents,
      sortOrder: nextOrder,
    );
    state = [...state, holding];
    _save(holding);
    return holding;
  }

  void upsert(Holding holding) {
    state = [for (final h in state) h.id == holding.id ? holding : h];
    _save(holding);
  }

  /// Quick deposit: tops up the reserve's first holding (or creates one).
  void deposit(ReserveKind reserve, int cents, {required String fallbackLabel}) {
    final first = inReserve(reserve).firstOrNull;
    if (first == null) {
      add(reserve, fallbackLabel, cents);
    } else {
      upsert(first.copyWith(valueCents: first.valueCents + cents));
    }
  }

  void remove(String id) {
    state = [for (final h in state) if (h.id != id) h];
    persist(ref.read(stashRepositoryProvider).deleteHolding(id));
  }
}

final decorProvider =
    NotifierProvider<DecorNotifier, Map<DecorKey, DecorItemState>>(
        DecorNotifier.new);

/// Golden Leaf cosmetic unlocks (ownership + visibility).
class DecorNotifier extends Notifier<Map<DecorKey, DecorItemState>> {
  @override
  Map<DecorKey, DecorItemState> build() {
    final saved = {
      for (final d in ref.watch(stashSnapshotProvider).decor) d.key: d,
    };
    return {
      for (final k in DecorKey.values) k: saved[k] ?? DecorItemState(key: k),
    };
  }

  bool isActive(DecorKey key) => state[key]?.active ?? false;

  void put(DecorItemState item) {
    state = {...state, item.key: item};
    persist(ref.read(stashRepositoryProvider).upsertDecor(item));
  }
}
