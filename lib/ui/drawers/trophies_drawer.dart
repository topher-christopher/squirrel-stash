import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../../providers/finance_providers.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'drawer_shell.dart';

/// Reclaimed trophies & Great Oak upgrades.
class TrophiesDrawer extends ConsumerWidget {
  const TrophiesDrawer({super.key});

  static const _levels = [
    ('🏮', 'Canopy Lantern'),
    ('🏮', 'Twin Lanterns'),
    ('🎏', 'Festival Bunting'),
    ('✨', 'Golden Grove'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophies = ref.watch(trophiesProvider);
    final level = ref.watch(financeProvider.select((f) => f.oakLevel));
    return DrawerShell(
      emoji: '🏆',
      title: 'Reclaimed Trophies & Oak Lv.$level',
      subtitle: 'Every completed goal seals its chamber and permanently upgrades your Great Oak',
      children: [
        Row(children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: i < level ? const Color(0x99451A03) : const Color(0xFF1C1917),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: i < level ? AppColors.amberBright : const Color(0x33F59E0B)),
                ),
                child: Column(children: [
                  Opacity(
                    opacity: i < level ? 1 : 0.35,
                    child: Text(_levels[i].$1, style: const TextStyle(fontSize: 18, fontFamilyFallback: AppType.emojiFallback)),
                  ),
                  const SizedBox(height: 3),
                  Text('Lv.${i + 1}', style: AppType.label(9.5, color: i < level ? AppColors.amberBright : AppColors.stoneDim)),
                  Text(_levels[i].$2,
                      textAlign: TextAlign.center,
                      style: AppType.body(10, color: i < level ? AppColors.cream : AppColors.stoneDim)),
                ]),
              ),
            ),
            if (i < 3) const SizedBox(width: 6),
          ],
        ]),
        const SizedBox(height: 14),
        if (trophies.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Fill a Goal Chamber to 100% and reclaim it to place your first relic here.',
                textAlign: TextAlign.center, style: AppType.body(13, color: AppColors.stoneDim)),
          ),
        for (final t in trophies) ...[
          StashCard(
            border: AppColors.amber.withValues(alpha: 0.3),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(t.icon, style: const TextStyle(fontSize: 20, fontFamilyFallback: AppType.emojiFallback)),
                const SizedBox(width: 10),
                Expanded(child: Text(t.name, style: AppType.title(15, color: AppColors.honey))),
                Text(Money.whole(t.amountCents), style: AppType.number(14, color: AppColors.emeraldBright)),
              ]),
              const SizedBox(height: 6),
              Text('“${t.note}”', style: AppType.body(12.5, color: AppColors.cream.withValues(alpha: 0.85), style: FontStyle.italic)),
              const SizedBox(height: 4),
              Text('Reclaimed ${Dates.short(t.reclaimedAt)}, ${t.reclaimedAt.year}',
                  style: AppType.body(11, color: AppColors.stoneDim)),
            ]),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
