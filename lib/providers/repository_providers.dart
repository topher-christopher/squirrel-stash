import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/memory_stash_repository.dart';
import '../database/stash_repository.dart';
import '../models/stash_snapshot.dart';

/// Overridden in `main()` with the SQLite repository.
final stashRepositoryProvider =
    Provider<StashRepository>((ref) => MemoryStashRepository());

/// Overridden in `main()` with the snapshot loaded at startup.
final initialSnapshotProvider =
    Provider<StashSnapshot>((ref) => const StashSnapshot());

/// The snapshot every domain notifier seeds itself from. Replacing it (reset
/// or demo restore) rebuilds all domain state at once.
final stashSnapshotProvider =
    NotifierProvider<StashSnapshotNotifier, StashSnapshot>(
        StashSnapshotNotifier.new);

class StashSnapshotNotifier extends Notifier<StashSnapshot> {
  @override
  StashSnapshot build() => ref.watch(initialSnapshotProvider);

  Future<void> replace(StashSnapshot snapshot) async {
    await ref.read(stashRepositoryProvider).replaceAll(snapshot);
    state = snapshot;
  }
}

/// Fire-and-forget write-through. Failures are logged, never thrown at the UI.
void persist(Future<void> write) {
  unawaited(write.catchError((Object error, StackTrace stack) {
    debugPrint('SquirrelStash: failed to persist ($error)');
  }));
}
