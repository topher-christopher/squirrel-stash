import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/money.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../providers/ui_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'backup_section.dart';
import 'drawer_shell.dart';
import 'prompts.dart';

/// Study settings: payday, feedback, art blueprint and data management.
class SettingsDrawer extends ConsumerWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final blueprint = ref.watch(uiProvider.select((u) => u.blueprint));
    final notifier = ref.read(settingsProvider.notifier);
    final actions = ref.read(stashActionsProvider);
    return DrawerShell(
      emoji: '⚙️',
      title: 'Study Settings',
      subtitle: 'Everything stays on this device — no account, no cloud.',
      children: [
        _Row(
          label: 'Payday amount',
          value: Money.whole(s.paydayCents),
          onTap: () async {
            final cents = await promptAmount(context, title: 'Payday amount', initialCents: s.paydayCents);
            if (cents != null && cents > 0) notifier.update((x) => x.copyWith(paydayCents: cents));
          },
        ),
        _Toggle(label: 'Sound effects', value: s.sfxOn, onChanged: (v) => notifier.update((x) => x.copyWith(sfxOn: v))),
        _Toggle(label: 'Haptics', value: s.hapticsOn, onChanged: (v) => notifier.update((x) => x.copyWith(hapticsOn: v))),
        _Toggle(
            label: 'Calm background piano (assets/audio/ambient_piano.wav)',
            value: s.ambientOn,
            onChanged: (v) => notifier.update((x) => x.copyWith(ambientOn: v))),
        _Toggle(
          label: 'Custom art blueprint (room drop-in slots)',
          value: blueprint,
          onChanged: (_) => ref.read(uiProvider.notifier).toggleBlueprint(),
        ),
        const SectionLabel('Backup & restore'),
        const BackupSection(),
        const SizedBox(height: 16),
        const SectionLabel('Your data'),
        PillButton(
          label: '🌳 Restore demo Great Oak',
          outlined: true,
          color: AppColors.honey,
          expand: true,
          onPressed: () async {
            final ok = await confirmAction(context,
                title: 'Restore the demo?', message: 'Replaces everything with the sample Great Oak colony.',
                confirmLabel: 'Restore', destructive: true);
            if (ok) {
              await actions.restoreDemo();
              if (context.mounted) Navigator.of(context).pop();
            }
          },
        ),
        const SizedBox(height: 8),
        PillButton(
          label: '🌱 Start fresh (clear all data)',
          color: const Color(0xFF7F1D1D),
          expand: true,
          onPressed: () async {
            final ok = await confirmAction(context,
                title: 'Start fresh?',
                message: 'Deletes all balances, statements, goals, trophies, holdings and logs on this device. Your bill presets come back empty. This cannot be undone.',
                confirmLabel: 'Clear everything', destructive: true);
            if (ok) {
              await actions.startFresh();
              if (context.mounted) Navigator.of(context).pop();
            }
          },
        ),
        const SizedBox(height: 16),
        Text(
          'SquirrelStash stores everything in a local SQLite database. Acorns and Golden Acorns are cosmetic currencies and are never mixed with real money. Live prices are fetched without any account or API key.',
          style: AppType.body(11.5, color: AppColors.stoneDim, height: 1.4),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: PressScale(
          scale: 0.98,
          onTap: onTap,
          child: StashCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Expanded(child: Text(label, style: AppType.body(14, weight: FontWeight.w700))),
              Text(value, style: AppType.number(15, color: AppColors.amberBright)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.stoneDim, size: 20),
            ]),
          ),
        ),
      );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: PressScale(
          scale: 0.98,
          onTap: () => onChanged(!value),
          child: StashCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(child: Text(label, style: AppType.body(14, weight: FontWeight.w700))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 46,
                height: 26,
                padding: const EdgeInsets.all(3),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: value ? AppColors.emeraldButton : AppColors.stoneDeep,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
                ),
              ),
            ]),
          ),
        ),
      );
}
