import '../models/treat_status.dart';
import '../models/window_scene.dart';

/// Visual state of one visible Goal Chamber slot.
class ChamberArt {
  const ChamberArt({
    required this.level,
    required this.percent,
    required this.priority,
  }) : isDigSlot = false;

  const ChamberArt.dig()
      : level = 0,
        percent = 0,
        priority = false,
        isDigSlot = true;

  /// 1 Dirt Alcove, 2 Timber Chamber, 3 Gold Treasury.
  final int level;
  final int percent;
  final bool priority;
  final bool isDigSlot;
}

/// Everything the Flame diorama needs to draw, pushed from Riverpod.
/// Plain data — the game never reaches back into providers.
class DioramaSnapshot {
  const DioramaSnapshot({
    this.scene = WindowScene.meadow,
    this.frost = false,
    this.twilight = false,
    this.fairyLights = false,
    this.hats = false,
    this.espresso = false,
    this.acornCount = 0,
    this.oakLevel = 1,
    this.focusRunning = false,
    this.focusProgress = 0,
    this.siloFill = 14,
    this.skipFraction = 0,
    this.downsizeFraction = 0,
    this.diyFraction = 1,
    this.treat = TreatLevel.green,
    this.forgedSilver = 0,
    this.forgedGold = 0,
    this.chambers = const [null, null],
    this.hootHasGift = false,
    this.paydayBurst = false,
  });

  final WindowScene scene;
  final bool frost;
  final bool twilight;
  final bool fairyLights;
  final bool hats;
  final bool espresso;

  /// Free Cash Acorn Pile size (0 or 4–15).
  final int acornCount;
  final int oakLevel;
  final bool focusRunning;
  final double focusProgress;

  /// Silo sand height in world units (14–70).
  final double siloFill;
  final double skipFraction;
  final double downsizeFraction;
  final double diyFraction;
  final TreatLevel treat;
  final int forgedSilver;
  final int forgedGold;

  /// Two slots: a goal, the dig slot, or empty (null).
  final List<ChamberArt?> chambers;
  final bool hootHasGift;
  final bool paydayBurst;
}
