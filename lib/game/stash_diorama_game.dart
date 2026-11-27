import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../models/impulse.dart';
import 'art/asset_manifest.dart';
import 'art/palette.dart';
import 'components/cellar_critters.dart';
import 'components/cellar_layer.dart';
import 'components/desk_instruments.dart';
import 'components/desk_layer.dart';
import 'components/fairy_lights.dart';
import 'components/fx_layer.dart';
import 'components/goal_chambers.dart';
import 'components/root_reserves.dart';
import 'components/study_wall.dart';
import 'components/window_frame.dart';
import 'components/window_view.dart';
import 'diorama_event.dart';
import 'diorama_snapshot.dart';
import 'layout.dart';

/// The 60fps living diorama: arched window scenes, the carved desk and the
/// cutaway root cellar, all in one 440 × 820 world.
class StashDioramaGame extends FlameGame {
  StashDioramaGame({DioramaSnapshot initial = const DioramaSnapshot()})
      : _snapshot = initial;

  DioramaSnapshot _snapshot;
  DioramaSnapshot get snapshot => _snapshot;

  /// Seconds since the diorama started (drives every idle animation).
  double time = 0;

  /// Custom PNG drop-ins (empty until loaded → procedural art).
  StashAssetManifest art = StashAssetManifest.empty;

  final FxLayer fx = FxLayer();
  final CellarCritters critters = CellarCritters();
  final Map<DioramaTarget, double> _pokes = {};

  @override
  Color backgroundColor() => const Color(0xFF180E08);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    await world.addAll([
      StudyWall(),
      WindowView(),
      WindowFrame(),
      FairyLights(),
      DeskLayer(),
      DeskInstruments(),
      CellarLayer(),
      GoalChambers(),
      RootReserves(),
      critters,
      fx,
    ]);
    unawaited(StashAssetManifest.load().then((loaded) => art = loaded));
  }

  @override
  void update(double dt) {
    // Clamp long frames (resume from background) so nothing teleports.
    final step = math.min(dt, 1 / 20);
    time += step;
    super.update(step);
  }

  void applySnapshot(DioramaSnapshot next) => _snapshot = next;

  /// Damped 0→1→0 wobble for a recently tapped object.
  double pokeAmount(DioramaTarget target) {
    final at = _pokes[target];
    if (at == null) return 0;
    final e = (time - at) / 0.55;
    if (e >= 1) return 0;
    return math.sin(e * math.pi * 2) * (1 - e) * 0.9;
  }

  void handleEvent(DioramaEvent event) {
    switch (event.kind) {
      case DioramaEventKind.poke:
        final target = event.target;
        if (target != null) _pokes[target] = time;
      case DioramaEventKind.payday:
        fx.burst(StudyLayout.cashPile.translate(0, -10),
            count: 18, colors: const [Pal.gold, Pal.acorn, Color(0xFFFFFFFF)]);
      case DioramaEventKind.impulseWin:
        final color = switch (event.mode) {
          ImpulseMode.skip => Pal.sandSkip,
          ImpulseMode.downsize => Pal.sandDownsize,
          _ => Pal.sandDiy,
        };
        _pokes[DioramaTarget.silo] = time;
        fx.burst(StudyLayout.siloTop,
            count: 16, colors: [color, Pal.gold, const Color(0xFFFFFFFF)], speed: 70);
      case DioramaEventKind.allocate:
        critters.dropAcorn(event.slot);
      case DioramaEventKind.reclaim:
        fx.confetti();
        fx.burst(StudyLayout.trophyShelf.translate(0, -16),
            count: 26, colors: const [Pal.gold, Pal.brass, Color(0xFFFFFFFF)], speed: 110);
      case DioramaEventKind.hootGift:
        _pokes[DioramaTarget.hoot] = time;
        fx.leaves(StudyLayout.hoot, count: 14);
      case DioramaEventKind.focusComplete:
        _pokes[DioramaTarget.clock] = time;
        fx.leaves(StudyLayout.clockCenter, count: 22);
      case DioramaEventKind.decor:
        fx.burst(const Offset(220, 120),
            count: 24, colors: const [Pal.gold, Color(0xFF38BDF8), Color(0xFF4ADE80)], speed: 120);
    }
  }
}
