import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/room.dart';
import 'awards_provider.dart';
import 'finance_providers.dart';
import 'goals_provider.dart';
import 'settings_provider.dart';

/// The headline number shown in a room's drawer header once it's tapped.
class RoomSummary {
  const RoomSummary({this.cents, this.text, this.acorns});

  /// Primary dollar total (null when the room's headline isn't money).
  final int? cents;
  final String? text;

  /// Acorn balance for the Outfitter.
  final int? acorns;
}

final roomSummaryProvider = Provider.family<RoomSummary, RoomKey>((ref, room) {
  switch (room) {
    case RoomKey.treasury:
      return RoomSummary(cents: ref.watch(financeProvider.select((f) => f.freeCashCents)), text: 'free');
    case RoomKey.outfitter:
      return RoomSummary(acorns: ref.watch(settingsProvider.select((s) => s.acorns)));
    case RoomKey.lab:
      return RoomSummary(cents: ref.watch(impulseStatsProvider.select((s) => s.monthCents)), text: 'saved this month');
    case RoomKey.trophyHall:
      final feats = ref.watch(awardCountProvider);
      final statues = ref.watch(trophiesProvider).length;
      ref.watch(awardsProvider);
      return RoomSummary(text: '${feats + statues} trophies');
    case RoomKey.billVault:
      return RoomSummary(cents: ref.watch(financeProvider.select((f) => f.upcomingBillsCents)), text: 'unpaid');
    case RoomKey.kitchen:
      return RoomSummary(cents: ref.watch(groceryStatsProvider.select((g) => g.monthCents)), text: 'groceries this month');
    case RoomKey.goals:
      return RoomSummary(cents: ref.watch(financeProvider.select((f) => f.allocatedCents)), text: 'in goals');
    case RoomKey.metro:
      return RoomSummary(cents: ref.watch(metroStatsProvider.select((m) => m.monthCents)), text: 'transit this month');
    default:
      final kind = room.reserve!;
      return RoomSummary(cents: ref.watch(financeProvider.select((f) => f.reserveCents(kind))));
  }
});
