import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/decor.dart';
import '../../models/room.dart';
import '../../providers/reserves_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'colony_cards.dart';
import 'colony_tiles.dart';
import 'drawer_shell.dart';

/// Colony Shop & Granary (opened from the HUD Acorn counters). Acorns pay
/// for upkeep and adventures; Golden Acorns build permanent infrastructure.
/// Every look and room theme is free.
class UpgradesDrawer extends ConsumerWidget {
  const UpgradesDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DrawerShell(
        emoji: '🌰',
        title: 'Colony Shop & Granary',
        subtitle: 'Acorns keep the Hearth lit and the squads foraging. Golden Acorns build for keeps. All looks are free.',
        children: [
          const CurrencyBar(),
          const SizedBox(height: 8),
          const CollectorCard(),
          const SectionLabel('Golden Acorn Infrastructure', color: AppColors.flame),
          const GoldenUpgradeTiles(),
          const SectionLabel('Keep the Hearth burning'),
          const HearthStatusCard(),
          const HearthFuelRow(),
          const SizedBox(height: 8),
          const OverdriveTiles(),
          const SectionLabel('Colony boosts'),
          const RushHourTile(),
          const SecondSquadTile(),
          Text('Seed expeditions live in the Scavenger Burrow; lures and seed bags at the Canopy Bird Feeder.',
              style: AppType.body(11.5, color: AppColors.stoneDim, height: 1.3)),
          const FreeLooks(),
          const SectionLabel('Room Themes'),
          for (final room in RoomKey.values) RoomThemeCard(room: room, compact: true),
        ],
      );
}

/// Grand Tree looks: free toggles (no paywalls since v1.2).
class FreeLooks extends ConsumerWidget {
  const FreeLooks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decor = ref.watch(decorProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionLabel('🌳 Grand Tree Looks (free)', color: AppColors.leaf),
      for (final key in DecorKey.values)
        ShopTile(
          title: key.label,
          blurb: key.blurb,
          accent: AppColors.leaf,
          trailing: Text(decor[key]!.enabled ? 'Shown' : 'Hidden',
              style: AppType.body(12, weight: FontWeight.w800,
                  color: decor[key]!.enabled ? AppColors.emeraldSoft : AppColors.stoneDim)),
          onTap: () => ref.read(stashActionsProvider).toggleDecor(key),
        ),
    ]);
  }
}
