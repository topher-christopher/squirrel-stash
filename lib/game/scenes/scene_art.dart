import 'dart:ui';

import '../art/asset_manifest.dart';
import '../art/palette.dart';
import '../diorama_event.dart';
import '../diorama_snapshot.dart';

/// Per-frame context handed to window scene painters.
class SceneContext {
  SceneContext({
    required this.snap,
    required this.time,
    required this.art,
    required this.poke,
  });

  final DioramaSnapshot snap;
  final double time;
  final StashAssetManifest art;
  final double Function(DioramaTarget target) poke;

  bool get frost => snap.frost;
  bool get twilight => snap.twilight;

  /// Twilight-darkened landscape color.
  Color dusk(Color c, [double amount = 0.55]) =>
      twilight ? Color.lerp(c, Pal.twilightInk, amount)! : c;

  /// Picks the frost variant during the Frostline, then applies dusk.
  Color land(Color normal, Color frosted, [double duskAmount = 0.55]) =>
      dusk(frost ? frosted : normal, duskAmount);
}

/// One swappable panoramic scene outside the study window.
abstract class SceneArt {
  void update(double dt) {}

  /// Draws the landscape and its residents (sky is drawn beforehand).
  void render(Canvas canvas, SceneContext ctx);

  void dispose() {}
}
