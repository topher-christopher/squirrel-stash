import '../models/impulse.dart';

/// Tappable things in the 1-screen study (shared by hotspots and the game).
enum DioramaTarget {
  cashPile,
  campfire,
  hoot,
  silo,
  lantern,
  clock,
  trophies,
  chamberLeft,
  chamberRight,
  amber,
  curio,
  treasury,
}

enum DioramaEventKind {
  /// A tap landed on a diorama object — squash & bounce it.
  poke,

  /// Payday delivery sprint.
  payday,

  /// Willpower win logged (sand sparkles in the silo).
  impulseWin,

  /// Acorns allocated into a chamber (chute drop).
  allocate,

  /// Goal reclaimed (confetti & golden sparkle).
  reclaim,

  /// Professor Hoot gifted leaves.
  hootGift,

  /// Focus Shift finished (golden leaf burst at the clock).
  focusComplete,

  /// Decor bought/toggled (sparkle).
  decor,
}

/// One-shot visual effect request sent from the app to the diorama.
class DioramaEvent {
  const DioramaEvent(this.kind, {this.target, this.mode, this.slot});

  const DioramaEvent.poke(DioramaTarget this.target)
      : kind = DioramaEventKind.poke,
        mode = null,
        slot = null;

  final DioramaEventKind kind;
  final DioramaTarget? target;
  final ImpulseMode? mode;

  /// Visible chamber slot (0 = left, 1 = right) for allocations.
  final int? slot;
}
