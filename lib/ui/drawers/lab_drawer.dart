import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/habit.dart';
import '../../models/impulse.dart';
import '../../models/room.dart';
import '../../providers/finance_providers.dart';
import '../../providers/impulse_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/stash_controls.dart';
import 'decor_shop.dart';
import 'drawer_shell.dart';
import 'habit_editor.dart';
import 'lab_sections.dart';
import 'prompts.dart';

enum _LabTab { wins, downsize, habits }

/// Foraging & Willpower Lab: pinned habit summary bar, then tabs for 1-tap
/// wins, the Smart Downsize Calculator and habit management.
class LabBody extends ConsumerStatefulWidget {
  const LabBody({super.key});

  @override
  ConsumerState<LabBody> createState() => _LabBodyState();
}

class _LabBodyState extends ConsumerState<LabBody> {
  _LabTab _tab = _LabTab.wins;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(impulseStatsProvider);
    return RoomPage(children: [
      const PinnedHabitsBar(),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.barkDeep, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (final t in _LabTab.values)
            Expanded(
              child: PressScale(
                onTap: () {
                  Haptics.tap();
                  setState(() => _tab = t);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t == _tab ? AppColors.emerald.withValues(alpha: 0.28) : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: t == _tab ? AppColors.emeraldBright : Colors.transparent),
                  ),
                  child: Text(
                    switch (t) {
                      _LabTab.wins => '1-Tap Wins',
                      _LabTab.downsize => 'Smart Downsize',
                      _LabTab.habits => 'Habits',
                    },
                    maxLines: 1,
                    style: AppType.body(12.5, weight: FontWeight.w800, color: t == _tab ? AppColors.cream : AppColors.stone),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      ...switch (_tab) {
        _LabTab.wins => [
            const HabitButtons(),
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
            const SizedBox(height: 12),
            const SweepSection(),
            const RecentWins(),
          ],
        _LabTab.downsize => [const DownsizeCalculator()],
        _LabTab.habits => [const HabitManager()],
      },
      const RoomUpgradeCard(room: RoomKey.lab),
    ]);
  }
}

/// Up to four pinned habits with this month's count and dollars; tap to log.
class PinnedHabitsBar extends ConsumerWidget {
  const PinnedHabitsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(habitsProvider).where((h) => h.pinned).toList();
    final logs = ref.watch(impulseLogsProvider);
    final now = DateTime.now();
    if (pinned.isEmpty) {
      return Text('Pin up to ${Habit.maxPinned} favorite habits from the Habits tab.',
          style: AppType.body(12, color: AppColors.stoneDim));
    }
    return Row(children: [
      for (var i = 0; i < pinned.length; i++) ...[
        Expanded(
          child: Builder(builder: (context) {
            final h = pinned[i];
            final month = logs.where((l) => l.habitId == h.id && Dates.sameMonth(l.loggedAt, now));
            final cents = month.fold<int>(0, (s, l) => s + l.amountCents);
            return PressScale(
              onTap: () => logHabitFlow(context, ref, h),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                decoration: BoxDecoration(
                  color: modeColor(h.mode).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: modeColor(h.mode).withValues(alpha: 0.45)),
                ),
                child: Column(children: [
                  Text(h.icon, style: const TextStyle(fontSize: 18, fontFamilyFallback: AppType.emojiFallback)),
                  const SizedBox(height: 3),
                  Text('${month.length}×', style: AppType.number(14, color: AppColors.cream)),
                  FittedBox(child: Text(Money.smart(cents), style: AppType.number(11.5, color: AppColors.emeraldBright))),
                ]),
              ),
            );
          }),
        ),
        if (i < pinned.length - 1) const SizedBox(width: 6),
      ],
    ]);
  }
}

/// Every habit as a tappable win button.
class HabitButtons extends ConsumerWidget {
  const HabitButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    if (habits.isEmpty) {
      return Text('No habits yet — add one in the Habits tab.', style: AppType.body(12.5, color: AppColors.stoneDim));
    }
    return LayoutBuilder(builder: (context, c) {
      final twoUp = c.maxWidth > 420;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final h in habits)
          SizedBox(
            width: twoUp ? (c.maxWidth - 8) / 2 : c.maxWidth,
            child: PressScale(
              onTap: () => logHabitFlow(context, ref, h),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1917),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: modeColor(h.mode).withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Text(h.icon, style: const TextStyle(fontSize: 17, fontFamilyFallback: AppType.emojiFallback)),
                  const SizedBox(width: 9),
                  Expanded(child: Text(h.label, style: AppType.body(13, weight: FontWeight.w700))),
                  Text(_hint(h), style: AppType.number(13, color: AppColors.emeraldBright)),
                ]),
              ),
            ),
          ),
      ]);
    });
  }

  static String _hint(Habit h) => switch (h.entry) {
        HabitEntry.prompt => '\$ ?',
        HabitEntry.both => '+${Money.smart(h.amountCents)} / \$?',
        HabitEntry.fixed => h.roundTrip ? '+${Money.smart(h.amountCents)} ×2' : '+${Money.smart(h.amountCents)}',
      };
}

/// Edit, pin, reorder-free delete, and add habits.
class HabitManager extends ConsumerWidget {
  const HabitManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final notifier = ref.read(habitsProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Pin up to ${Habit.maxPinned} favorites to the summary bar. Edits never change past wins.',
          style: AppType.body(12, color: AppColors.stoneDim, height: 1.35)),
      const SizedBox(height: 10),
      for (final h in habits)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StashCard(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(children: [
              Text(h.icon, style: const TextStyle(fontSize: 18, fontFamilyFallback: AppType.emojiFallback)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.label, style: AppType.body(13, weight: FontWeight.w800)),
                  Text('${h.mode.label} • ${HabitButtons._hint(h)}', style: AppType.body(11, color: AppColors.stoneDim)),
                ]),
              ),
              IconButton(
                tooltip: h.pinned ? 'Unpin' : 'Pin',
                icon: Icon(h.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: h.pinned ? AppColors.amberBright : AppColors.stoneDim, size: 20),
                onPressed: () {
                  if (!notifier.togglePin(h.id)) {
                    Haptics.warn();
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(content: Text('Only 4 habits fit on the pinned bar — unpin one first.')));
                  } else {
                    Haptics.tap();
                  }
                },
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_rounded, color: AppColors.honey, size: 20),
                onPressed: () => editHabit(context, ref, h),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.alert, size: 20),
                onPressed: () async {
                  final ok = await confirmAction(context,
                      title: 'Delete “${h.label}”?', message: 'The habit is removed. Wins you already logged stay in your stats.',
                      confirmLabel: 'Delete', destructive: true);
                  if (ok) notifier.remove(h.id);
                },
              ),
            ]),
          ),
        ),
      PillButton(label: '+ New Habit', expand: true, onPressed: () => editHabit(context, ref)),
    ]);
  }
}

/// Sand color per impulse kind.
Color modeColor(ImpulseMode mode) => switch (mode) {
      ImpulseMode.skip => AppColors.sandSkip,
      ImpulseMode.downsize => AppColors.sandDownsize,
      ImpulseMode.diy => AppColors.sandDiy,
    };
