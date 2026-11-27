import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/layout.dart';
import '../../game/stash_diorama_game.dart';
import '../../providers/diorama_snapshot_provider.dart';
import '../../providers/ui_provider.dart';
import 'blueprint_overlay.dart';
import 'cellar_plaques.dart';
import 'desk_plaques.dart';
import 'window_plaques.dart';

/// Hosts the Flame diorama and the Flutter plaque/hotspot overlay in one
/// shared 440 × 820 world, scaled uniformly to fit any screen.
class DioramaStage extends ConsumerStatefulWidget {
  const DioramaStage({super.key});

  @override
  ConsumerState<DioramaStage> createState() => _DioramaStageState();
}

class _DioramaStageState extends ConsumerState<DioramaStage> {
  late final StashDioramaGame _game =
      StashDioramaGame(initial: ref.read(dioramaSnapshotProvider));
  StreamSubscription<Object?>? _events;

  @override
  void initState() {
    super.initState();
    _events = ref.read(dioramaEventsProvider).stream.listen(_game.handleEvent);
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dioramaSnapshotProvider, (_, next) => _game.applySnapshot(next));
    return Center(
      child: AspectRatio(
        aspectRatio: StudyLayout.width / StudyLayout.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x99783510), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x99000000), blurRadius: 32, offset: Offset(0, 14)),
              BoxShadow(color: Color(0x22F59E0B), blurRadius: 60, spreadRadius: -10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FittedBox(
              child: SizedBox(
                width: StudyLayout.width,
                height: StudyLayout.height,
                child: Stack(children: [
                  Positioned.fill(
                    child: RepaintBoundary(child: GameWidget<StashDioramaGame>(game: _game)),
                  ),
                  const Positioned.fill(child: WindowPlaques()),
                  const Positioned.fill(child: DeskPlaques()),
                  const Positioned.fill(child: CellarPlaques()),
                  const Positioned.fill(child: BlueprintOverlay()),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
