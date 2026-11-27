import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/bird.dart';
import '../../models/room.dart';
import '../../providers/clock_provider.dart';
import '../../providers/colony_actions.dart';
import '../../providers/colony_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'bird_logbook_view.dart';
import 'colony_cards.dart';
import 'drawer_shell.dart';

/// Canopy Bird Feeder: pour seed bags, set out timed lures and feeder
/// upgrades, see who's perched right now, and browse the Lifetime Bird &
/// Critter Logbook.
class BirdFeederBody extends ConsumerWidget {
  const BirdFeederBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colony = ref.watch(colonyProvider);
    final bags = ref.watch(seedBagsProvider);
    final now = ref.read(clockProvider)();
    final seed = colony.seedIn(now);
    final lure = colony.lureOn(now);
    final perched = colony.perched(now);
    final actions = ref.read(colonyActionsProvider);
    return RoomPage(children: [
      StashCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(seed == null ? 'The feeder is empty' : seed.label,
              style: AppType.title(15, color: seed == null ? AppColors.stoneDim : AppColors.honey)),
          const SizedBox(height: 4),
          if (seed != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: colony.feederFill(now),
                minHeight: 7,
                backgroundColor: AppColors.stoneDeep,
                color: AppColors.amberBright,
              ),
            ),
            const SizedBox(height: 4),
            Text('${countdown(colony.feederUntil!.difference(now))} of seed left · attracts ${seed.attracts}',
                style: AppType.body(11.5, color: AppColors.stoneDim, height: 1.3)),
          ] else
            Text('Send a scavenger squad from the burrow, then pour a bag here.',
                style: AppType.body(12, color: AppColors.stoneDim)),
          if (lure != null) ...[
            const SizedBox(height: 6),
            Text('${lure.label} · ${countdown(colony.lureUntil!.difference(now))} left',
                style: AppType.body(12, weight: FontWeight.w800, color: AppColors.emeraldSoft)),
          ],
        ]),
      ),
      const SectionLabel('Perched right now'),
      if (perched.isEmpty)
        Text(seed == null ? 'No seed, no guests.' : 'Nobody at the moment. They come and go every few minutes.',
            style: AppType.body(12, color: AppColors.stoneDim))
      else
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final b in perched)
            Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
              decoration: BoxDecoration(color: AppColors.barkDeep, borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                BirdPortrait(species: b, size: 26),
                const SizedBox(width: 4),
                Text(b.label, style: AppType.body(12, weight: FontWeight.w700)),
              ]),
            ),
        ]),
      const SectionLabel('Pour a seed bag'),
      for (final s in SeedKind.values)
        ShopTile(
          title: '${s.label} (${bags[s] ?? 0} on hand)',
          blurb: '${s.feederHours}h per bag, up to ${SeedKind.maxBagsInFeeder} bags · ${s.attracts}',
          trailing: PillButton(
            label: 'Pour',
            dense: true,
            onPressed: (bags[s] ?? 0) > 0 ? () => actions.pourSeed(s) : null,
          ),
          onTap: (bags[s] ?? 0) > 0 ? () => actions.pourSeed(s) : null,
        ),
      const SectionLabel('Lures & feeder upgrades'),
      for (final l in LureKind.values)
        ShopTile(
          title: '${l.label} · ${l.durationLabel}',
          blurb: l.blurb,
          acorns: l.acorns,
          status: lure == l ? 'Set out · ${countdown(colony.lureUntil!.difference(now))} left' : null,
          onTap: () => actions.buyLure(l),
        ),
      const SectionLabel('Lifetime Bird & Critter Logbook', color: AppColors.leaf),
      Text('Every species earns its keepsake at ${BirdSpecies.keepsakeVisits} lifetime visits. Counts keep climbing forever.',
          style: AppType.body(11.5, color: AppColors.stoneDim, height: 1.3)),
      const SizedBox(height: 8),
      const BirdLogbookView(),
      const RoomThemeCard(room: RoomKey.birdFeeder),
    ]);
  }
}
