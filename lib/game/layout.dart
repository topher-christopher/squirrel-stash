import 'dart:ui';

import '../models/room.dart';

/// A quadratic limb curve (start, control, tip).
typedef Limb = (Offset, Offset, Offset);

/// World coordinates of the unified Great Oak cutaway (600 × 1150 units):
/// sunlit canopy & terrace → trunk (3 hero rooms left, 3 compact rooms
/// right) → grass-level Scavenger Burrow → root concourse → DC Metro →
/// vault pockets & the Deep-Root Hearth. The Flame world and the Flutter
/// tap hotspots share this space.
abstract final class TreeLayout {
  static const double width = 600;
  static const double height = 1150;
  static const Size size = Size(width, height);

  // Bands
  static const double trunkTop = 236;
  static const double groundY = 768;
  static const double canopyBottom = 250;

  /// The Canopy Terrace deck the pedestals stand on.
  static const double deckY = 244;

  /// Bark silhouette: narrower at the crown, flaring at the roots.
  static Path trunkPath() => Path()
    ..moveTo(52, trunkTop)
    ..cubicTo(40, 420, 34, 640, 14, groundY + 6)
    ..lineTo(586, groundY + 6)
    ..cubicTo(566, 640, 560, 420, 548, trunkTop)
    ..close();

  // Central acorn-pulley lift (terminates at the root concourse floor).
  static const Offset pulley = Offset(364, 226);
  static const double shaftLeft = 352;
  static const double shaftRight = 376;
  static const double shaftBottom = 806;
  static const double shaftX = 364;

  /// Lift stops (basket floor y): Canopy Terrace, three trunk floors, and
  /// the root concourse. It never drops into the Metro.
  static const List<double> liftStops = [deckY, 404, 568, 732, 802];

  /// Root concourse: the lift landing, the burrow tunnel and the stairs
  /// down to the Metro.
  static const Rect concourse = Rect.fromLTRB(40, 782, 560, 808);

  static const Map<RoomKey, Rect> rooms = {
    RoomKey.treasury: Rect.fromLTWH(205, 92, 190, 118),
    RoomKey.birdFeeder: Rect.fromLTWH(430, 122, 168, 88),
    // Left trunk: three large hero rooms
    RoomKey.outfitter: Rect.fromLTWH(48, 256, 298, 150),
    RoomKey.kitchen: Rect.fromLTWH(46, 420, 300, 150),
    RoomKey.billVault: Rect.fromLTWH(44, 584, 302, 150),
    // Right trunk: three compact rooms
    RoomKey.lab: Rect.fromLTWH(382, 256, 172, 144),
    RoomKey.trophyHall: Rect.fromLTWH(382, 412, 172, 144),
    RoomKey.goals: Rect.fromLTWH(382, 568, 172, 100),
    // Grass-level outpost
    RoomKey.burrow: Rect.fromLTWH(398, 678, 198, 100),
    // Underground
    RoomKey.metro: Rect.fromLTWH(26, 814, 548, 126),
    RoomKey.brokerage: Rect.fromLTWH(30, 952, 126, 92),
    RoomKey.pokemon: Rect.fromLTWH(168, 952, 126, 92),
    RoomKey.crypto: Rect.fromLTWH(306, 952, 126, 92),
    RoomKey.espp: Rect.fromLTWH(444, 952, 126, 92),
    RoomKey.hysa: Rect.fromLTWH(30, 1054, 126, 92),
    RoomKey.retirement: Rect.fromLTWH(168, 1054, 126, 92),
    RoomKey.silver: Rect.fromLTWH(306, 1054, 126, 92),
    RoomKey.hearth: Rect.fromLTWH(444, 1054, 126, 92),
  };

  static Rect room(RoomKey key) => rooms[key]!;

  /// Canopy Terrace pedestal bases in unlock order: four base slots, then
  /// the two Golden Acorn extras on the outside.
  static const List<Offset> pedestals = [
    Offset(140, deckY), Offset(184, deckY), Offset(416, deckY), Offset(460, deckY),
    Offset(96, deckY), Offset(504, deckY),
  ];

  // Canopy limbs (shared by the crown art, residents and visiting birds)
  static const Limb leftLimb = (Offset(205, 196), Offset(130, 168), Offset(4, 136));
  static const Limb rightLimb = (Offset(395, 196), Offset(470, 168), Offset(596, 136));

  static Offset limbAt(Limb limb, double u) {
    final (a, c, b) = limb;
    return a * ((1 - u) * (1 - u)) + c * (2 * (1 - u) * u) + b * (u * u);
  }

  // Left branch: Professor Hoot and the Owl Moonlight Lantern
  static const Offset hoot = Offset(122, 152);
  static const Rect hootHotspot = Rect.fromLTWH(100, 128, 44, 40);
  static const Offset owlLantern = Offset(44, 146);

  /// Open songbird perch hanging under the Owl Lantern.
  static const Offset songPerch = Offset(44, 196);

  // Right branch: birdhouse, wooden landing perch, hanging feeder
  static const Offset birdhouse = Offset(458, 172);
  static const Offset landingPerch = Offset(512, 140);
  static const Offset feederHook = Offset(562, 146);

  /// Seed-bag rope lift running down the outer bark to the burrow.
  static const double ropeX = 593;

  // Wild acorn bubbles above the crown
  static const List<Offset> bubbleSpots = [
    Offset(116, 56), Offset(196, 32), Offset(300, 14), Offset(404, 32), Offset(484, 56),
  ];
  static const Rect bubbleHotspot = Rect.fromLTRB(88, 0, 512, 78);

  /// Where the scavengers pop out of the ground.
  static const Offset burrowHole = Offset(468, 766);

  /// Where the camera centers when zoomed to a room.
  static Offset focusPoint(RoomKey key) => room(key).center;
}
