import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_service.dart';
import '../game/diorama_event.dart';
import '../models/room.dart';

/// A celebration toast under the HUD.
class BannerMessage {
  const BannerMessage(this.id, this.text, this.icon);
  final int id;
  final String text;
  final String icon;
}

/// A request for the tree camera to glide to a room (seq makes repeats fire).
class CameraRequest {
  const CameraRequest(this.room, this.seq);
  final RoomKey? room;
  final int seq;
}

/// Ephemeral (non-persisted) UI state.
class UiState {
  const UiState({
    this.blueprint = false,
    this.banner,
    this.labReaction,
    this.labReactionId = 0,
    this.paydayBurst = false,
    this.visitedRooms = const {},
    this.camera = const CameraRequest(null, 0),
  });

  final bool blueprint;
  final BannerMessage? banner;
  final String? labReaction;
  final int labReactionId;
  final bool paydayBurst;

  /// Rooms visited in the swipeable drawer (Window Shopper feat).
  final Set<RoomKey> visitedRooms;
  final CameraRequest camera;

  UiState copyWith({
    bool? blueprint,
    BannerMessage? Function()? banner,
    String? Function()? labReaction,
    int? labReactionId,
    bool? paydayBurst,
    Set<RoomKey>? visitedRooms,
    CameraRequest? camera,
  }) =>
      UiState(
        blueprint: blueprint ?? this.blueprint,
        banner: banner != null ? banner() : this.banner,
        labReaction: labReaction != null ? labReaction() : this.labReaction,
        labReactionId: labReactionId ?? this.labReactionId,
        paydayBurst: paydayBurst ?? this.paydayBurst,
        visitedRooms: visitedRooms ?? this.visitedRooms,
        camera: camera ?? this.camera,
      );
}

final uiProvider = NotifierProvider<UiNotifier, UiState>(UiNotifier.new);

class UiNotifier extends Notifier<UiState> {
  Timer? _bannerTimer;
  Timer? _labTimer;
  Timer? _paydayTimer;
  int _bannerSeq = 0;

  @override
  UiState build() {
    ref.onDispose(() {
      _bannerTimer?.cancel();
      _labTimer?.cancel();
      _paydayTimer?.cancel();
    });
    return const UiState();
  }

  void showBanner(String text, {String icon = '✨'}) {
    final message = BannerMessage(++_bannerSeq, text, icon);
    state = state.copyWith(banner: () => message);
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 4800), dismissBanner);
  }

  void dismissBanner() {
    _bannerTimer?.cancel();
    if (state.banner != null) state = state.copyWith(banner: () => null);
  }

  /// Floating "+$12 Saved!" bubble over the Foraging Lab (2.6s).
  void showLabReaction(String text) {
    state = state.copyWith(labReaction: () => text, labReactionId: state.labReactionId + 1);
    _labTimer?.cancel();
    _labTimer = Timer(const Duration(milliseconds: 2600), () {
      state = state.copyWith(labReaction: () => null);
    });
  }

  /// Multi-squirrel acorn delivery sprint (3.8s).
  void startPaydayBurst() {
    state = state.copyWith(paydayBurst: true);
    _paydayTimer?.cancel();
    _paydayTimer = Timer(const Duration(milliseconds: 3800), () {
      state = state.copyWith(paydayBurst: false);
    });
  }

  void toggleBlueprint() => state = state.copyWith(blueprint: !state.blueprint);

  /// Records a room visit; returns true the first time every room was seen.
  bool visitRoom(RoomKey room) {
    if (state.visitedRooms.contains(room)) return false;
    final next = {...state.visitedRooms, room};
    state = state.copyWith(visitedRooms: next);
    return next.length == RoomKey.values.length;
  }

  void focusCamera(RoomKey? room) =>
      state = state.copyWith(camera: CameraRequest(room, state.camera.seq + 1));
}

/// Broadcast bus for one-shot diorama effects.
class DioramaEventBus {
  final StreamController<DioramaEvent> _controller =
      StreamController<DioramaEvent>.broadcast();

  Stream<DioramaEvent> get stream => _controller.stream;

  void emit(DioramaEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> close() => _controller.close();
}

final dioramaEventsProvider = Provider<DioramaEventBus>((ref) {
  final bus = DioramaEventBus();
  ref.onDispose(bus.close);
  return bus;
});

/// Whether the optional background piano file was bundled.
final ambientPianoAvailableProvider = FutureProvider<bool>((ref) => AmbientPiano.isAvailable());

/// Overridden with [SilentAudioService] in tests.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioPlayersService();
  ref.onDispose(service.dispose);
  return service;
});
