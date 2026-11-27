import 'dart:ui';

/// World coordinates of the 1-Screen Hollow Oak Study (440 × 820 units,
/// identical to the blueprint's viewBox). The Flame world and the Flutter
/// plaque/hotspot overlay share this space.
abstract final class StudyLayout {
  static const double width = 440;
  static const double height = 820;
  static const Size size = Size(width, height);

  // Bands
  static const double wallBottom = 390;
  static const double deskTop = 376;
  static const double deskFront = 418;
  static const double cellarTop = 512;

  // Arched window
  static const Rect windowRect = Rect.fromLTRB(38, 20, 402, 380);
  static const double archSpring = 155;

  static Path archPath() => Path()
    ..moveTo(38, 380)
    ..lineTo(38, archSpring)
    ..arcToPoint(const Offset(402, archSpring),
        radius: const Radius.elliptical(182, 135))
    ..lineTo(402, 380)
    ..close();

  // Window anchors
  static const Offset cashPile = Offset(212, 356);
  static const Offset campfire = Offset(332, 356);
  static const Offset hoot = Offset(105, 174);

  // Desk instrument origins (top-left of each instrument group)
  static const Offset silo = Offset(22, 326);
  static const Offset lantern = Offset(136, 336);
  static const Offset clock = Offset(242, 336);
  static const Offset trophies = Offset(342, 344);

  static const Offset siloTop = Offset(49, 334);
  static const Offset lanternCenter = Offset(182, 392);
  static const Offset clockCenter = Offset(286, 388);
  static const Offset trophyShelf = Offset(381, 408);

  // Root cellar
  static const Rect chute = Rect.fromLTWH(208, 512, 24, 156);
  static const List<Rect> chambers = [
    Rect.fromLTWH(16, 540, 186, 112),
    Rect.fromLTWH(238, 540, 186, 112),
  ];
  static const List<Rect> reserves = [
    Rect.fromLTWH(16, 686, 130, 118),
    Rect.fromLTWH(155, 686, 130, 118),
    Rect.fromLTWH(294, 686, 130, 118),
  ];
  static const double patrolY = 776;

  /// Chest position inside a chamber rect.
  static Offset chestIn(Rect chamber) =>
      Offset(chamber.left + 30, chamber.top + 78);

  // Tap regions (hotspots) in world space
  static const Rect cashHotspot = Rect.fromLTWH(158, 314, 108, 54);
  static const Rect campfireHotspot = Rect.fromLTWH(284, 316, 96, 52);
  static const Rect hootHotspot = Rect.fromLTWH(90, 158, 30, 32);
  static const Rect siloHotspot = Rect.fromLTWH(16, 318, 114, 175);
  static const Rect lanternHotspot = Rect.fromLTWH(132, 328, 102, 164);
  static const Rect clockHotspot = Rect.fromLTWH(238, 328, 96, 164);
  static const Rect trophyHotspot = Rect.fromLTWH(338, 336, 84, 156);
}
