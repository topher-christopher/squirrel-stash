import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/room.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/acorn_icons.dart';
import '../widgets/room_icons.dart';
import '../widgets/stash_controls.dart';

/// "2d 4h", "7h 20m" or "12m".
String countdown(Duration d) {
  if (d.inMinutes <= 0) return 'now';
  if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m';
}

/// Acorns (with the Granary cap and anything waiting outside it) and
/// Golden Acorns.
class CurrencyBar extends ConsumerWidget {
  const CurrencyBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final fill = (s.acorns / s.granaryCap).clamp(0.0, 1.0);
    return StashCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AcornAmount(s.acorns, size: 20, style: AppType.number(18, color: AppColors.amberBright)),
          const SizedBox(width: 6),
          Text('/ ${s.granaryCap} in the Granary', style: AppType.body(12, color: AppColors.stoneDim)),
          const Spacer(),
          AcornAmount(s.goldenAcorns, golden: true, size: 20, style: AppType.number(18, color: AppColors.flame)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 6,
            backgroundColor: AppColors.stoneDeep,
            color: fill >= 1 ? AppColors.ember : AppColors.amberBright,
          ),
        ),
        if (s.acornsOverflow > 0) ...[
          const SizedBox(height: 6),
          Text('+${s.acornsOverflow} Acorns waiting outside the full Granary. They roll in as soon as there is room.',
              style: AppType.body(11.5, color: AppColors.honey, height: 1.3)),
        ],
      ]),
    );
  }
}

/// Acorn and/or Golden Acorn price tag.
class CostTag extends StatelessWidget {
  const CostTag({super.key, this.acorns = 0, this.golden = 0, this.affordable = true});

  final int acorns;
  final int golden;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final dim = affordable ? null : AppColors.stoneDim;
    return Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
      if (acorns > 0) AcornAmount(acorns, size: 13, style: AppType.number(13, color: dim ?? AppColors.amberBright)),
      if (golden > 0) AcornAmount(golden, golden: true, size: 13, style: AppType.number(13, color: dim ?? AppColors.flame)),
    ]);
  }
}

/// A tappable purchase / action row used across the colony drawers.
class ShopTile extends ConsumerWidget {
  const ShopTile({
    super.key,
    required this.title,
    required this.blurb,
    required this.onTap,
    this.acorns = 0,
    this.golden = 0,
    this.status,
    this.trailing,
    this.done = false,
    this.accent = AppColors.amber,
  });

  final String title;
  final String blurb;
  final VoidCallback? onTap;
  final int acorns;
  final int golden;

  /// e.g. "Active · 6h 12m left" (shown in green).
  final String? status;
  final Widget? trailing;

  /// Maxed out / not purchasable any more.
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final affordable = s.acorns >= acorns && s.goldenAcorns >= golden;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressScale(
        onTap: done ? null : onTap,
        scale: 0.98,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: status != null ? const Color(0x99064E3B) : const Color(0xFF1C1917),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: status != null
                    ? AppColors.emeraldBright.withValues(alpha: 0.45)
                    : accent.withValues(alpha: affordable && !done ? 0.45 : 0.16)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppType.body(13.5, weight: FontWeight.w800, color: AppColors.cream)),
                const SizedBox(height: 2),
                Text(blurb, style: AppType.body(11, color: AppColors.stoneDim, height: 1.3)),
                if (status != null) ...[
                  const SizedBox(height: 3),
                  Text(status!, style: AppType.body(11.5, weight: FontWeight.w800, color: AppColors.emeraldSoft)),
                ],
              ]),
            ),
            const SizedBox(width: 10),
            trailing ??
                (done
                    ? Text('Maxed', style: AppType.title(13, color: AppColors.emeraldSoft))
                    : CostTag(acorns: acorns, golden: golden, affordable: affordable)),
          ]),
        ),
      ),
    );
  }
}

/// Free room theme picker (Starter / Cozy / Max) at the bottom of each room.
class RoomThemeCard extends ConsumerWidget {
  const RoomThemeCard({super.key, required this.room, this.compact = false});

  final RoomKey room;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(roomsProvider.select((r) => r.levelOf(room)));
    return Padding(
      padding: EdgeInsets.only(top: compact ? 0 : 18, bottom: compact ? 8 : 0),
      child: StashCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: RoomIcons.accent(room).withValues(alpha: 0.3),
        child: Row(children: [
          RoomMedallion(room: room, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(compact ? room.title : 'Room Theme', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppType.body(13, weight: FontWeight.w800)),
              Text('Free to switch any time', style: AppType.body(10.5, color: AppColors.stoneDim)),
            ]),
          ),
          for (var lv = 1; lv <= RoomLevels.max; lv++)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: PressScale(
                onTap: () => ref.read(stashActionsProvider).setRoomTheme(room, lv),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: lv == level ? AppColors.amber.withValues(alpha: 0.85) : AppColors.stoneDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(RoomLevels.name(lv),
                      style: AppType.title(11.5, color: lv == level ? AppColors.night : AppColors.honey)),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
