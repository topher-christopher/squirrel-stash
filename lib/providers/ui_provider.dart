import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_service.dart';
import '../game/diorama_event.dart';

/// A celebration toast under the HUD pill.
class BannerMessage {
  const BannerMessage(this.id, this.text, this.icon);
  final int id;
  final String text;
  final String icon;
}

/// Ephemeral (non-persisted) UI state.
class UiState {
  const UiState({
    this.blueprint = false,
    this.goalPage = 0,
    this.banner,
    this.labReaction,
    this.labReactionId = 0,
    this.paydayBurst = false,
  });

  final bool blueprint;
  final int goalPage;
  final BannerMessage? banner;
  final String? labReaction;
  final int labReactionId;
  final bool paydayBurst;

  UiState copyWith({
    bool? blueprint,
    int? goalPage,
    BannerMessage? Function()? banner,
    String? Function()? labReaction,
    int? labReactionId,
    bool? paydayBurst,
  }) =>
      UiState(
        blueprint: blueprint ?? this.blueprint,
        goalPage: goalPage ?? this.goalPage,
        banner: banner != null ? banner() : this.banner,
        labReaction: labReaction != null ? labReaction() : this.labReaction,
        labReactionId: labReactionId ?? this.labReactionId,
        paydayBurst: paydayBurst ?? this.paydayBurst,
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

  /// Floating "+$12 Saved!" bubble above the silo (2.6s).
  void showLabReaction(String text) {
    state = state.copyWith(
      labReaction: () => text,
      labReactionId: state.labReactionId + 1,
    );
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

  void toggleBlueprint() =>
      state = state.copyWith(blueprint: !state.blueprint);

  void setGoalPage(int page) =>
      state = state.copyWith(goalPage: page < 0 ? 0 : page);
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

/// Overridden with [SilentAudioService] in tests.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioPlayersService();
  ref.onDispose(service.dispose);
  return service;
});
