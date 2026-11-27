import 'dart:ui';

import '../models/room.dart';

/// World coordinates of the unified Great Oak cutaway (600 × 1150 units):
/// sunlit canopy → lively trunk → underground root tunnels. The Flame world
/// and the Flutter icon/plaque overlay share this space.
abstract final class TreeLayout {
  static const double width = 600;
  static const double height = 1150;
  static const Size size = Size(width, height);

  // Bands
  static const double trunkTop = 236;
  static const double groundY = 768;
  static const double canopyBottom = 250;

  /// Bark silhouette: narrower at the crown, flaring at the roots.
  static Path trunkPath() => Path()
    ..moveTo(52, trunkTop)
    ..cubicTo(40, 420, 34, 640, 14, groundY + 6)
    ..lineTo(586, groundY + 6)
    ..cubicTo(566, 640, 560, 420, 548, trunkTop)
    ..close();

  // Central acorn-pulley lift
  static const Offset pulley = Offset(364, 226);
  static const double shaftLeft = 352;
  static const double shaftRight = 376;
  static const double shaftBottom = 924;
  static const double shaftX = 364;

  /// Lift stops (basket floor y) — one per trunk floor plus the Metro.
  static const List<double> liftStops = [404, 568, 732, 922];

  static const Map<RoomKey, Rect> rooms = {
    RoomKey.treasury: Rect.fromLTWH(205, 92, 190, 118),
    RoomKey.outfitter: Rect.fromLTWH(48, 256, 298, 150),
    RoomKey.lab: Rect.fromLTWH(382, 256, 170, 150),
    RoomKey.trophyHall: Rect.fromLTWH(46, 420, 300, 150),
    RoomKey.billVault: Rect.fromLTWH(382, 420, 172, 150),
    RoomKey.kitchen: Rect.fromLTWH(44, 584, 302, 150),
    RoomKey.goals: Rect.fromLTWH(382, 584, 174, 150),
    RoomKey.metro: Rect.fromLTWH(26, 794, 548, 132),
    RoomKey.brokerage: Rect.fromLTWH(30, 948, 126, 92),
    RoomKey.pokemon: Rect.fromLTWH(168, 948, 126, 92),
    RoomKey.crypto: Rect.fromLTWH(306, 948, 126, 92),
    RoomKey.espp: Rect.fromLTWH(444, 948, 126, 92),
    RoomKey.hysa: Rect.fromLTWH(99, 1050, 126, 92),
    RoomKey.retirement: Rect.fromLTWH(237, 1050, 126, 92),
    RoomKey.silver: Rect.fromLTWH(375, 1050, 126, 92),
  };

  static Rect room(RoomKey key) => rooms[key]!;

  /// Display pedestals on the grassy terrace at the trunk's base.
  static const List<Offset> pedestals = [
    Offset(86, 774), Offset(170, 774), Offset(448, 774), Offset(526, 774),
  ];

  // Canopy residents
  static const Offset beacon = Offset(96, 204);
  static const Offset hoot = Offset(510, 166);
  static const Rect hootHotspot = Rect.fromLTWH(488, 140, 44, 40);

  /// Where the camera centers when zoomed to a room (slightly above center
  /// so the drawer doesn't cover it).
  static Offset focusPoint(RoomKey key) => room(key).center;
}
