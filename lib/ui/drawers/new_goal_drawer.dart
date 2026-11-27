import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'drawer_shell.dart';
import 'prompts.dart';

/// Excavate a new Goal Chamber.
class NewGoalDrawer extends ConsumerStatefulWidget {
  const NewGoalDrawer({super.key});

  @override
  ConsumerState<NewGoalDrawer> createState() => _NewGoalDrawerState();
}

class _NewGoalDrawerState extends ConsumerState<NewGoalDrawer> {
  static const _icons = ['🎯', '✈️', '💻', '👟', '⌨️', '🎸', '🏡', '🚗', '🎮', '📷', '🐶', '🎓'];

  final _name = TextEditingController();
  final _target = TextEditingController();
  final _note = TextEditingController();
  String _icon = '🎯';
  bool _priority = false;
  DateTime _due = Dates.addMonths(DateTime.now(), 6);

  bool get _valid => _name.text.trim().isNotEmpty && (Money.parse(_target.text) ?? 0) > 0;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  void _excavate() {
    if (!_valid) {
      Haptics.warn();
      return;
    }
    ref.read(stashActionsProvider).createGoal(
          name: _name.text.trim(),
          icon: _icon,
          targetCents: Money.parse(_target.text)!,
          dueDate: _due,
          priority: _priority,
          note: _note.text.trim(),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => DrawerShell(
        emoji: '⛏️',
        title: 'Dig New Goal Chamber',
        subtitle: 'Squirrels will excavate a Lv.1 Dirt Alcove that grows as you fill it',
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final icon in _icons)
              PressScale(
                onTap: () {
                  Haptics.tap();
                  setState(() => _icon = icon);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: icon == _icon ? const Color(0x55F59E0B) : AppColors.barkDeep,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: icon == _icon ? AppColors.amberBright : const Color(0x33F59E0B)),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 20, fontFamilyFallback: AppType.emojiFallback)),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          StashField(controller: _name, hint: 'Goal name (e.g., Mechanical Keyboard)', onChanged: (_) => setState(() {})),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: StashField(controller: _target, money: true, hint: 'Target amount', onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            Expanded(
              child: PillButton(
                label: '📅 ${Dates.short(_due)}, ${_due.year}',
                outlined: true,
                color: AppColors.honey,
                expand: true,
                onPressed: () async {
                  final picked = await pickDate(context, _due);
                  if (picked != null) setState(() => _due = picked);
                },
              ),
            ),
          ]),
          const SizedBox(height: 8),
          StashField(controller: _note, hint: 'Time-capsule note for your future self…', maxLines: 3),
          const SizedBox(height: 10),
          PressScale(
            onTap: () {
              Haptics.tap();
              setState(() => _priority = !_priority);
            },
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _priority ? AppColors.amberBright : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.amberBright, width: 1.6),
                ),
                child: _priority ? const Icon(Icons.check_rounded, size: 18, color: AppColors.night) : null,
              ),
              const SizedBox(width: 10),
              Text('⭐ Mark as Priority Chamber', style: AppType.body(13.5, weight: FontWeight.w800, color: AppColors.honey)),
            ]),
          ),
          const SizedBox(height: 16),
          PillButton(label: 'Excavate Chamber', expand: true, color: AppColors.amberBright, onPressed: _valid ? _excavate : null),
        ],
      );
}
