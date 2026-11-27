import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../models/decor.dart';
import '../../models/feat.dart';
import '../../models/room.dart';
import '../../models/trinket.dart';
import '../../providers/awards_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/reserves_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'decor_shop.dart';
import 'drawer_shell.dart';

/// Acorn Outfitter: stashed human trinkets (tap for a Field Note), the
/// colony wardrobe, and the Display Pedestals around the tree.
class OutfitterBody extends ConsumerWidget {
  const OutfitterBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(roomsProvider.select((r) => r.levelOf(RoomKey.outfitter)));
    final outfits = ref.watch(decorProvider.select((d) => d[DecorKey.hats]!));
    return RoomPage(children: [
      SectionLabel('Stashed Goods',
          trailing: Text('Tap for Field Notes', style: AppType.body(11, color: AppColors.stoneDim))),
      LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in Trinket.all) SizedBox(width: w, child: _TrinketTile(trinket: t, unlocked: level >= t.minLevel)),
        ]);
      }),
      SectionLabel('Colony Wardrobe',
          trailing: PressScale(
            onTap: () => ref.read(stashActionsProvider).buyOrToggleDecor(DecorKey.hats),
            child: Text(outfits.owned ? (outfits.enabled ? 'Worn' : 'Stowed') : 'Unlock in Upgrades',
                style: AppType.body(11.5, weight: FontWeight.w800, color: outfits.active ? AppColors.emeraldSoft : AppColors.honey)),
          )),
      for (final piece in OutfitPiece.all)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Text(piece.emoji, style: const TextStyle(fontSize: 18, fontFamilyFallback: AppType.emojiFallback)),
            const SizedBox(width: 10),
            Expanded(child: Text(piece.name, style: AppType.body(13, weight: FontWeight.w800))),
            Flexible(child: Text(piece.wornBy, textAlign: TextAlign.end, style: AppType.body(11, color: AppColors.stoneDim))),
          ]),
        ),
      const SectionLabel('Display Pedestals'),
      Text('Four stone pedestals on the terrace show off your favorite statues, trophies and trinkets.',
          style: AppType.body(12, color: AppColors.stoneDim, height: 1.35)),
      const SizedBox(height: 8),
      const _PedestalRow(),
      const RoomUpgradeCard(room: RoomKey.outfitter),
    ]);
  }
}

class _TrinketTile extends StatelessWidget {
  const _TrinketTile({required this.trinket, required this.unlocked});

  final Trinket trinket;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: () {
          Haptics.light();
          showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text('${trinket.emoji} ${trinket.name}'),
              content: Text(
                unlocked ? trinket.fieldNote : 'Still being hauled home… upgrade the Outfitter to Lv.${trinket.minLevel} to display it.',
                style: AppType.body(14, color: AppColors.cream, height: 1.4, style: FontStyle.italic),
              ),
              actions: [PillButton(label: 'Noted', dense: true, onPressed: () => Navigator.of(c).pop())],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1917),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.amber.withValues(alpha: unlocked ? 0.35 : 0.12)),
          ),
          child: Row(children: [
            Opacity(
              opacity: unlocked ? 1 : 0.35,
              child: Text(trinket.emoji, style: const TextStyle(fontSize: 18, fontFamilyFallback: AppType.emojiFallback)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(trinket.name,
                  maxLines: 2,
                  style: AppType.body(11.5, weight: FontWeight.w700, color: unlocked ? AppColors.cream : AppColors.stoneDim)),
            ),
          ]),
        ),
      );
}

class _PedestalRow extends ConsumerWidget {
  const _PedestalRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(roomsProvider.select((r) => r.pedestals));
    return Row(children: [
      for (var i = 0; i < slots.length; i++) ...[
        Expanded(
          child: PressScale(
            onTap: () => _pick(context, ref, i),
            child: Container(
              height: 74,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.barkDeep,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stoneDim.withValues(alpha: 0.4)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_icon(ref, slots[i]), style: const TextStyle(fontSize: 22, fontFamilyFallback: AppType.emojiFallback)),
                const SizedBox(height: 4),
                Text(_label(ref, slots[i]),
                    maxLines: 2, textAlign: TextAlign.center, style: AppType.body(9.5, color: AppColors.stone, height: 1.15)),
              ]),
            ),
          ),
        ),
        if (i < slots.length - 1) const SizedBox(width: 6),
      ],
    ]);
  }

  static List<(String, String, String)> _options(WidgetRef ref) {
    final statues = ref.read(trophiesProvider);
    final feats = {for (final a in ref.read(awardsProvider)) a.featKey}..remove(Feats.fourSeasonsStage);
    return [
      for (final t in statues) ('statue:${t.id}', t.icon, '${t.name} statue'),
      for (final key in feats)
        if (Feats.byKey(key) case final def?) ('feat:$key', def.icon, def.name),
      for (final t in Trinket.all) ('trinket:${t.key}', t.emoji, t.name),
    ];
  }

  static String _icon(WidgetRef ref, String item) {
    if (item.isEmpty) return '➕';
    for (final o in _options(ref)) {
      if (o.$1 == item) return o.$2;
    }
    return '❔';
  }

  static String _label(WidgetRef ref, String item) {
    if (item.isEmpty) return 'Empty';
    for (final o in _options(ref)) {
      if (o.$1 == item) return o.$3;
    }
    return 'Missing';
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, int slot) async {
    final options = _options(ref);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.plaque,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 12), children: [
          ListTile(
            leading: const Icon(Icons.clear_rounded, color: AppColors.stoneDim),
            title: Text('Leave empty', style: AppType.body(14)),
            onTap: () => Navigator.of(c).pop(''),
          ),
          for (final (key, icon, label) in options)
            ListTile(
              leading: Text(icon, style: const TextStyle(fontSize: 20, fontFamilyFallback: AppType.emojiFallback)),
              title: Text(label, style: AppType.body(14)),
              onTap: () => Navigator.of(c).pop(key),
            ),
        ]),
      ),
    );
    if (choice != null) {
      ref.read(roomsProvider.notifier).setPedestal(slot, choice);
      Haptics.success();
    }
  }
}
