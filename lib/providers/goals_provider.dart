import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ids.dart';
import '../models/goal.dart';
import '../models/trophy.dart';
import 'repository_providers.dart';

final goalsProvider =
    NotifierProvider<GoalsNotifier, List<Goal>>(GoalsNotifier.new);

/// Goal Chambers, in excavation order (first chamber = default sweep target).
class GoalsNotifier extends Notifier<List<Goal>> {
  @override
  List<Goal> build() => ref.watch(stashSnapshotProvider).goals.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  void _save(Goal goal) =>
      persist(ref.read(stashRepositoryProvider).upsertGoal(goal));

  Goal? byId(String id) => state.where((g) => g.id == id).firstOrNull;

  Goal add({
    required String name,
    required String icon,
    required int targetCents,
    required DateTime dueDate,
    bool priority = false,
    String note = '',
  }) {
    final goal = Goal(
      id: newId('goal'),
      name: name,
      icon: icon,
      targetCents: targetCents,
      dueDate: dueDate,
      priority: priority,
      note: note,
      createdAt: DateTime.now(),
    );
    state = [...state, goal];
    _save(goal);
    return goal;
  }

  void upsert(Goal goal) {
    final exists = state.any((g) => g.id == goal.id);
    state = exists
        ? [for (final g in state) g.id == goal.id ? goal : g]
        : [...state, goal];
    _save(goal);
  }

  void addSaved(String id, int cents) {
    final goal = byId(id);
    if (goal == null || cents == 0) return;
    final next = goal.savedCents + cents;
    upsert(goal.copyWith(savedCents: next < 0 ? 0 : next));
  }

  void togglePriority(String id) {
    final goal = byId(id);
    if (goal != null) upsert(goal.copyWith(priority: !goal.priority));
  }

  void remove(String id) {
    state = [for (final g in state) if (g.id != id) g];
    persist(ref.read(stashRepositoryProvider).deleteGoal(id));
  }
}

final trophiesProvider =
    NotifierProvider<TrophiesNotifier, List<Trophy>>(TrophiesNotifier.new);

/// Reclaimed relics, newest first.
class TrophiesNotifier extends Notifier<List<Trophy>> {
  @override
  List<Trophy> build() => ref.watch(stashSnapshotProvider).trophies.toList()
    ..sort((a, b) => b.reclaimedAt.compareTo(a.reclaimedAt));

  void add(Trophy trophy) {
    state = [trophy, ...state];
    persist(ref.read(stashRepositoryProvider).upsertTrophy(trophy));
  }
}
