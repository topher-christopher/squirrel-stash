import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/colony_economy.dart';
import '../../providers/clock_provider.dart';
import '../../providers/colony_actions.dart';
import '../../providers/colony_math.dart';
import '../../providers/colony_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/acorn_icons.dart';
import '../widgets/stash_controls.dart';
import 'colony_cards.dart';

/// Hearth status: lit or embers, fuel gauge, time left and active boosts.
class HearthStatusCard extends ConsumerWidget {
  const HearthStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(colonyProvider);
    final now = ref.read(clockProvider)();
    final lit = c.isLit(now);
    final cap = ColonyEconomy.hearthBurnHours[c.hearthLevel - 1];
    return StashCard(
      color: lit ? const Color(0x99431407) : const Color(0x991E1B4B),
      border: (lit ? AppColors.ember : AppColors.sky).withValues(alpha: 0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(lit ? Icons.local_fire_department_rounded : Icons.nightlight_round,
              color: lit ? AppColors.ember : AppColors.frost, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lit ? 'The Hearth is burning' : 'Embers out: the colony is asleep',
                  style: AppType.title(15, color: lit ? const Color(0xFFFDBA74) : AppColors.frostPale)),
              Text(
                  lit
                      ? 'Tree lights, disco, the holiday tree and full worker bustle are on.'
                      : 'The tree has dimmed to cozy twilight. Refuel to wake everyone. Your money is never affected.',
                  style: AppType.body(11.5, color: AppColors.stone, height: 1.3)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: c.fuelFraction(now),
            minHeight: 8,
            backgroundColor: AppColors.stoneDeep,
            color: AppColors.ember,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [
            'Fuel: ${countdown(c.fuelLeft(now))} of ${cap >= 72 ? '3 days' : '${cap}h'}',
            if (c.overdriveOn(now)) 'Overdrive ${countdown(c.overdriveUntil!.difference(now))}',
            if (c.festivalOn(now)) 'Festival ${countdown(c.festivalUntil!.difference(now))}',
          ].join(' · '),
          style: AppType.body(12, weight: FontWeight.w700, color: AppColors.honey),
        ),
      ]),
    );
  }
}

/// +4h / +12h / Fill fuel buttons with live Acorn prices.
class HearthFuelRow extends ConsumerWidget {
  const HearthFuelRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(colonyProvider);
    final acorns = ref.watch(settingsProvider.select((s) => s.acorns));
    final now = ref.read(clockProvider)();
    final actions = ref.read(colonyActionsProvider);
    Widget button(String label, int hours, VoidCallback onTap) {
      final until = ColonyMath.refuel(c, now, hours);
      final cost = until == null ? 0 : ColonyMath.fuelCost(c, now, until);
      final ok = until != null && acorns >= cost;
      return Expanded(
        child: PressScale(
          onTap: until == null ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: ok ? AppColors.ember.withValues(alpha: 0.85) : AppColors.stoneDeep,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Text(label, style: AppType.title(13, color: ok ? AppColors.night : AppColors.stoneDim)),
              if (until == null)
                Text('Full', style: AppType.body(11, color: AppColors.stoneDim))
              else
                AcornAmount(cost, size: 12, style: AppType.number(12, color: ok ? AppColors.night : AppColors.stoneDim)),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        button('+4h', 4, () => actions.fuelHearth(4)),
        const SizedBox(width: 8),
        button('+12h', 12, () => actions.fuelHearth(12)),
        const SizedBox(width: 8),
        button('Fill', c.hearthCapacity.inHours, actions.fillHearth),
      ]),
    );
  }
}

/// Hearth Overdrive: lights stay on for 24h or 48h regardless of fuel.
class OverdriveTiles extends ConsumerWidget {
  const OverdriveTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(colonyProvider);
    final now = ref.read(clockProvider)();
    return Column(children: [
      for (final h in ColonyEconomy.overdriveHours)
        ShopTile(
          title: 'Hearth Overdrive · ${h}h',
          blurb: 'Blazing lights and full bustle for $h hours, no matter the fuel. Stacks.',
          acorns: ColonyEconomy.overdriveAcorns(h),
          status: c.overdriveOn(now) && h == ColonyEconomy.overdriveHours.first
              ? 'Active · ${countdown(c.overdriveUntil!.difference(now))} left'
              : null,
          onTap: () => ref.read(colonyActionsProvider).overdrive(h),
        ),
    ]);
  }
}

/// Permanent Golden Acorn infrastructure and the instant Festival.
class GoldenUpgradeTiles extends ConsumerWidget {
  const GoldenUpgradeTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(colonyProvider);
    final s = ref.watch(settingsProvider);
    final now = ref.read(clockProvider)();
    final actions = ref.read(colonyActionsProvider);
    final granaryMax = s.granaryLevel >= ColonyEconomy.granaryMax;
    final hearthMax = c.hearthLevel >= ColonyEconomy.hearthMax;
    final pedestalsMax = c.extraPedestals >= ColonyEconomy.maxExtraPedestals;
    return Column(children: [
      ShopTile(
        title: 'Granary Storage · Lv.${s.granaryLevel}',
        blurb: granaryMax
            ? 'Holds ${s.granaryCap} Acorns, the biggest Granary in the forest.'
            : 'Raise the cap from ${s.granaryCap} to ${ColonyEconomy.granaryCap(s.granaryLevel + 1)} Acorns so big trophy payouts fit.',
        golden: granaryMax ? 0 : ColonyEconomy.granaryGolden[s.granaryLevel],
        done: granaryMax,
        onTap: actions.upgradeGranary,
      ),
      ShopTile(
        title: 'Hearth Burn Time · Lv.${c.hearthLevel}',
        blurb: hearthMax
            ? 'One fill now burns for 3 full days.'
            : 'One fill burns ${ColonyEconomy.hearthBurnHours[c.hearthLevel - 1]}h now; upgrade to '
                '${ColonyEconomy.hearthBurnHours[c.hearthLevel] >= 72 ? '3 full days' : '${ColonyEconomy.hearthBurnHours[c.hearthLevel]}h'}.',
        golden: hearthMax ? 0 : ColonyEconomy.hearthGolden[c.hearthLevel],
        done: hearthMax,
        onTap: actions.upgradeHearth,
      ),
      ShopTile(
        title: 'Canopy Terrace Pedestal (${c.pedestalCount}/${ColonyEconomy.basePedestals + ColonyEconomy.maxExtraPedestals})',
        blurb: 'Raise another stone Display Pedestal on the terrace for a trophy, statue or trinket.',
        golden: pedestalsMax ? 0 : ColonyEconomy.pedestalGolden[c.extraPedestals],
        done: pedestalsMax,
        onTap: actions.addPedestal,
      ),
      ShopTile(
        title: 'Instant Colony Festival · 24h',
        blurb: 'Confetti over the whole tree, peak disco lighting, the Hearth lit, and rare feeder visitors.',
        golden: ColonyEconomy.festivalGolden,
        status: c.festivalOn(now) ? 'Festival on · ${countdown(c.festivalUntil!.difference(now))} left' : null,
        accent: AppColors.flame,
        onTap: actions.startFestival,
      ),
    ]);
  }
}

class RushHourTile extends ConsumerWidget {
  const RushHourTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(colonyProvider);
    final now = ref.read(clockProvider)();
    return ShopTile(
      title: 'Rush-Hour Worker Flood · ${ColonyEconomy.rushHourHours}h',
      blurb: 'Pack the DC Metro platform with commuters and run the trains faster. Purely for show.',
      acorns: ColonyEconomy.rushHourAcorns,
      status: c.rushHourOn(now) ? 'Rush hour · ${countdown(c.rushHourUntil!.difference(now))} left' : null,
      onTap: ref.read(colonyActionsProvider).rushHour,
    );
  }
}

class SecondSquadTile extends ConsumerWidget {
  const SecondSquadTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(colonyProvider);
    final now = ref.read(clockProvider)();
    return ShopTile(
      title: 'Temporary 2nd Scavenger Squad · 24h',
      blurb: 'Run two seed expeditions at once for a day.',
      acorns: ColonyEconomy.secondSquadAcorns,
      status: c.secondSquadOn(now) ? 'Hired · ${countdown(c.secondSquadUntil!.difference(now))} left' : null,
      onTap: ref.read(colonyActionsProvider).hireSecondSquad,
    );
  }
}

/// Wild canopy acorn collector: bubbles ready and a harvest button.
class CollectorCard extends ConsumerWidget {
  const CollectorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(colonyProvider);
    final now = ref.read(clockProvider)();
    final n = c.bubbles;
    final hours = c.isLit(now) ? ColonyEconomy.collectorLitHours : ColonyEconomy.collectorDarkHours;
    final perBubble = Duration(minutes: hours * 60 ~/ ColonyEconomy.bubbleCount);
    final into = (c.collectorProgress * ColonyEconomy.bubbleCount) % 1;
    final next = Duration(minutes: ((1 - into) * perBubble.inMinutes).round());
    return StashCard(
      child: Row(children: [
        const AcornIcon(size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Wild Acorn Bubbles · $n/${ColonyEconomy.bubbleCount}', style: AppType.body(13.5, weight: FontWeight.w800)),
            Text(
                n >= ColonyEconomy.bubbleCount
                    ? 'The canopy collector is full. Tap the bubbles above the tree!'
                    : 'Fills in ${hours}h (${c.isLit(now) ? 'Hearth lit' : 'Hearth out'}). Next bubble in ${countdown(next)}.',
                style: AppType.body(11, color: AppColors.stoneDim, height: 1.3)),
          ]),
        ),
        if (n > 0)
          PillButton(
            label: '+${n * ColonyEconomy.acornsPerBubble}',
            dense: true,
            onPressed: () => ref.read(colonyActionsProvider).harvestBubbles(),
          ),
      ]),
    );
  }
}
