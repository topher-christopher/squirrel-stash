import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:squirrel_stash/core/audio_service.dart';
import 'package:squirrel_stash/core/haptics.dart';
import 'package:squirrel_stash/database/memory_stash_repository.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/models/stash_snapshot.dart';
import 'package:squirrel_stash/providers/repository_providers.dart';
import 'package:squirrel_stash/providers/ui_provider.dart';

/// Shared overrides: in-memory repository, silent audio, haptics off.
class TestHarness {
  TestHarness([StashSnapshot? snapshot])
      : snapshot = snapshot ?? SeedData.demo(DateTime.now()) {
    repository = MemoryStashRepository(this.snapshot);
    Haptics.enabled = false;
  }

  final StashSnapshot snapshot;
  late final MemoryStashRepository repository;

  List<Override> get overrides => [
        stashRepositoryProvider.overrideWithValue(repository),
        initialSnapshotProvider.overrideWithValue(snapshot),
        audioServiceProvider.overrideWithValue(SilentAudioService()),
      ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);
}

/// Demo snapshot with some settings replaced.
StashSnapshot demoWith(Map<String, String> settings, {StashSnapshot? base}) {
  final demo = base ?? SeedData.demo(DateTime.now());
  return StashSnapshot(
    settings: {...demo.settings, ...settings},
    bills: demo.bills,
    goals: demo.goals,
    trophies: demo.trophies,
    chips: demo.chips,
    logs: demo.logs,
    holdings: demo.holdings,
    decor: demo.decor,
  );
}
