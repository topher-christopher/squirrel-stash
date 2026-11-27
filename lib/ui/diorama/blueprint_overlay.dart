import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/layout.dart';
import '../../models/room.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_typography.dart';

/// Custom-art blueprint: outlines every room's drop-in slot and prints the
/// PNG name and world box to export at (see assets/images/rooms/).
class BlueprintOverlay extends ConsumerWidget {
  const BlueprintOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(uiProvider.select((u) => u.blueprint));
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: on
            ? Stack(children: [
                for (final room in RoomKey.values) _Slot(room: room, rect: TreeLayout.room(room)),
              ])
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.room, required this.rect});

  final RoomKey room;
  final Rect rect;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: rect,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x2238BDF8),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(4),
          child: Text(
            'rooms/${room.name}.png\n${rect.width.round()}×${rect.height.round()} @ (${rect.left.round()}, ${rect.top.round()})',
            style: AppType.body(8, color: const Color(0xFFE0F2FE), height: 1.2),
          ),
        ),
      );
}
