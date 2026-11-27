import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/habit.dart';
import '../../models/impulse.dart';
import '../../providers/impulse_provider.dart';
import '../../providers/willpower_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'prompts.dart';

/// Logs [habit] the way it wants to be logged: 1-tap, custom amount,
/// default-or-custom, or with a round-trip toggle.
Future<void> logHabitFlow(BuildContext context, WidgetRef ref, Habit habit) async {
  final actions = ref.read(willpowerActionsProvider);
  if (habit.roundTrip) {
    final round = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${habit.icon} ${habit.label}'),
        content: Text('Walked or biked instead of riding?', style: AppType.body(14, color: AppColors.stone)),
        actions: [
          PillButton(label: 'One way +${Money.smart(habit.amountCents)}', dense: true, outlined: true,
              onPressed: () => Navigator.of(c).pop(false)),
          PillButton(label: 'Round trip +${Money.smart(habit.amountCents * 2)}', dense: true,
              onPressed: () => Navigator.of(c).pop(true)),
        ],
      ),
    );
    if (round != null) actions.logHabit(habit, roundTrip: round);
    return;
  }
  switch (habit.entry) {
    case HabitEntry.fixed:
      actions.logHabit(habit);
    case HabitEntry.prompt:
      final cents = await promptAmount(context,
          title: habit.label, message: 'How much did you save this time?', initialCents: habit.amountCents, confirmLabel: 'Log win');
      if (cents != null && cents > 0) actions.logHabit(habit, cents: cents);
    case HabitEntry.both:
      final choice = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('${habit.icon} ${habit.label}'),
          content: Text('Log the usual fee & tip savings, or enter the exact difference.',
              style: AppType.body(14, color: AppColors.stone)),
          actions: [
            PillButton(label: 'Custom…', dense: true, outlined: true, onPressed: () => Navigator.of(c).pop('custom')),
            PillButton(label: '1-tap +${Money.smart(habit.amountCents)}', dense: true, onPressed: () => Navigator.of(c).pop('default')),
          ],
        ),
      );
      if (choice == 'default') actions.logHabit(habit);
      if (choice == 'custom' && context.mounted) {
        final cents = await promptAmount(context, title: 'Delivery vs. pickup difference', confirmLabel: 'Log win');
        if (cents != null && cents > 0) actions.logHabit(habit, cents: cents);
      }
  }
}

/// Create or edit a habit (label, icon, amount, kind, entry style).
Future<void> editHabit(BuildContext context, WidgetRef ref, [Habit? existing]) async {
  final result = await showDialog<Habit>(context: context, builder: (_) => _HabitDialog(existing: existing));
  if (result == null) return;
  final habits = ref.read(habitsProvider.notifier);
  if (existing == null) {
    habits.add(label: result.label, mode: result.mode, amountCents: result.amountCents, icon: result.icon,
        entry: result.entry, roundTrip: result.roundTrip);
  } else {
    habits.upsert(result);
  }
  Haptics.success();
}

class _HabitDialog extends StatefulWidget {
  const _HabitDialog({this.existing});
  final Habit? existing;

  @override
  State<_HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<_HabitDialog> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late final _icon = TextEditingController(text: widget.existing?.icon ?? '✨');
  late final _amount = TextEditingController(
      text: widget.existing == null ? '' : Money.plain(widget.existing!.amountCents));
  late ImpulseMode _mode = widget.existing?.mode ?? ImpulseMode.skip;
  late HabitEntry _entry = widget.existing?.entry ?? HabitEntry.fixed;
  late bool _roundTrip = widget.existing?.roundTrip ?? false;

  @override
  void dispose() {
    _label.dispose();
    _icon.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final cents = Money.parse(_amount.text);
    if (_label.text.trim().isEmpty || cents == null || cents <= 0) {
      Haptics.warn();
      return;
    }
    final icon = _icon.text.trim().isEmpty ? _mode.defaultIcon : _icon.text.trim();
    final base = widget.existing ??
        Habit(id: '', label: '', mode: _mode, amountCents: cents, icon: icon);
    Navigator.of(context).pop(base.copyWith(
        label: _label.text.trim(), mode: _mode, amountCents: cents, icon: icon, entry: _entry, roundTrip: _roundTrip));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.existing == null ? 'New willpower habit' : 'Edit habit'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              SizedBox(width: 64, child: StashField(controller: _icon, textAlign: TextAlign.center)),
              const SizedBox(width: 8),
              Expanded(child: StashField(controller: _label, hint: 'e.g. Skipped dessert', autofocus: widget.existing == null)),
            ]),
            const SizedBox(height: 8),
            StashField(controller: _amount, money: true, hint: 'Default amount'),
            const SizedBox(height: 10),
            Text('KIND', style: AppType.label(9.5)),
            const SizedBox(height: 6),
            ChoicePills<ImpulseMode>(
              values: ImpulseMode.values,
              selected: _mode,
              label: (m) => m.label,
              onSelected: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: 10),
            Text('WHEN LOGGING', style: AppType.label(9.5)),
            const SizedBox(height: 6),
            ChoicePills<HabitEntry>(
              values: HabitEntry.values,
              selected: _entry,
              label: (e) => switch (e) {
                HabitEntry.fixed => '1-tap amount',
                HabitEntry.prompt => 'Ask each time',
                HabitEntry.both => '1-tap or custom',
              },
              onSelected: (e) => setState(() => _entry = e),
            ),
            const SizedBox(height: 10),
            PressScale(
              onTap: () => setState(() => _roundTrip = !_roundTrip),
              child: Row(children: [
                Icon(_roundTrip ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: AppColors.amberBright, size: 22),
                const SizedBox(width: 8),
                Text('Offer a round-trip (×2) toggle', style: AppType.body(13, weight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: AppType.body(14, color: AppColors.stone))),
          PillButton(label: 'Save', dense: true, onPressed: _save),
        ],
      );
}
