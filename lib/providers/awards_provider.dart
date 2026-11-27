import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feat.dart';
import 'repository_providers.dart';

final awardsProvider =
    NotifierProvider<AwardsNotifier, List<FeatAward>>(AwardsNotifier.new);

/// Earned Trophy Hall feats (one row per feat per period).
class AwardsNotifier extends Notifier<List<FeatAward>> {
  @override
  List<FeatAward> build() => ref.watch(stashSnapshotProvider).awards.toList()
    ..sort((a, b) => a.awardedAt.compareTo(b.awardedAt));

  void addAll(List<FeatAward> awards) {
    if (awards.isEmpty) return;
    final have = {for (final a in state) a.uniqueKey};
    final fresh = [for (final a in awards) if (!have.contains(a.uniqueKey)) a];
    if (fresh.isEmpty) return;
    state = [...state, ...fresh];
    persist(ref.read(stashRepositoryProvider).upsertAwards(fresh));
  }

  /// How many times a repeatable/seasonal feat has stacked, or ladder tiers.
  int countOf(String featKey) => state.where((a) => a.featKey == featKey).length;
}
