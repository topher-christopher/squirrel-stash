import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/impulse.dart';
import '../../providers/finance_providers.dart';
import '../../providers/goals_provider.dart';
import '../../providers/impulse_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
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
          Text('Ordered small instead of large? Bank the difference.',
              style: AppType.body(11.5, color: AppColors.stoneDim)),
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
                ? () => ref.read(stashActionsProvider).logWin(
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

/// + Save Custom Temptation Chip (adds the chip and logs it immediately).
class CustomChipForm extends ConsumerStatefulWidget {
  const CustomChipForm({super.key});

  @override
  ConsumerState<CustomChipForm> createState() => _CustomChipFormState();
}

class _CustomChipFormState extends ConsumerState<CustomChipForm> {
  final _label = TextEditingController();
  final _amount = TextEditingController();
  ImpulseMode _mode = ImpulseMode.skip;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = ref
        .read(stashActionsProvider)
        .addChipAndLog(_label.text, _mode, Money.parse(_amount.text) ?? 0);
    if (!ok) {
      Haptics.warn();
      return;
    }
    _label.clear();
    _amount.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) => StashCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('+ Save Custom Temptation Chip', style: AppType.title(14, color: AppColors.honey)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(flex: 3, child: StashField(controller: _label, hint: 'e.g. Skipped Coffee Run')),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: StashField(controller: _amount, money: true, hint: '0')),
          ]),
          const SizedBox(height: 10),
          ChoicePills<ImpulseMode>(
            values: ImpulseMode.values,
            selected: _mode,
            label: (m) => '${m.defaultIcon} ${m.label}',
            onSelected: (m) => setState(() => _mode = m),
            color: modeColor(_mode),
          ),
          const SizedBox(height: 10),
          PillButton(label: 'Add & Log', expand: true, onPressed: _submit),
        ]),
      );
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
              color: AppColors.amber,
              onPressed: unswept > 0 ? () => ref.read(stashActionsProvider).sweepToGoal(g.id) : null,
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
            ref.read(impulseLogsProvider.notifier).remove(log.id);
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
