import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/decor.dart';
import '../../providers/reserves_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';

/// Golden Leaf Cosmetic Decor Shop (cosmetic currency only — never USD).
class DecorShop extends ConsumerWidget {
  const DecorShop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaves = ref.watch(settingsProvider.select((s) => s.goldenLeaves));
    final decor = ref.watch(decorProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionLabel('🍃 Golden Leaf Study Decor',
          color: AppColors.leaf,
          trailing: Text('$leaves Leaves', style: AppType.number(14, color: AppColors.leaf))),
      LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final key in DecorKey.values)
            SizedBox(
              width: w,
              child: _DecorTile(
                item: decor[key]!,
                affordable: leaves >= key.cost,
                onTap: () => ref.read(stashActionsProvider).buyOrToggleDecor(key),
              ),
            ),
        ]);
      }),
      const SizedBox(height: 8),
      Text('Golden Leaves come from Focus Shifts, Professor Hoot and reclaimed chambers. They are purely cosmetic.',
          style: AppType.body(11.5, color: AppColors.stoneDim, height: 1.35)),
    ]);
  }
}

class _DecorTile extends StatelessWidget {
  const _DecorTile({required this.item, required this.affordable, required this.onTap});

  final DecorItemState item;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final owned = item.owned;
    final status = !owned
        ? 'Unlock: 🍃 ${item.key.cost} Leaves'
        : (item.enabled ? 'Shown • Tap to hide' : 'Hidden • Tap to show');
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: owned ? (item.enabled ? const Color(0x99064E3B) : const Color(0x66064E3B)) : const Color(0xFF1C1917),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: owned
                ? AppColors.emeraldBright.withValues(alpha: item.enabled ? 0.55 : 0.25)
                : AppColors.amber.withValues(alpha: affordable ? 0.45 : 0.18),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${item.key.emoji} ${item.key.label}',
              style: AppType.body(13, weight: FontWeight.w800, color: owned ? AppColors.emeraldSoft : AppColors.cream)),
          const SizedBox(height: 3),
          Text(status, style: AppType.body(11, color: owned ? AppColors.emeraldSoft.withValues(alpha: 0.8) : AppColors.stoneDim)),
        ]),
      ),
    );
  }
}
