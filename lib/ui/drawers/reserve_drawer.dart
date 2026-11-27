import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/money.dart';
import '../../models/holding.dart';
import '../../providers/finance_providers.dart';
import '../../providers/reserves_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/animated_money.dart';
import '../widgets/stash_controls.dart';
import 'drawer_shell.dart';
import 'prompts.dart';

/// Deep Oak-Root Reserve detail (Amber Reserve / Curio Vault / Deep Treasury).
class ReserveDrawer extends ConsumerWidget {
  const ReserveDrawer({super.key, required this.kind});

  final ReserveKind kind;

  static const _titles = {
    ReserveKind.amber: 'Amber Reserve (Brokerage & HYSA)',
    ReserveKind.curio: 'Curio Vault (Pokémon Cards & Silver)',
    ReserveKind.treasury: 'Deep Treasury (Roth IRA & 401k)',
  };

  static const _quick = {
    ReserveKind.amber: ('+ Deposit \$500 to Amber Reserve', 50000, 'Deposits'),
    ReserveKind.curio: ('+ Log New Slab / Bullion (+\$250)', 25000, 'New Curios'),
    ReserveKind.treasury: ('+ Log Retirement Contribution (+\$500)', 50000, 'Contributions'),
  };

  static const _colors = {
    ReserveKind.amber: AppColors.amberBright,
    ReserveKind.curio: AppColors.slate,
    ReserveKind.treasury: AppColors.cautionSoft,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(financeProvider);
    final holdings = ref.watch(holdingsProvider).where((h) => h.reserve == kind).toList();
    final apyBps = ref.watch(settingsProvider.select((s) => s.brokerageApyBps));
    final notifier = ref.read(holdingsProvider.notifier);
    final color = _colors[kind]!;
    final quick = _quick[kind]!;

    final info = switch (kind) {
      ReserveKind.amber =>
        'Settlement: 1–3 business days • Estimated passive yield: ~${Money.exact(f.dailyYieldCents.round())}/day at ${(apyBps / 100).toStringAsFixed(2)}% APY',
      ReserveKind.curio => holdings.isEmpty
          ? 'Tracked separately from daily cash: graded slabs, sealed boxes and bullion.'
          : 'Tracked separately from daily cash: ${holdings.map((h) => '${h.label} (${Money.whole(h.valueCents)})').join(' + ')}',
      ReserveKind.treasury =>
        'Roth IRA + 401(k) locked deep in the ancient roots for long-term compounding. The Golden Elder keeps watch.',
    };

    return DrawerShell(
      emoji: kind.emoji,
      title: _titles[kind]!,
      accent: color,
      children: [
        StashCard(
          border: color.withValues(alpha: 0.35),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedMoney(f.reserveCents(kind), style: AppType.number(30, color: color)),
            const SizedBox(height: 6),
            Text(info, style: AppType.body(12.5, color: AppColors.stone, height: 1.35)),
            if (kind == ReserveKind.amber) ...[
              const SizedBox(height: 10),
              PillButton(
                label: 'Edit APY (${(apyBps / 100).toStringAsFixed(2)}%)',
                dense: true,
                outlined: true,
                color: AppColors.amberBright,
                onPressed: () async {
                  final cents = await promptAmount(context,
                      title: 'Annual yield (APY %)',
                      message: 'e.g. 4.6 for 4.60%',
                      initialCents: apyBps,
                      confirmLabel: 'Save');
                  if (cents != null) {
                    ref.read(settingsProvider.notifier).update((s) => s.copyWith(brokerageApyBps: cents));
                  }
                },
              ),
            ],
          ]),
        ),
        SectionLabel('Holdings',
            trailing: Text('Tap to update • Hold to edit', style: AppType.body(11, color: AppColors.stoneDim))),
        if (holdings.isEmpty)
          Text('Nothing here yet.', style: AppType.body(12.5, color: AppColors.stoneDim)),
        for (final h in holdings) ...[
          PressScale(
            scale: 0.98,
            onTap: () async {
              final cents = await promptAmount(context, title: h.label, message: 'Current value', initialCents: h.valueCents);
              if (cents != null) {
                notifier.upsert(h.copyWith(valueCents: cents));
                Haptics.success();
              }
            },
            onLongPress: () => _editHolding(context, ref, h),
            child: StashCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Expanded(child: Text(h.label, style: AppType.body(14, weight: FontWeight.w800))),
                Text(Money.whole(h.valueCents), style: AppType.number(15, color: color)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        PillButton(
          label: quick.$1,
          expand: true,
          color: kind == ReserveKind.curio ? const Color(0xFF475569) : AppColors.amberDeep,
          onPressed: () {
            notifier.deposit(kind, quick.$2, fallbackLabel: quick.$3);
            Haptics.success();
          },
        ),
        const SizedBox(height: 8),
        PillButton(
          label: '+ Add holding',
          expand: true,
          outlined: true,
          color: color,
          onPressed: () async {
            final result = await promptLabelAmount(context, title: 'New holding', labelHint: 'e.g. Charizard PSA 10', confirmLabel: 'Add');
            if (result != null) notifier.add(kind, result.$1, result.$2);
          },
        ),
      ],
    );
  }

  Future<void> _editHolding(BuildContext context, WidgetRef ref, Holding h) async {
    Haptics.light();
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(h.label),
        content: Text('Rename or revalue this holding, or remove it from the reserve.',
            style: AppType.body(13.5, color: AppColors.stone)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop('remove'),
            child: Text('Remove', style: AppType.body(14, color: AppColors.alert)),
          ),
          PillButton(label: 'Edit', dense: true, onPressed: () => Navigator.of(c).pop('edit')),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;
    final holdings = ref.read(holdingsProvider.notifier);
    if (choice == 'remove') {
      final ok = await confirmAction(context,
          title: 'Remove ${h.label}?', message: 'Delete this holding from the reserve?',
          confirmLabel: 'Remove', destructive: true);
      if (ok) holdings.remove(h.id);
      return;
    }
    final result = await promptLabelAmount(context,
        title: 'Edit holding', initialLabel: h.label, initialCents: h.valueCents);
    if (result != null) holdings.upsert(h.copyWith(label: result.$1, valueCents: result.$2));
  }
}
