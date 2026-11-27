import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:squirrel_stash/core/audio_service.dart';
import 'package:squirrel_stash/core/haptics.dart';
import 'package:squirrel_stash/core/market_price_service.dart';
import 'package:squirrel_stash/database/memory_stash_repository.dart';
import 'package:squirrel_stash/database/seed_data.dart';
import 'package:squirrel_stash/models/stash_snapshot.dart';
import 'package:squirrel_stash/providers/clock_provider.dart';
import 'package:squirrel_stash/providers/repository_providers.dart';
import 'package:squirrel_stash/providers/reserves_provider.dart';
import 'package:squirrel_stash/providers/ui_provider.dart';

/// Shared overrides: in-memory repository, silent audio, offline prices,
/// haptics off, and (optionally) a controllable clock.
class TestHarness {
  TestHarness([StashSnapshot? snapshot, this.prices = const {}, this.clock])
      : snapshot = snapshot ?? SeedData.demo(DateTime.now()) {
    repository = MemoryStashRepository(this.snapshot);
    Haptics.enabled = false;
  }

  final StashSnapshot snapshot;
  final Map<String, double> prices;
  final DateTime Function()? clock;
  late final MemoryStashRepository repository;

  List<Override> get overrides => [
        stashRepositoryProvider.overrideWithValue(repository),
        initialSnapshotProvider.overrideWithValue(snapshot),
        audioServiceProvider.overrideWithValue(SilentAudioService()),
        marketPriceServiceProvider.overrideWithValue(OfflineMarketPriceService(prices)),
        if (clock != null) clockProvider.overrideWithValue(clock!),
      ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);
}

/// Demo snapshot with some settings replaced.
StashSnapshot demoWith(Map<String, String> settings, {StashSnapshot? base}) {
  final demo = base ?? SeedData.demo(DateTime.now());
  return demo.copyWith(settings: {...demo.settings, ...settings});
}
