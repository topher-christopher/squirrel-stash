import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/money.dart';
import '../../providers/finance_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/stash_controls.dart';
import 'drawer_shell.dart';
import 'prompts.dart';

/// Spendable Free Cash: checking minus cash reserved in Goal Chambers.
class CashDrawer extends ConsumerWidget {
  const CashDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(financeProvider);
    final payday = ref.watch(settingsProvider.select((s) => s.paydayCents));
    final actions = ref.read(stashActionsProvider);
    return DrawerShell(
      emoji: '🌰',
      title: 'Spendable Free Cash',
      subtitle: 'Checking balance minus cash reserved inside your Goal Chambers',
      accent: AppColors.emeraldBright,
      children: [
        Row(children: [
          Expanded(child: StatTile(label: 'Total Bank', value: AnimatedMoney(f.checkingCents))),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              label: 'In Goals',
              color: AppColors.amberBright,
              value: AnimatedMoney(f.allocatedCents, prefix: '-'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              label: 'Free Cash',
              highlight: true,
              color: AppColors.emeraldBright,
              value: AnimatedMoney(f.freeCashCents),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: PillButton(
              label: '+ Log Payday (+${Money.whole(payday)})',
              color: AppColors.emeraldButton,
              expand: true,
              onPressed: actions.payday,
            ),
          ),
          const SizedBox(width: 8),
          PillButton(
            label: 'Spend -\$100',
            color: AppColors.stoneDeep,
            foreground: AppColors.honey,
            onPressed: () => actions.spend(10000),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: PillButton(
              label: 'Sync bank balance',
              outlined: true,
              color: AppColors.emeraldBright,
              expand: true,
              onPressed: () async {
                final cents = await promptAmount(context,
                    title: 'Checking balance',
                    message: 'Enter what your bank shows right now.',
                    initialCents: f.checkingCents);
                if (cents != null) actions.setChecking(cents);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PillButton(
              label: 'Log a spend…',
              outlined: true,
              color: AppColors.honey,
              expand: true,
              onPressed: () async {
                final cents = await promptAmount(context, title: 'How much did you spend?', confirmLabel: 'Spend');
                if (cents != null) actions.spend(cents);
              },
            ),
          ),
        ]),
        const SizedBox(height: 16),
        StashCard(
          child: Row(children: [
            const Text('🌳', style: TextStyle(fontSize: 22, fontFamilyFallback: AppType.emojiFallback)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TOTAL STASH (NET WORTH)', style: AppType.label(9.5)),
                const SizedBox(height: 3),
                AnimatedMoney(f.netWorthCents, style: AppType.number(20, color: AppColors.cream)),
              ]),
            ),
            Text('Checking + reserves', style: AppType.body(11, color: AppColors.stoneDim)),
          ]),
        ),
        const SizedBox(height: 10),
        Text(
          'Tip: keep checking synced with your bank. Spending never dips into '
          'acorns already stashed in Goal Chambers.',
          style: AppType.body(12, color: AppColors.stoneDim, height: 1.35),
        ),
      ],
    );
  }
}
