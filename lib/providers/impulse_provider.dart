import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../models/impulse.dart';
import 'repository_providers.dart';

final impulseChipsProvider =
    NotifierProvider<ImpulseChipsNotifier, List<ImpulseChip>>(
        ImpulseChipsNotifier.new);

/// 1-tap temptation chips in the Foraging & Alchemy Lab.
class ImpulseChipsNotifier extends Notifier<List<ImpulseChip>> {
  @override
  List<ImpulseChip> build() =>
      ref.watch(stashSnapshotProvider).chips.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  ImpulseChip add({
    required String label,
    required ImpulseMode mode,
    required int amountCents,
    String? icon,
  }) {
    final nextOrder = state.isEmpty
        ? 0
        : state.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final chip = ImpulseChip(
      id: newId('chip'),
      label: label,
      mode: mode,
      amountCents: amountCents,
      icon: icon ?? mode.defaultIcon,
      sortOrder: nextOrder,
    );
    state = [...state, chip];
    persist(ref.read(stashRepositoryProvider).upsertChip(chip));
    return chip;
  }

  void remove(String id) {
    state = [for (final c in state) if (c.id != id) c];
    persist(ref.read(stashRepositoryProvider).deleteChip(id));
  }
}

final impulseLogsProvider =
    NotifierProvider<ImpulseLogsNotifier, List<ImpulseLog>>(
        ImpulseLogsNotifier.new);

/// Logged willpower wins, newest first.
class ImpulseLogsNotifier extends Notifier<List<ImpulseLog>> {
  @override
  List<ImpulseLog> build() => ref.watch(stashSnapshotProvider).logs.toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  ImpulseLog add({
    required String label,
    required ImpulseMode mode,
    required int amountCents,
  }) {
    final log = ImpulseLog(
      id: newId('log'),
      label: label,
      mode: mode,
      amountCents: amountCents,
      loggedAt: DateTime.now(),
    );
    state = [log, ...state];
    persist(ref.read(stashRepositoryProvider).upsertLogs([log]));
    return log;
  }

  void markSwept(Set<String> ids) {
    if (ids.isEmpty) return;
    final changed = {
      for (final l in state)
        if (ids.contains(l.id)) l.id: l.copyWith(swept: true),
    };
    state = [for (final l in state) changed[l.id] ?? l];
    persist(ref.read(stashRepositoryProvider).upsertLogs(changed.values.toList()));
  }

  void remove(String id) {
    state = [for (final l in state) if (l.id != id) l];
    persist(ref.read(stashRepositoryProvider).deleteLog(id));
  }
}
