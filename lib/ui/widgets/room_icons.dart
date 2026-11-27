import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/room.dart';
import '../../providers/art_assets_provider.dart';

/// Clean diegetic icon + accent color per room. Drop
/// `assets/images/icons/<room>.png` in to use hand-drawn art instead.
abstract final class RoomIcons {
  static IconData icon(RoomKey room) => switch (room) {
        RoomKey.treasury => Icons.savings_rounded,
        RoomKey.birdFeeder => Icons.flutter_dash_rounded,
        RoomKey.burrow => Icons.backpack_rounded,
        RoomKey.hearth => Icons.local_fire_department_rounded,
        RoomKey.outfitter => Icons.skateboarding_rounded,
        RoomKey.lab => Icons.science_rounded,
        RoomKey.trophyHall => Icons.emoji_events_rounded,
        RoomKey.billVault => Icons.receipt_long_rounded,
        RoomKey.kitchen => Icons.soup_kitchen_rounded,
        RoomKey.goals => Icons.flag_rounded,
        RoomKey.metro => Icons.subway_rounded,
        RoomKey.brokerage => Icons.show_chart_rounded,
        RoomKey.pokemon => Icons.style_rounded,
        RoomKey.crypto => Icons.diamond_rounded,
        RoomKey.espp => Icons.badge_rounded,
        RoomKey.hysa => Icons.account_balance_rounded,
        RoomKey.retirement => Icons.beach_access_rounded,
        RoomKey.silver => Icons.hardware_rounded,
      };

  static Color accent(RoomKey room) => switch (room) {
        RoomKey.treasury => const Color(0xFF4ADE80),
        RoomKey.birdFeeder => const Color(0xFF7DD3FC),
        RoomKey.burrow => const Color(0xFFBEF264),
        RoomKey.hearth => const Color(0xFFFB923C),
        RoomKey.outfitter => const Color(0xFFF472B6),
        RoomKey.lab => const Color(0xFF6EE7B7),
        RoomKey.trophyHall => const Color(0xFFFBBF24),
        RoomKey.billVault => const Color(0xFFFDBA74),
        RoomKey.kitchen => const Color(0xFFFB923C),
        RoomKey.goals => const Color(0xFFFCD34D),
        RoomKey.metro => const Color(0xFF93C5FD),
        RoomKey.brokerage => const Color(0xFF86EFAC),
        RoomKey.pokemon => const Color(0xFFFDE047),
        RoomKey.crypto => const Color(0xFFC4B5FD),
        RoomKey.espp => const Color(0xFF7DD3FC),
        RoomKey.hysa => const Color(0xFFFDE68A),
        RoomKey.retirement => const Color(0xFFFACC15),
        RoomKey.silver => const Color(0xFFE2E8F0),
      };

  static String assetPath(RoomKey room) => 'assets/images/icons/${room.name}.png';
}

/// A round carved-oak medallion holding a room's icon.
class RoomMedallion extends ConsumerWidget {
  const RoomMedallion({super.key, required this.room, this.size = 34, this.glow = false});

  final RoomKey room;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = RoomIcons.accent(room);
    final custom = ref.watch(artAssetsProvider).contains(RoomIcons.assetPath(room));
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFF6B3D1E), Color(0xFF3B1E0B)]),
        border: Border.all(color: accent.withValues(alpha: 0.85), width: size * 0.06),
        boxShadow: [
          const BoxShadow(color: Color(0x88000000), blurRadius: 4, offset: Offset(0, 2)),
          if (glow) BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: size * 0.5),
        ],
      ),
      child: custom
          ? Padding(padding: EdgeInsets.all(size * 0.12), child: Image.asset(RoomIcons.assetPath(room)))
          : Icon(RoomIcons.icon(room), size: size * 0.56, color: accent),
    );
  }
}
