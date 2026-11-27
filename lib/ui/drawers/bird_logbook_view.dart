import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/art/bird_painter.dart';
import '../../models/bird.dart';
import '../../providers/colony_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// The Lifetime Bird & Critter Logbook: every species with its all-time
/// visits, first/last seen, favorite lure and keepsake (unlocked at 100).
class BirdLogbookView extends ConsumerWidget {
  const BirdLogbookView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(birdLogProvider);
    final unlocked = log.values.where((e) => e.keepsakeUnlocked).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Keepsakes: $unlocked / ${BirdSpecies.values.length} · ${log.values.fold<int>(0, (s, e) => s + e.visits)} lifetime visits',
          style: AppType.body(12, weight: FontWeight.w800, color: AppColors.honey)),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 8) / 2;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in BirdSpecies.values) SizedBox(width: w, child: _SpeciesCard(species: s, entry: log[s])),
        ]);
      }),
    ]);
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.species, required this.entry});

  final BirdSpecies species;
  final BirdLogEntry? entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final seen = e != null;
    final visits = e?.visits ?? 0;
    final done = e?.keepsakeUnlocked ?? false;
    final date = DateFormat.MMMd();
    final rarity = switch (species.rarity) {
      BirdRarity.common => 'Common',
      BirdRarity.uncommon => 'Uncommon',
      BirdRarity.rare => 'Rare',
    };
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (done ? AppColors.flame : AppColors.amber).withValues(alpha: done ? 0.6 : 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          BirdPortrait(species: species, size: 34, hidden: !seen),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(seen ? species.label : '???', maxLines: 2,
                  style: AppType.body(11.5, weight: FontWeight.w800, color: seen ? AppColors.cream : AppColors.stoneDim, height: 1.15)),
              Text('$rarity · ${species.seed.label.split(' ').first}',
                  style: AppType.body(9.5, color: AppColors.stoneDim)),
            ]),
          ),
          KeepsakeBadge(species: species, unlocked: done, size: 26),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: math.min(1.0, visits / BirdSpecies.keepsakeVisits),
            minHeight: 5,
            backgroundColor: AppColors.stoneDeep,
            color: done ? AppColors.flame : AppColors.leaf,
          ),
        ),
        const SizedBox(height: 4),
        Text(done ? '$visits visits · ${species.keepsake}' : '$visits / ${BirdSpecies.keepsakeVisits} visits',
            maxLines: 2, style: AppType.body(10.5, weight: FontWeight.w700, color: done ? AppColors.flame : AppColors.stone)),
        if (seen)
          Text('First ${date.format(e.firstSeen)} · Last ${date.format(e.lastSeen)}\nFavorite: ${e.favoriteLure?.label ?? 'plain seed'}',
              style: AppType.body(9.5, color: AppColors.stoneDim, height: 1.25))
        else
          Text(species.nightOnly ? 'Only visits at night.' : 'Not spotted yet.',
              style: AppType.body(9.5, color: AppColors.stoneDim)),
      ]),
    );
  }
}

/// Painted species portrait (a dark silhouette until first spotted).
class BirdPortrait extends StatelessWidget {
  const BirdPortrait({super.key, required this.species, this.size = 32, this.hidden = false});

  final BirdSpecies species;
  final double size;
  final bool hidden;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Container(
          width: size,
          height: size,
          color: const Color(0xFF2A170B),
          child: CustomPaint(painter: _PortraitPainter(species, hidden)),
        ),
      );
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.species, this.hidden);

  final BirdSpecies species;
  final bool hidden;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 26 / BirdPainter.scaleOf(species);
    final at = Offset(size.width / 2 + 1, size.height * 0.84);
    if (hidden) {
      canvas.saveLayer(Offset.zero & size,
          Paint()..colorFilter = const ColorFilter.mode(Color(0xFF57412B), BlendMode.srcIn));
    }
    BirdPainter.paint(canvas, at, species, scale: s * (species == BirdSpecies.chipmunk ? 0.95 : 1.1));
    if (hidden) canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitPainter old) => old.species != species || old.hidden != hidden;
}

/// The species' keepsake medallion: gold with the bird inside once it has
/// 100 lifetime visits, a dim locked disc before that.
class KeepsakeBadge extends StatelessWidget {
  const KeepsakeBadge({super.key, required this.species, required this.unlocked, this.size = 28});

  final BirdSpecies species;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: unlocked ? species.keepsake : 'Keepsake unlocks at ${BirdSpecies.keepsakeVisits} visits',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: unlocked
                    ? const [Color(0xFFFDE68A), Color(0xFFD97706)]
                    : const [Color(0xFF44403C), Color(0xFF292524)]),
            border: Border.all(color: unlocked ? const Color(0xFFFBBF24) : const Color(0xFF57534E), width: 1.4),
            boxShadow: unlocked ? const [BoxShadow(color: Color(0x88FBBF24), blurRadius: 8)] : null,
          ),
          child: unlocked
              ? CustomPaint(painter: _PortraitPainter(species, false))
              : Icon(Icons.lock_rounded, size: size * 0.5, color: const Color(0xFF78716C)),
        ),
      );
}
