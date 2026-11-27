import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/impulse.dart';
import '../../providers/finance_math.dart';
import '../../providers/finance_providers.dart';
import '../../providers/goals_provider.dart';
import '../../providers/impulse_provider.dart';
import '../../providers/willpower_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/acorn_icons.dart';
import '../widgets/stash_controls.dart';
import 'lab_drawer.dart';

/// Smart Downsize Calculator (ordered small instead of large).
class DownsizeCalculator extends ConsumerStatefulWidget {
  const DownsizeCalculator({super.key});

  @override
  ConsumerState<DownsizeCalculator> createState() => _DownsizeCalculatorState();
}

class _DownsizeCalculatorState extends ConsumerState<DownsizeCalculator> {
  final _label = TextEditingController(text: 'Drink / Meal Downsize');
  final _large = TextEditingController(text: '7.00');
  final _small = TextEditingController(text: '4.50');

  int get _diff {
    final l = Money.parse(_large.text) ?? 0;
    final s = Money.parse(_small.text) ?? 0;
    return l - s > 0 ? l - s : 0;
  }

  @override
  void dispose() {
    _label.dispose();
    _large.dispose();
    _small.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StashCard(
        color: const Color(0x66022C22),
        border: AppColors.emerald.withValues(alpha: 0.35),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('🥤 Smart Downsize Calculator', style: AppType.title(14, color: AppColors.emeraldSoft)),
          Text('Ordered small instead of large? Bank the difference.', style: AppType.body(11.5, color: AppColors.stoneDim)),
          const SizedBox(height: 10),
          StashField(controller: _label, hint: 'Item name', onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _priceField('Large', _large)),
            const SizedBox(width: 8),
            Expanded(child: _priceField('Small', _small)),
          ]),
          const SizedBox(height: 10),
          PillButton(
            label: 'Bank Downsize Difference (+${Money.exact(_diff)})',
            color: AppColors.emeraldButton,
            expand: true,
            onPressed: _diff > 0
                ? () => ref.read(willpowerActionsProvider).logWin(
                    _label.text.trim().isEmpty ? 'Smart Downsize' : _label.text, ImpulseMode.downsize, _diff)
                : null,
          ),
        ]),
      );

  Widget _priceField(String label, TextEditingController c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppType.label(9.5, color: AppColors.emeraldSoft)),
          const SizedBox(height: 4),
          StashField(controller: c, money: true, onChanged: (_) => setState(() {})),
        ],
      );
}

/// Silo sand mix + progress to the next Golden Acorn.
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
    final toNext = 10000 - stats.allTimeCents % 10000;
    return StashCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(children: [
        Row(children: [
          swatch(AppColors.sandSkip, 'Skips', stats.skipPct),
          swatch(AppColors.sandDownsize, 'Downsizes', stats.downsizePct),
          swatch(AppColors.sandDiy, 'Swaps', stats.diyPct),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const GoldenAcornIcon(size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text('${Money.smart(toNext)} more willpower forges your next Golden Acorn • 10 Acorns per \$1',
                style: AppType.body(11.5, weight: FontWeight.w800, color: AppColors.amberBright)),
          ),
        ]),
      ]),
    );
  }
}

/// One-tap sweep of this month's unswept savings into a goal chamber.
class SweepSection extends ConsumerWidget {
  const SweepSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    if (goals.isEmpty) return const SizedBox.shrink();
    final unswept = ref.watch(impulseStatsProvider.select((s) => s.unsweptMonthCents));
    final ordered = [...goals.where((g) => g.priority), ...goals.where((g) => !g.priority)];
    return StashCard(
      color: const Color(0x99451A03),
      border: AppColors.amberBright.withValues(alpha: 0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          const TextSpan(text: 'Sweep '),
          TextSpan(text: Money.smart(unswept), style: AppType.body(13.5, weight: FontWeight.w900, color: AppColors.amberBright)),
          const TextSpan(text: ' of this month’s unswept savings into:'),
        ]), style: AppType.body(13.5)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final g in ordered)
            PillButton(
              label: '${g.priority ? '⭐ ' : ''}${g.icon} ${g.name}',
              dense: true,
              onPressed: unswept > 0 ? () => ref.read(willpowerActionsProvider).sweepToGoal(g.id) : null,
            ),
        ]),
      ]),
    );
  }
}

/// The last few logged wins (swipe to undo a mistaken log).
class RecentWins extends ConsumerWidget {
  const RecentWins({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(impulseLogsProvider).take(6).toList();
    if (logs.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel('Recent Wins', trailing: Text('Swipe to undo', style: AppType.body(11, color: AppColors.stoneDim))),
      for (final log in logs)
        Dismissible(
          key: ValueKey(log.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            Haptics.tap();
            ref.read(willpowerActionsProvider).undoLog(log.id);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.undo_rounded, color: AppColors.alert),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: modeColor(log.mode), shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(log.label, style: AppType.body(13), overflow: TextOverflow.ellipsis)),
              Text(Dates.relative(log.loggedAt), style: AppType.body(11.5, color: AppColors.stoneDim)),
              const SizedBox(width: 10),
              Text('+${Money.smart(log.amountCents)}', style: AppType.number(13.5, color: AppColors.emeraldBright)),
            ]),
          ),
        ),
    ]);
  }
}
