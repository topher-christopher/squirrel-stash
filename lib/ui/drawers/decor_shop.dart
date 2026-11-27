import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/decor.dart';
import '../../models/room.dart';
import '../../providers/reserves_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/acorn_icons.dart';
import '../widgets/room_icons.dart';
import '../widgets/stash_controls.dart';
import 'drawer_shell.dart';

/// Two-tier upgrade shop: Acorns raise individual rooms (Starter → Cozy →
/// Max), Acorns + Golden Acorns buy Grand Tree upgrades. Cosmetic only.
class UpgradesDrawer extends ConsumerWidget {
  const UpgradesDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DrawerShell(
        emoji: '🔨',
        title: 'Colony Upgrades',
        subtitle: 'Spend Acorns on rooms and Golden Acorns on the Great Oak itself — purely cosmetic.',
        children: [
          const CurrencyBar(),
          const GrandTreeShop(),
          const SectionLabel('Room Upgrades'),
          for (final room in RoomKey.values) ...[
            RoomUpgradeCard(room: room, compact: true),
            const SizedBox(height: 8),
          ],
        ],
      );
}

/// Current Acorn & Golden Acorn balances.
class CurrencyBar extends ConsumerWidget {
  const CurrencyBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    return StashCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        AcornAmount(s.acorns, size: 20, style: AppType.number(18, color: AppColors.amberBright)),
        const SizedBox(width: 6),
        Text('Acorns', style: AppType.body(12, color: AppColors.stoneDim)),
        const Spacer(),
        AcornAmount(s.goldenAcorns, golden: true, size: 20, style: AppType.number(18, color: AppColors.flame)),
        const SizedBox(width: 6),
        Text('Golden', style: AppType.body(12, color: AppColors.stoneDim)),
      ]),
    );
  }
}

/// Upgrade one room's look with Acorns (shown at the bottom of every room).
class RoomUpgradeCard extends ConsumerWidget {
  const RoomUpgradeCard({super.key, required this.room, this.compact = false});

  final RoomKey room;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(roomsProvider.select((r) => r.levelOf(room)));
    final acorns = ref.watch(settingsProvider.select((s) => s.acorns));
    final maxed = level >= RoomLevels.max;
    final cost = maxed ? 0 : RoomLevels.costFor(level + 1);
    return Padding(
      padding: EdgeInsets.only(top: compact ? 0 : 18),
      child: StashCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: RoomIcons.accent(room).withValues(alpha: 0.3),
        child: Row(children: [
          RoomMedallion(room: room, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(compact ? room.title : 'Room Upgrade', style: AppType.body(13, weight: FontWeight.w800)),
              Row(children: [
                for (var i = 1; i <= RoomLevels.max; i++)
                  Container(
                    width: 16,
                    height: 5,
                    margin: const EdgeInsets.only(right: 3, top: 4),
                    decoration: BoxDecoration(
                      color: i <= level ? AppColors.amberBright : AppColors.stoneDeep,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('Lv.$level ${RoomLevels.name(level)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body(11, color: AppColors.stoneDim)),
                ),
              ]),
            ]),
          ),
          if (maxed)
            Text('Maxed', style: AppType.title(13, color: AppColors.emeraldSoft))
          else
            PressScale(
              onTap: () => ref.read(stashActionsProvider).upgradeRoom(room),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: acorns >= cost ? AppColors.amber.withValues(alpha: 0.85) : AppColors.stoneDeep,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AcornAmount(cost, size: 14,
                    style: AppType.title(13, color: acorns >= cost ? AppColors.night : AppColors.stoneDim)),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Grand Tree upgrades (beacon, fairy lights, twilight, seasonal foliage,
/// colony outfits). Owned upgrades toggle on and off for free.
class GrandTreeShop extends ConsumerWidget {
  const GrandTreeShop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final decor = ref.watch(decorProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionLabel('🌳 Grand Tree Upgrades', color: AppColors.leaf),
      for (final key in DecorKey.values) ...[
        _GrandTile(
          item: decor[key]!,
          affordable: s.acorns >= key.acornCost && s.goldenAcorns >= key.goldenCost,
          onTap: () => ref.read(stashActionsProvider).buyOrToggleDecor(key),
        ),
        const SizedBox(height: 8),
      ],
    ]);
  }
}

class _GrandTile extends StatelessWidget {
  const _GrandTile({required this.item, required this.affordable, required this.onTap});

  final DecorItemState item;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final owned = item.owned;
    final key = item.key;
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: owned ? (item.enabled ? const Color(0x99064E3B) : const Color(0x66064E3B)) : const Color(0xFF1C1917),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: owned
                ? AppColors.emeraldBright.withValues(alpha: item.enabled ? 0.55 : 0.25)
                : AppColors.amber.withValues(alpha: affordable ? 0.45 : 0.18),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(key.label, style: AppType.body(13.5, weight: FontWeight.w800, color: owned ? AppColors.emeraldSoft : AppColors.cream)),
              const SizedBox(height: 2),
              Text(key.blurb, style: AppType.body(11, color: AppColors.stoneDim, height: 1.3)),
            ]),
          ),
          const SizedBox(width: 10),
          if (owned)
            Text(item.enabled ? 'Shown' : 'Hidden',
                style: AppType.body(12, weight: FontWeight.w800, color: AppColors.emeraldSoft))
          else
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              AcornAmount(key.acornCost, size: 13, style: AppType.number(13, color: AppColors.amberBright)),
              if (key.goldenCost > 0)
                AcornAmount(key.goldenCost, golden: true, size: 13, style: AppType.number(13, color: AppColors.flame)),
            ]),
        ]),
      ),
    );
  }
}
