import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/room.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'colony_cards.dart';
import 'colony_tiles.dart';
import 'drawer_shell.dart';

/// Deep-Root Hearth & Tree-Light Generator: fuel, Overdrive, the Granary,
/// the canopy acorn collector and the Golden Acorn infrastructure.
class HearthBody extends ConsumerWidget {
  const HearthBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => RoomPage(children: [
        const HearthStatusCard(),
        const HearthFuelRow(),
        const SizedBox(height: 6),
        Text('Fuel costs 10 Acorns per hour of burn. When the Hearth runs dry the tree dims to twilight and the colony naps. Nothing is ever lost.',
            style: AppType.body(11.5, color: AppColors.stoneDim, height: 1.35)),
        const SectionLabel('Overdrive'),
        const OverdriveTiles(),
        const SectionLabel('Granary & Wild Acorns'),
        const CurrencyBar(),
        const SizedBox(height: 8),
        const CollectorCard(),
        const SectionLabel('Golden Acorn Infrastructure', color: AppColors.flame),
        const GoldenUpgradeTiles(),
        const RoomThemeCard(room: RoomKey.hearth),
      ]);
}
