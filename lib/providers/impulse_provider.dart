import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../models/habit.dart';
import '../models/impulse.dart';
import 'repository_providers.dart';

final habitsProvider =
    NotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

/// Editable, pinnable willpower habits in the Foraging & Willpower Lab.
class HabitsNotifier extends Notifier<List<Habit>> {
  @override
  List<Habit> build() => ref.watch(stashSnapshotProvider).habits.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void _save(Habit h) => persist(ref.read(stashRepositoryProvider).upsertHabit(h));

  Habit? byId(String? id) => id == null ? null : state.where((h) => h.id == id).firstOrNull;

  Habit? byKey(String key) => state.where((h) => h.key == key).firstOrNull;

  List<Habit> get pinned => state.where((h) => h.pinned).toList();

  Habit add({
    required String label,
    required ImpulseMode mode,
    required int amountCents,
    String? icon,
    HabitEntry entry = HabitEntry.fixed,
    bool roundTrip = false,
  }) {
    final nextOrder = state.isEmpty
        ? 0
        : state.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final habit = Habit(
      id: newId('habit'),
      label: label,
      mode: mode,
      amountCents: amountCents,
      icon: icon ?? mode.defaultIcon,
      entry: entry,
      roundTrip: roundTrip,
      sortOrder: nextOrder,
    );
    state = [...state, habit];
    _save(habit);
    return habit;
  }

  void upsert(Habit habit) {
    state = [for (final h in state) h.id == habit.id ? habit : h];
    _save(habit);
  }

  /// Pins up to [Habit.maxPinned]; returns false when the bar is full.
  bool togglePin(String id) {
    final habit = byId(id);
    if (habit == null) return false;
    if (!habit.pinned && pinned.length >= Habit.maxPinned) return false;
    upsert(habit.copyWith(pinned: !habit.pinned));
    return true;
  }

  void remove(String id) {
    state = [for (final h in state) if (h.id != id) h];
    persist(ref.read(stashRepositoryProvider).deleteHabit(id));
  }
}

final impulseLogsProvider =
    NotifierProvider<ImpulseLogsNotifier, List<ImpulseLog>>(ImpulseLogsNotifier.new);

/// Logged willpower wins, newest first.
class ImpulseLogsNotifier extends Notifier<List<ImpulseLog>> {
  @override
  List<ImpulseLog> build() => ref.watch(stashSnapshotProvider).logs.toList()
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

  ImpulseLog add({
    required String label,
    required ImpulseMode mode,
    required int amountCents,
    String? habitId,
    DateTime? at,
  }) {
    final log = ImpulseLog(
      id: newId('log'),
      label: label,
      mode: mode,
      amountCents: amountCents,
      loggedAt: at ?? DateTime.now(),
      habitId: habitId,
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

  ImpulseLog? remove(String id) {
    final log = state.where((l) => l.id == id).firstOrNull;
    state = [for (final l in state) if (l.id != id) l];
    persist(ref.read(stashRepositoryProvider).deleteLog(id));
    return log;
  }
}
