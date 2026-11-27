import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../models/decor.dart';
import '../../models/feat.dart';
import '../../models/room.dart';
import '../../models/trinket.dart';
import '../../models/colony_economy.dart';
import '../../providers/awards_provider.dart';
import '../../providers/colony_actions.dart';
import '../../providers/colony_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/reserves_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/stash_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../widgets/stash_controls.dart';
import 'colony_cards.dart';
import 'drawer_shell.dart';

/// Acorn Outfitter (skatepark & DJ lounge): every stashed trinket (tap for
/// a Field Note), the free colony wardrobe, and the Canopy Terrace
/// Display Pedestals.
class OutfitterBody extends ConsumerWidget {
  const OutfitterBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfits = ref.watch(decorProvider.select((d) => d[DecorKey.hats]!));
    final pedestals = ref.watch(colonyProvider.select((c) => c.pedestalCount));
    return RoomPage(children: [
      Text('An indoor mini half-pipe, DJ Hazelnut on the bottle-cap decks and a mirror disco ball that spins while the Hearth is warm.',
          style: AppType.body(12, color: AppColors.stoneDim, height: 1.35)),
      SectionLabel('Stashed Goods',
          trailing: Text('All free · tap for Field Notes', style: AppType.body(11, color: AppColors.stoneDim))),
      LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in Trinket.all) SizedBox(width: w, child: _TrinketTile(trinket: t)),
        ]);
      }),
      SectionLabel('Colony Wardrobe',
          trailing: PressScale(
            onTap: () => ref.read(stashActionsProvider).toggleDecor(DecorKey.hats),
            child: Text(outfits.enabled ? 'Worn · tap to stow' : 'Stowed · tap to wear',
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
      const SectionLabel('Canopy Terrace Pedestals'),
      Text('$pedestals stone pedestals on the Canopy Terrace show off your favorite statues, trophies and trinkets.',
          style: AppType.body(12, color: AppColors.stoneDim, height: 1.35)),
      const SizedBox(height: 8),
      _PedestalRow(count: pedestals),
      if (pedestals < ColonyEconomy.basePedestals + ColonyEconomy.maxExtraPedestals) ...[
        const SizedBox(height: 8),
        PillButton(
          label: 'Raise another pedestal (${ColonyEconomy.pedestalGolden[pedestals - ColonyEconomy.basePedestals]} Golden Acorns)',
          outlined: true,
          color: AppColors.flame,
          expand: true,
          onPressed: () => ref.read(colonyActionsProvider).addPedestal(),
        ),
      ],
      const RoomThemeCard(room: RoomKey.outfitter),
    ]);
  }
}

class _TrinketTile extends StatelessWidget {
  const _TrinketTile({required this.trinket});

  final Trinket trinket;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: () {
          Haptics.light();
          showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text('${trinket.emoji} ${trinket.name}'),
              content: Text(
                '${trinket.fieldNote}\n\nFound in: ${trinket.room}',
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
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            Text(trinket.emoji, style: const TextStyle(fontSize: 18, fontFamilyFallback: AppType.emojiFallback)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(trinket.name,
                  maxLines: 2,
                  style: AppType.body(11.5, weight: FontWeight.w700, color: AppColors.cream)),
            ),
          ]),
        ),
      );
}

class _PedestalRow extends ConsumerWidget {
  const _PedestalRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(roomsProvider.select((r) => r.pedestals)).take(count).toList();
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
