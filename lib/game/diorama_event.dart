import '../models/impulse.dart';
import '../models/room.dart';

enum DioramaEventKind {
  /// A tap landed on a room or critter — squash & bounce it.
  poke,

  /// Payday delivery sprint into the Canopy Treasury.
  payday,

  /// Willpower win logged (sand sparkles in the Foraging Lab).
  impulseWin,

  /// Acorns allocated into a Goal Chamber (lift drop).
  allocate,

  /// Goal reclaimed (confetti & a new statue in the Trophy Hall).
  reclaim,

  /// Professor Hoot gifted Acorns.
  hootGift,

  /// Focus Shift finished (golden leaf burst).
  focusComplete,

  /// Room or Grand Tree upgrade bought/toggled (sparkle).
  upgrade,

  /// Metro fare tapped (a train pulls through).
  metroRide,

  /// Grocery trip or home-cooked meal (kitchen steam puff).
  kitchen,

  /// New trophy earned.
  trophy,

  /// Wild acorn bubbles harvested above the canopy.
  harvest,

  /// A scavenger squad popped out of the burrow with a backpack.
  expeditionStart,

  /// A squad sprinted home carrying a seed bag.
  expeditionReturn,

  /// A seed bag was poured into the Canopy Bird Feeder.
  pourSeed,

  /// The Deep-Root Hearth was fueled (or overdriven).
  hearthFuel,

  /// A 24h Colony Festival started.
  festival,

  /// A feeder lure or temporary feeder upgrade was set out.
  lure,
}

/// One-shot visual effect request sent from the app to the Great Oak.
class DioramaEvent {
  const DioramaEvent(this.kind, {this.room, this.mode});

  const DioramaEvent.poke(RoomKey this.room)
      : kind = DioramaEventKind.poke,
        mode = null;

  /// Poke key for critters that are not rooms.
  static const hoot = 'hoot';

  final DioramaEventKind kind;
  final RoomKey? room;
  final ImpulseMode? mode;

  /// Key used by the game's squash-bounce table.
  String? get pokeKey => room?.name;
}
