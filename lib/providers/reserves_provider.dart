import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../core/market_price_service.dart';
import '../models/decor.dart';
import '../models/holding.dart';
import 'repository_providers.dart';

/// Live prices on device; the web dev preview stays offline (browser CORS
/// blocks Yahoo), and tests override this with fixed prices.
final marketPriceServiceProvider = Provider<MarketPriceService>(
    (ref) => kIsWeb ? const OfflineMarketPriceService() : HttpMarketPriceService());

final holdingsProvider =
    NotifierProvider<HoldingsNotifier, List<Holding>>(HoldingsNotifier.new);

/// Outcome of a price refresh (for the toast).
class PriceRefresh {
  const PriceRefresh(this.updated, this.failed);
  final int updated;
  final int failed;
}

/// Line items inside the seven deep-root vault pockets.
class HoldingsNotifier extends Notifier<List<Holding>> {
  @override
  List<Holding> build() => ref.watch(stashSnapshotProvider).holdings.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void _save(List<Holding> items) =>
      persist(ref.read(stashRepositoryProvider).upsertHoldings(items));

  List<Holding> inReserve(ReserveKind kind) =>
      state.where((h) => h.reserve == kind).toList();

  int get _nextOrder => state.isEmpty
      ? 0
      : state.map((h) => h.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

  Holding add(Holding draft) {
    final holding = Holding(
      id: newId('hold'),
      reserve: draft.reserve,
      label: draft.label,
      valueCents: draft.valueCents,
      sortOrder: _nextOrder,
      trackingMode: draft.trackingMode,
      ticker: draft.ticker,
      quantity: draft.quantity,
      costBasisPerUnit: draft.costBasisPerUnit,
      lastFetchedPrice: draft.lastFetchedPrice,
      lastUpdatedAt: draft.lastUpdatedAt,
      apyPercent: draft.apyPercent,
      esppDiscountPercent: draft.esppDiscountPercent,
      esppCashPotCents: draft.esppCashPotCents,
      recurringCents: draft.recurringCents,
    );
    state = [...state, holding];
    _save([holding]);
    return holding;
  }

  void upsert(Holding holding) {
    state = [for (final h in state) h.id == holding.id ? holding : h];
    _save([holding]);
  }

  /// Quick deposit: tops up the pocket's first manual holding (or creates one).
  void deposit(ReserveKind reserve, int cents, {required String fallbackLabel}) {
    final first = inReserve(reserve).where((h) => !h.isTicker).firstOrNull;
    if (first == null) {
      add(Holding(id: '', reserve: reserve, label: fallbackLabel, valueCents: cents));
    } else {
      upsert(first.copyWith(valueCents: first.valueCents + cents));
    }
  }

  void remove(String id) {
    state = [for (final h in state) if (h.id != id) h];
    persist(ref.read(stashRepositoryProvider).deleteHolding(id));
  }

  /// Pulls live prices for every ticker holding (optionally one pocket) and
  /// caches them. Holdings whose fetch fails keep their last cached price.
  Future<PriceRefresh> refreshPrices({ReserveKind? only}) async {
    final targets = state
        .where((h) => h.isTicker && (h.ticker ?? '').trim().isNotEmpty)
        .where((h) => only == null || h.reserve == only)
        .toList();
    if (targets.isEmpty) return const PriceRefresh(0, 0);
    final crypto = [for (final h in targets) if (h.reserve == ReserveKind.crypto) h.ticker!];
    final quotes = [for (final h in targets) if (h.reserve != ReserveKind.crypto) h.ticker!];
    final prices = await ref
        .read(marketPriceServiceProvider)
        .fetchPrices(quoteSymbols: quotes, cryptoSymbols: crypto);
    if (!ref.mounted) return const PriceRefresh(0, 0);
    final now = DateTime.now();
    final changed = <Holding>[];
    for (final h in targets) {
      final price = prices[h.ticker];
      if (price == null) continue;
      final next = h.copyWith(lastFetchedPrice: () => price, lastUpdatedAt: () => now);
      changed.add(next.copyWith(valueCents: next.currentValueCents));
    }
    if (changed.isNotEmpty) {
      final byId = {for (final h in changed) h.id: h};
      state = [for (final h in state) byId[h.id] ?? h];
      _save(changed);
    }
    return PriceRefresh(changed.length, targets.length - changed.length);
  }
}

final decorProvider =
    NotifierProvider<DecorNotifier, Map<DecorKey, DecorItemState>>(DecorNotifier.new);

/// Grand Tree upgrades (ownership + visibility).
class DecorNotifier extends Notifier<Map<DecorKey, DecorItemState>> {
  @override
  Map<DecorKey, DecorItemState> build() {
    final saved = {for (final d in ref.watch(stashSnapshotProvider).decor) d.key: d};
    return {for (final k in DecorKey.values) k: saved[k] ?? DecorItemState(key: k)};
  }

  bool isActive(DecorKey key) => state[key]?.active ?? false;

  void put(DecorItemState item) {
    state = {...state, item.key: item};
    persist(ref.read(stashRepositoryProvider).upsertDecor(item));
  }
}
