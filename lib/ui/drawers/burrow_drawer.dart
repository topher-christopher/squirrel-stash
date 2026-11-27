import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/bird.dart';
import '../../models/expedition.dart';
import '../../models/room.dart';
import '../../providers/clock_provider.dart';
import '../../providers/colony_actions.dart';
import '../../providers/colony_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'colony_cards.dart';
import 'colony_tiles.dart';
import 'drawer_shell.dart';

/// Scavenger Burrow Outpost: send squads on timed seed expeditions. They
/// come home with ready-to-pour bags — no second timer or payment.
class BurrowBody extends ConsumerWidget {
  const BurrowBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expeditions = ref.watch(expeditionsProvider);
    final colony = ref.watch(colonyProvider);
    final bags = ref.watch(seedBagsProvider);
    final now = ref.read(clockProvider)();
    final active = [for (final e in expeditions) if (e.active) e];
    final squads = colony.squads(now);
    final free = squads - active.length;
    return RoomPage(children: [
      StashCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${active.length} of $squads squad${squads == 1 ? '' : 's'} out foraging',
              style: AppType.title(15, color: AppColors.leaf)),
          if (active.isEmpty)
            Text('The squad is resting by the burrow, backpacks on their hooks.',
                style: AppType.body(12, color: AppColors.stoneDim)),
          for (final e in active) _ActiveExpedition(e: e, now: now),
        ]),
      ),
      SectionLabel('Expeditions', trailing: Text(free > 0 ? '$free squad ready' : 'All squads out',
          style: AppType.body(11, color: AppColors.stoneDim))),
      for (final route in ExpeditionRoute.values)
        ShopTile(
          title: '${route.label} · ${route.hours}h',
          blurb: 'Brings home ${route.seed.label}: ${route.seed.attracts}.',
          acorns: route.acorns,
          accent: AppColors.leaf,
          onTap: () => ref.read(colonyActionsProvider).dispatch(route),
        ),
      const SecondSquadTile(),
      const SectionLabel('Seed bags on hand'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final seed in SeedKind.values)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: AppColors.barkDeep, borderRadius: BorderRadius.circular(12)),
            child: Text('${bags[seed] ?? 0} × ${seed.label}', style: AppType.body(12, weight: FontWeight.w700)),
          ),
      ]),
      const SizedBox(height: 6),
      Text('Pour bags into the Canopy Bird Feeder (swipe to it, or tap the feeder in the tree).',
          style: AppType.body(11.5, color: AppColors.stoneDim, height: 1.3)),
      const RoomThemeCard(room: RoomKey.burrow),
    ]);
  }
}

class _ActiveExpedition extends StatelessWidget {
  const _ActiveExpedition({required this.e, required this.now});

  final Expedition e;
  final DateTime now;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(e.route.label, style: AppType.body(13, weight: FontWeight.w800))),
            Text(e.isDone(now) ? 'Heading home…' : '${countdown(e.left(now))} left',
                style: AppType.body(12, weight: FontWeight.w700, color: AppColors.honey)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: e.progress(now),
              minHeight: 6,
              backgroundColor: AppColors.stoneDeep,
              color: AppColors.leaf,
            ),
          ),
        ]),
      );
}
