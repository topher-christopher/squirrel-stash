import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/layout.dart';
import '../../models/room.dart';
import '../../providers/colony_actions.dart';
import '../../providers/colony_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/acorn_icons.dart';
import 'tap_zone.dart';

/// Invisible tap regions in tree-world coordinates. The tree itself carries
/// no icons or floating labels — each room's name is carved into its wood
/// (game art), and its name + total appear in the drawer once tapped.
/// Cozy Zen disables taps so the tree is pure ambience.
class RoomHotspots extends ConsumerWidget {
  const RoomHotspots({super.key, required this.onRoomTap});

  final void Function(RoomKey room) onRoomTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zen = ref.watch(settingsProvider.select((s) => s.zenMode));
    final bubbles = ref.watch(colonyProvider.select((c) => c.bubbles));
    return ZenFade(
      zen: zen,
      child: Stack(clipBehavior: Clip.none, children: [
        for (final room in RoomKey.values)
          Positioned.fromRect(
            rect: TreeLayout.room(room),
            child: TapZone(label: room.title, room: room, onTap: () => onRoomTap(room)),
          ),
        if (bubbles > 0)
          Positioned.fromRect(
            rect: TreeLayout.bubbleHotspot,
            child: TapZone(
              label: 'Harvest wild acorns',
              onTap: () => ref.read(colonyActionsProvider).harvestBubbles(),
            ),
          ),
        Positioned.fromRect(
          rect: TreeLayout.hootHotspot,
          child: TapZone(
            label: 'Professor Hoot',
            onTap: () => ref.read(stashActionsProvider).greetHoot(),
          ),
        ),
        const _LabReaction(),
      ]),
    );
  }
}

/// "+$12 Saved! +120" bubble floating up over the Foraging Lab.
class _LabReaction extends ConsumerWidget {
  const _LabReaction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(uiProvider.select((u) => u.labReaction));
    final id = ref.watch(uiProvider.select((u) => u.labReactionId));
    final r = TreeLayout.room(RoomKey.lab);
    if (text == null) return const SizedBox.shrink();
    return Positioned(
      left: r.left - 20,
      width: r.width + 40,
      top: r.top - 10,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(id),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2400),
          builder: (context, v, child) => Opacity(
            opacity: v < 0.75 ? 1 : (1 - (v - 0.75) / 0.25),
            child: Transform.translate(offset: Offset(0, -30 * v), child: child),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xF2064E3B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.emeraldBright),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(text, style: AppType.title(12, color: AppColors.emeraldBright)),
                const SizedBox(width: 3),
                const AcornIcon(size: 12),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
