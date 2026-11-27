import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../models/goal.dart';
import '../../models/room.dart';
import '../../providers/finance_providers.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/stash_controls.dart';
import 'colony_cards.dart';
import 'drawer_shell.dart';
import 'drawers.dart';

/// Goal Chambers: every savings goal with its chamber level; tap one for
/// allocations and Reclaim & Upgrade, or dig a new chamber.
class GoalsBody extends ConsumerWidget {
  const GoalsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final f = ref.watch(financeProvider);
    final ordered = [...goals.where((g) => g.priority), ...goals.where((g) => !g.priority)];
    return RoomPage(children: [
      Row(children: [
        Expanded(child: StatTile(label: 'In Chambers', color: AppColors.amberBright, value: AnimatedMoney(f.allocatedCents))),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Free Cash', highlight: true, color: AppColors.emeraldBright, value: AnimatedMoney(f.freeCashCents))),
      ]),
      const SizedBox(height: 12),
      if (goals.isEmpty)
        Text('No chambers dug yet. Start one below — it seals at 100% and becomes a statue in the Trophy Hall.',
            style: AppType.body(12.5, color: AppColors.stoneDim, height: 1.35)),
      for (final g in ordered) ...[
        _GoalRow(goal: g, onTap: () => Drawers.goal(context, g.id)),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      PillButton(label: '⛏️ Dig New Goal Chamber', color: AppColors.amberBright, expand: true, onPressed: () => Drawers.newGoal(context)),
      const RoomThemeCard(room: RoomKey.goals),
    ]);
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal, required this.onTap});

  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        scale: 0.98,
        child: StashCard(
          border: (goal.roomLevel == 3 ? AppColors.amberBright : AppColors.amber).withValues(alpha: goal.priority ? 0.6 : 0.3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text(goal.icon, style: const TextStyle(fontSize: 20, fontFamilyFallback: AppType.emojiFallback)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${goal.priority ? '⭐ ' : ''}${goal.name}', style: AppType.title(15, color: AppColors.honey)),
                  Text('Lv.${goal.roomLevel} ${goal.roomName} • Due ${Dates.short(goal.dueDate)}',
                      style: AppType.body(11, color: AppColors.stoneDim)),
                ]),
              ),
              Text('${goal.percent}%', style: AppType.number(16, color: AppColors.amberBright)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF3B2110),
                valueColor: const AlwaysStoppedAnimation(AppColors.amberBright),
              ),
            ),
            const SizedBox(height: 6),
            Text(
                goal.isComplete
                    ? 'Ready to reclaim!'
                    : '${Money.whole(goal.savedCents)} of ${Money.whole(goal.targetCents)} • ${Money.whole(goal.remainingCents)} to go',
                style: AppType.body(11.5, color: goal.isComplete ? AppColors.emeraldBright : AppColors.stone)),
          ]),
        ),
      );
}
