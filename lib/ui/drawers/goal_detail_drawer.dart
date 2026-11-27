import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../models/goal.dart';
import '../../providers/finance_providers.dart';
import '../../providers/goals_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/stash_controls.dart';
import 'drawer_shell.dart';
import 'prompts.dart';
import 'reclaim_celebration.dart';

/// Goal Chamber detail: allocate acorns, priority, reclaim at 100%.
class GoalDetailDrawer extends ConsumerStatefulWidget {
  const GoalDetailDrawer({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalDetailDrawer> createState() => _GoalDetailDrawerState();
}

class _GoalDetailDrawerState extends ConsumerState<GoalDetailDrawer> {
  /// Last seen goal, so the sheet animates out intact after a reclaim.
  Goal? _last;

  @override
  Widget build(BuildContext context) {
    final watched = ref.watch(goalsProvider.select(
        (goals) => goals.where((g) => g.id == widget.goalId).firstOrNull));
    if (watched != null) _last = watched;
    final goal = _last;
    if (goal == null) return const SizedBox.shrink();
    final free = ref.watch(financeProvider.select((f) => f.freeCashCents));
    final actions = ref.read(stashActionsProvider);
    return DrawerShell(
      emoji: goal.icon,
      title: goal.name,
      subtitle: '${Money.whole(goal.savedCents)} of ${Money.whole(goal.targetCents)} • Due ${Dates.short(goal.dueDate)}, ${goal.dueDate.year}',
      children: [
        StashCard(
          border: (goal.roomLevel == 3 ? AppColors.amberBright : AppColors.amber).withValues(alpha: 0.4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('LV.${goal.roomLevel} ${goal.roomName.toUpperCase()}', style: AppType.label(10.5)),
              const Spacer(),
              Text('${goal.percent}%', style: AppType.number(18, color: AppColors.amberBright)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: goal.progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, p, _) => LinearProgressIndicator(
                  value: p,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF3B2110),
                  valueColor: const AlwaysStoppedAnimation(AppColors.amberBright),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              AnimatedMoney(goal.savedCents, style: AppType.number(16, color: AppColors.honey)),
              const Spacer(),
              Text(goal.isComplete ? 'Ready to reclaim!' : '${Money.whole(goal.remainingCents)} to go',
                  style: AppType.body(12.5, color: goal.isComplete ? AppColors.emeraldBright : AppColors.stone)),
            ]),
          ]),
        ),
        if (goal.note.isNotEmpty) ...[
          const SizedBox(height: 10),
          StashCard(
            color: const Color(0x66451A03),
            child: Text('📜 “${goal.note}”',
                style: AppType.body(13, color: AppColors.cream.withValues(alpha: 0.88), style: FontStyle.italic)),
          ),
        ],
        SectionLabel('Stash acorns from Free Cash',
            trailing: Text('${Money.whole(free)} free', style: AppType.body(12, color: AppColors.emeraldSoft))),
        Row(children: [
          for (final amt in const [5000, 25000, 50000]) ...[
            Expanded(
              child: PillButton(
                label: '+${Money.whole(amt)}',
                color: AppColors.emeraldButton,
                expand: true,
                onPressed: () => actions.allocate(goal.id, amt),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: PillButton(
              label: 'Custom',
              outlined: true,
              color: AppColors.emeraldBright,
              expand: true,
              onPressed: () async {
                final cents = await promptAmount(context, title: 'Stash how much?', confirmLabel: 'Stash',
                    message: 'Up to ${Money.whole(free)} of Free Cash is available.');
                if (cents != null) actions.allocate(goal.id, cents);
              },
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: PillButton(
              label: goal.priority ? '⭐ Priority Active' : '☆ Set Priority',
              color: AppColors.stoneDeep,
              foreground: AppColors.honey,
              expand: true,
              onPressed: () => ref.read(goalsProvider.notifier).togglePriority(goal.id),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PillButton(
              label: 'Return acorns',
              outlined: true,
              color: AppColors.stone,
              expand: true,
              onPressed: goal.savedCents <= 0
                  ? null
                  : () async {
                      final cents = await promptAmount(context, title: 'Return to Free Cash', confirmLabel: 'Return',
                          initialCents: goal.savedCents);
                      if (cents != null) actions.release(goal.id, cents);
                    },
            ),
          ),
        ]),
        if (goal.isComplete) ...[
          const SizedBox(height: 14),
          PillButton(
            label: '🏆 Reclaim & Upgrade!',
            color: AppColors.amberBright,
            expand: true,
            onPressed: () async {
              final nav = Navigator.of(context);
              final trophy = actions.reclaim(goal.id);
              if (trophy == null) return;
              final level = ref.read(financeProvider).oakLevel;
              nav.pop();
              await showReclaimCelebration(nav.context, trophy: trophy, oakLevel: level);
            },
          ),
        ],
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final ok = await confirmAction(context,
                  title: 'Fill in ${goal.name}?',
                  message: 'The chamber is removed and its ${Money.whole(goal.savedCents)} returns to Free Cash.',
                  confirmLabel: 'Fill in', destructive: true);
              if (!ok) return;
              actions.dissolveGoal(goal.id);
              nav.pop();
            },
            child: Text('Fill in this chamber', style: AppType.body(12.5, color: AppColors.alert)),
          ),
        ),
      ],
    );
  }
}
