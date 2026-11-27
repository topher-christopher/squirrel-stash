import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/room.dart';
import 'repository_providers.dart';

/// Chosen room themes and what sits on the Canopy Terrace pedestals.
class RoomsState {
  const RoomsState({this.levels = const {}, this.pedestals = const ['', '', '', '', '', '']});

  final Map<RoomKey, int> levels;

  /// Pedestal slots (4 base + up to 2 Golden Acorn extras):
  /// `statue:<trophyId>`, `feat:<key>`, `trinket:<key>` or '' (empty).
  final List<String> pedestals;

  bool get allMax => RoomKey.values.every((r) => levelOf(r) >= RoomLevels.max);
  bool get allStarter => RoomKey.values.every((r) => levelOf(r) <= 1);

  int levelOf(RoomKey room) => levels[room] ?? 1;

  RoomsState copyWith({Map<RoomKey, int>? levels, List<String>? pedestals}) =>
      RoomsState(levels: levels ?? this.levels, pedestals: pedestals ?? this.pedestals);
}

final roomsProvider = NotifierProvider<RoomsNotifier, RoomsState>(RoomsNotifier.new);

/// Stored as `room_lv_<room>` and `pedestals` keys in the settings table.
class RoomsNotifier extends Notifier<RoomsState> {
  /// Slots stored (the Canopy Terrace shows 4 + purchased extras).
  static const pedestalCount = 6;

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

  void setAll(int level) {
    final lv = level.clamp(1, RoomLevels.max);
    state = state.copyWith(levels: {for (final r in RoomKey.values) r: lv});
    final repo = ref.read(stashRepositoryProvider);
    for (final r in RoomKey.values) {
      persist(repo.putSetting('room_lv_${r.name}', '$lv'));
    }
  }

  void setPedestal(int slot, String item) {
    if (slot < 0 || slot >= pedestalCount) return;
    final next = [...state.pedestals]..[slot] = item;
    state = state.copyWith(pedestals: next);
    persist(ref.read(stashRepositoryProvider).putSetting('pedestals', next.join(',')));
  }
}
