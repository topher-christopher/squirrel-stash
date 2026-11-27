import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart' show GameWidget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../game/layout.dart';
import '../../game/stash_diorama_game.dart';
import '../../models/room.dart';
import '../../providers/diorama_snapshot_provider.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../drawers/drawers.dart';
import '../widgets/stash_controls.dart';
import 'blueprint_overlay.dart';
import 'room_hotspots.dart';

/// Hosts the Great Oak (Flame) and its invisible room tap hotspots in one
/// shared 600 × 1150 world inside an [InteractiveViewer]: 1.0x shows the
/// whole tree, pinch up to 2.8x; tapping a room glides the camera to it.
class TreeStage extends ConsumerStatefulWidget {
  const TreeStage({super.key});

  static const minScale = 1.0;
  static const maxScale = 2.8;

  /// Zoom where extra interior animations start fading in (full at 1.3x).
  static const detailStart = 1.12;
  static const detailFull = 1.3;

  @override
  ConsumerState<TreeStage> createState() => _TreeStageState();
}

class _TreeStageState extends ConsumerState<TreeStage> with SingleTickerProviderStateMixin {
  late final StashDioramaGame _game = StashDioramaGame(initial: ref.read(dioramaSnapshotProvider));
  final TransformationController _tc = TransformationController();
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  final ValueNotifier<double> _scale = ValueNotifier(1);
  StreamSubscription<Object?>? _events;
  Animation<Matrix4>? _tween;
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    _events = ref.read(dioramaEventsProvider).stream.listen(_game.handleEvent);
    _tc.addListener(_onTransform);
    _anim.addListener(() {
      final tween = _tween;
      if (tween != null) _tc.value = tween.value;
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    _tc.removeListener(_onTransform);
    _tc.dispose();
    _anim.dispose();
    _scale.dispose();
    super.dispose();
  }

  void _onTransform() {
    final s = _tc.value.getMaxScaleOnAxis();
    _scale.value = s;
    final d = ((s - TreeStage.detailStart) / (TreeStage.detailFull - TreeStage.detailStart)).clamp(0.0, 1.0);
    _game.detail = d;
  }

  double get _fit => math.min(_viewport.width / TreeLayout.width, _viewport.height / TreeLayout.height);

  Offset get _contentOrigin => Offset(
        (_viewport.width - TreeLayout.width * _fit) / 2,
        (_viewport.height - TreeLayout.height * _fit) / 2,
      );

  /// Matrix that shows world point [world] at [screen] with zoom [scale],
  /// clamped so the tree never slides out of view. [liftBottom] lets the
  /// bottom of the tree rise that far above the screen's bottom edge, so
  /// deep rooms can sit above a half-height drawer.
  Matrix4 _matrixFor(Offset world, double scale, Offset screen, {double liftBottom = 0}) {
    final content = _contentOrigin + world * _fit;
    final tx = (screen.dx - content.dx * scale).clamp(_viewport.width * (1 - scale), 0.0);
    final ty = (screen.dy - content.dy * scale).clamp(_viewport.height * (1 - scale) - liftBottom, 0.0);
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(begin: _tc.value.clone(), end: target)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic));
    _anim.forward(from: 0);
  }

  /// Glides to [room]. With a drawer open, the room is parked in the top
  /// part of the screen, above the half-height sheet (lifting the bottom of
  /// the tree if needed so the Metro and vault pockets can get there too).
  void focusRoom(RoomKey room, {bool forDrawer = true}) {
    if (_viewport == Size.zero) return;
    final pocket = room.size == RoomSize.pocket;
    final scale = math.max(_scale.value, pocket ? 2.4 : (room == RoomKey.metro ? 1.6 : 2.0))
        .clamp(TreeStage.minScale, TreeStage.maxScale);
    final screen = Offset(_viewport.width / 2, forDrawer ? _viewport.height * 0.22 : _viewport.height / 2);
    _animateTo(_matrixFor(TreeLayout.focusPoint(room), scale, screen,
        liftBottom: forDrawer ? _viewport.height * 0.55 : 0));
  }

  /// After a drawer closes, eases any lifted view back inside the tree.
  void _settleCamera() {
    final m = _tc.value;
    final s = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    final ty = t.y.clamp(_viewport.height * (1 - s), 0.0);
    if ((ty - t.y).abs() < 0.5) return;
    _animateTo(Matrix4.identity()
      ..translateByDouble(t.x, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1));
  }

  void resetZoom() {
    Haptics.tap();
    _animateTo(Matrix4.identity());
  }

  Future<void> _onRoomTap(RoomKey room) async {
    focusRoom(room);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    await Drawers.room(context, room);
    if (mounted) _settleCamera();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dioramaSnapshotProvider, (_, next) => _game.applySnapshot(next));
    ref.listen(uiProvider.select((u) => u.camera), (_, req) {
      final room = req.room;
      if (room == null) {
        _animateTo(Matrix4.identity());
      } else {
        focusRoom(room);
      }
    });
    return LayoutBuilder(builder: (context, box) {
      _viewport = box.biggest;
      final w = TreeLayout.width * _fit;
      final h = TreeLayout.height * _fit;
      return Stack(children: [
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _tc,
            minScale: TreeStage.minScale,
            maxScale: TreeStage.maxScale,
            onInteractionStart: (_) => _anim.stop(),
            child: SizedBox(
              width: box.maxWidth,
              height: box.maxHeight,
              child: Stack(children: [
                const Positioned.fill(child: _Backdrop()),
                Center(
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: FittedBox(
                      child: SizedBox(
                        width: TreeLayout.width,
                        height: TreeLayout.height,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Positioned.fill(
                            child: RepaintBoundary(child: GameWidget<StashDioramaGame>(game: _game)),
                          ),
                          Positioned.fill(child: RoomHotspots(onRoomTap: _onRoomTap)),
                          const Positioned.fill(child: BlueprintOverlay()),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 14,
          child: ValueListenableBuilder<double>(
            valueListenable: _scale,
            builder: (context, s, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: s > 1.02 ? Center(child: _ResetChip(onTap: resetZoom)) : const SizedBox.shrink(),
            ),
          ),
        ),
      ]);
    });
  }
}

class _ResetChip extends StatelessWidget {
  const _ResetChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xE626170E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.zoom_out_map_rounded, size: 16, color: AppColors.honey),
            const SizedBox(width: 6),
            Text('Reset Zoom', style: AppType.title(13, color: AppColors.honey)),
          ]),
        ),
      );
}

/// Full-bleed sky → horizon → earth behind the tree (fills gutters on wide
/// screens so the world never looks boxed in).
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7DD3FC), Color(0xFFBAE6FD), Color(0xFF86EFAC), Color(0xFF382010), Color(0xFF1E1007)],
            stops: [0, 0.4, 0.66, 0.68, 1],
          ),
        ),
      );
}
