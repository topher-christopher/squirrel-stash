import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/impulse.dart';
import '../../providers/finance_math.dart';
import '../../providers/finance_providers.dart';
import '../../providers/impulse_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/stash_controls.dart';
import 'drawer_shell.dart';
import 'lab_sections.dart';
import 'prompts.dart';

/// Foraging & Alchemy Lab + the Treat-Yourself lantern verdict.
class LabDrawer extends ConsumerWidget {
  const LabDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treat = ref.watch(treatStatusProvider);
    final stats = ref.watch(impulseStatsProvider);
    final chips = ref.watch(impulseChipsProvider);
    final actions = ref.read(stashActionsProvider);
    return DrawerShell(
      emoji: '🧪',
      title: 'Foraging & Alchemy Lab',
      subtitle: 'Log skipped impulses, smart downsizes, and DIY swaps — or check your guilt-free lantern',
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: treat.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: treat.border, width: 1.4),
            boxShadow: [BoxShadow(color: treat.dot.withValues(alpha: 0.25), blurRadius: 18)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: treat.dot, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(treat.label, style: AppType.label(12.5, color: Colors.white, letterSpacing: 1.1)),
            ]),
            const SizedBox(height: 5),
            Text(treat.sublabel, style: AppType.body(13, color: Colors.white.withValues(alpha: 0.92))),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: StatTile(label: 'This Month', color: AppColors.emeraldBright, value: AnimatedMoney(stats.monthCents))),
          const SizedBox(width: 8),
          Expanded(child: StatTile(label: 'This Year', color: AppColors.honey, value: AnimatedMoney(stats.yearCents))),
          const SizedBox(width: 8),
          Expanded(child: StatTile(label: 'All-Time', color: AppColors.cautionSoft, value: AnimatedMoney(stats.allTimeCents))),
        ]),
        const SizedBox(height: 10),
        SiloLegend(stats: stats),
        SectionLabel('1-Tap Willpower Wins',
            trailing: Text('Hold to remove', style: AppType.body(11, color: AppColors.stoneDim))),
        if (chips.isEmpty)
          Text('No chips yet — save one below.', style: AppType.body(12.5, color: AppColors.stoneDim)),
        LayoutBuilder(builder: (context, c) {
          final twoUp = c.maxWidth > 420;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in chips)
                SizedBox(
                  width: twoUp ? (c.maxWidth - 8) / 2 : c.maxWidth,
                  child: _ChipButton(
                    chip: chip,
                    onTap: () => actions.logWin(chip.label, chip.mode, chip.amountCents),
                    onLongPress: () async {
                      Haptics.light();
                      final ok = await confirmAction(context,
                          title: 'Remove chip?', message: '“${chip.label}” will be removed. Logged wins stay.',
                          confirmLabel: 'Remove', destructive: true);
                      if (ok) ref.read(impulseChipsProvider.notifier).remove(chip.id);
                    },
                  ),
                ),
            ],
          );
        }),
        const SizedBox(height: 14),
        const DownsizeCalculator(),
        const SizedBox(height: 12),
        const CustomChipForm(),
        const SizedBox(height: 12),
        const SweepSection(),
        const RecentWins(),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.chip, required this.onTap, required this.onLongPress});

  final ImpulseChip chip;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1917),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: modeColor(chip.mode).withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Text(chip.icon, style: const TextStyle(fontSize: 17, fontFamilyFallback: AppType.emojiFallback)),
            const SizedBox(width: 9),
            Expanded(child: Text(chip.label, style: AppType.body(13, weight: FontWeight.w700))),
            Text('+${Money.smart(chip.amountCents)}', style: AppType.number(14, color: AppColors.emeraldBright)),
          ]),
        ),
      );
}

/// Sand color per impulse mode.
Color modeColor(ImpulseMode mode) => switch (mode) {
      ImpulseMode.skip => AppColors.sandSkip,
      ImpulseMode.downsize => AppColors.sandDownsize,
      ImpulseMode.diy => AppColors.sandDiy,
    };

/// Silo sand mix + forged acorns.
class SiloLegend extends StatelessWidget {
  const SiloLegend({super.key, required this.stats});

  final ImpulseStats stats;

  @override
  Widget build(BuildContext context) {
    Widget swatch(Color c, String label, int pct) => Expanded(
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 5),
            Flexible(child: Text('$label $pct%', style: AppType.body(11.5, color: AppColors.stone), overflow: TextOverflow.ellipsis)),
          ]),
        );
    return StashCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(children: [
        Row(children: [
          swatch(AppColors.sandSkip, 'Skips', stats.skipPct),
          swatch(AppColors.sandDownsize, 'Downsizes', stats.downsizePct),
          swatch(AppColors.sandDiy, 'DIY', stats.diyPct),
        ]),
        const SizedBox(height: 8),
        Text('👑 ${stats.goldAcorns} Royal Gold (\$100)   •   🥈 ${stats.silverAcorns} Silver (\$25) forged',
            style: AppType.body(12, weight: FontWeight.w800, color: AppColors.amberBright)),
      ]),
    );
  }
}
