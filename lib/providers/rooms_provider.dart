import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/room.dart';
import 'repository_providers.dart';

/// Purchased room levels and what sits on the Display Pedestals.
class RoomsState {
  const RoomsState({this.levels = const {}, this.pedestals = const ['', '', '', '']});

  final Map<RoomKey, int> levels;

  /// Four pedestal slots: `statue:<trophyId>`, `feat:<key>`,
  /// `trinket:<key>` or '' (empty).
  final List<String> pedestals;

  int levelOf(RoomKey room) => levels[room] ?? 1;

  RoomsState copyWith({Map<RoomKey, int>? levels, List<String>? pedestals}) =>
      RoomsState(levels: levels ?? this.levels, pedestals: pedestals ?? this.pedestals);
}

final roomsProvider = NotifierProvider<RoomsNotifier, RoomsState>(RoomsNotifier.new);

/// Stored as `room_lv_<room>` and `pedestals` keys in the settings table.
class RoomsNotifier extends Notifier<RoomsState> {
  static const pedestalCount = 4;

  @override
  RoomsState build() {
    final s = ref.watch(stashSnapshotProvider).settings;
    final levels = <RoomKey, int>{};
    for (final room in RoomKey.values) {
      final lv = int.tryParse(s['room_lv_${room.name}'] ?? '');
      if (lv != null) levels[room] = lv.clamp(1, RoomLevels.max);
    }
    final raw = (s['pedestals'] ?? '').split(',');
    return RoomsState(
      levels: levels,
      pedestals: [for (var i = 0; i < pedestalCount; i++) i < raw.length ? raw[i].trim() : ''],
    );
  }

  void setLevel(RoomKey room, int level) {
    final lv = level.clamp(1, RoomLevels.max);
    state = state.copyWith(levels: {...state.levels, room: lv});
    persist(ref.read(stashRepositoryProvider).putSetting('room_lv_${room.name}', '$lv'));
  }

  void setPedestal(int slot, String item) {
    if (slot < 0 || slot >= pedestalCount) return;
    final next = [...state.pedestals]..[slot] = item;
    state = state.copyWith(pedestals: next);
    persist(ref.read(stashRepositoryProvider).putSetting('pedestals', next.join(',')));
  }
}
