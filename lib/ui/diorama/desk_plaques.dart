import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/money.dart';
import '../../game/diorama_event.dart';
import '../../game/layout.dart';
import '../../providers/finance_providers.dart';
import '../../providers/focus_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../drawers/drawers.dart';
import '../widgets/animated_money.dart';
import 'tap_zone.dart';

/// Carved desk plaques under each instrument + trophy relics on the shelf.
class DeskPlaques extends ConsumerWidget {
  const DeskPlaques({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zen = ref.watch(settingsProvider.select((s) => s.zenMode));
    final stats = ref.watch(impulseStatsProvider);
    final treat = ref.watch(treatStatusProvider);
    final focus = ref.watch(focusProvider);
    final leaves = ref.watch(settingsProvider.select((s) => s.goldenLeaves));
    final hearth = ref.watch(settingsProvider.select((s) => s.hearthLabel));
    final trophies = ref.watch(trophiesProvider);
    final oak = ref.watch(financeProvider.select((f) => f.oakLevel));

    Widget zone(Rect hotspot, Offset plaqueAt, DioramaTarget target, String label, VoidCallback onTap, Widget plaque) =>
        Positioned.fromRect(
          rect: hotspot,
          child: TapZone(
            target: target,
            label: label,
            pressAlignment: Alignment.bottomCenter,
            onTap: onTap,
            child: Stack(children: [
              Positioned(
                left: plaqueAt.dx - hotspot.left,
                top: plaqueAt.dy - hotspot.top,
                child: ZenFade(zen: zen, child: plaque),
              ),
            ]),
          ),
        );

    return Stack(children: [
      zone(StudyLayout.siloHotspot, const Offset(22, 428), DioramaTarget.silo,
          'Impulse silo. Opens the Foraging and Alchemy Lab', () => Drawers.lab(context),
          _Card(width: 102, lines: [
            Text('🧪 IMPULSE SAVED', style: AppType.label(8.5, letterSpacing: 0.4)),
            AnimatedMoney(stats.monthCents, suffix: '/mo', style: AppType.number(15, weight: FontWeight.w700, color: AppColors.emeraldBright)),
            Text('All-Time: ${Money.whole(stats.allTimeCents)}', style: AppType.body(8.5, weight: FontWeight.w700, color: AppColors.stone)),
            Text('${stats.goldAcorns}👑 ${stats.silverAcorns}🥈 • +Log', style: AppType.body(8.5, weight: FontWeight.w800, color: AppColors.amberBright)),
          ])),
      zone(StudyLayout.lanternHotspot, const Offset(136, 428), DioramaTarget.lantern,
          'Treat Yourself lantern: ${treat.label}', () => Drawers.lab(context),
          _Card(width: 94, color: treat.background, border: treat.border, glow: treat.dot, lines: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: treat.dot, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(treat.badge, style: AppType.label(8.5, color: Colors.white, weight: FontWeight.w900, letterSpacing: 0.5)),
            ]),
            Text(treat.label, style: AppType.title(10, weight: FontWeight.w700, color: Colors.white)),
            Text(treat.hint, style: AppType.body(8.5, color: Colors.white.withValues(alpha: 0.92))),
          ])),
      zone(StudyLayout.clockHotspot, const Offset(242, 428), DioramaTarget.clock,
          'Focus Shift clock. Opens the focus timer', () => Drawers.focus(context),
          _Card(
            width: 90,
            color: focus.running ? const Color(0xFF78350F) : const Color(0xFF241308),
            border: focus.running ? AppColors.caution : AppColors.rust,
            glow: focus.running ? AppColors.caution : null,
            lines: [
              Text('⏳ FOCUS SHIFT', style: AppType.label(8.5, letterSpacing: 0.4)),
              Text(focus.running || focus.paused ? focus.clock : 'Start Timer',
                  style: AppType.number(focus.running || focus.paused ? 15 : 13.5, weight: FontWeight.w700)),
              Text('🍃 $leaves Leaves', style: AppType.body(8.5, weight: FontWeight.w700, color: AppColors.leaf)),
              Text('🔥 $hearth', style: AppType.body(8, weight: FontWeight.w700, color: const Color(0xFFFDBA74))),
            ],
          )),
      zone(StudyLayout.trophyHotspot, const Offset(342, 428), DioramaTarget.trophies,
          'Trophy stand. Great Oak level $oak', () => Drawers.trophies(context),
          _Card(width: 78, lines: [
            Text('🏆 TROPHIES', style: AppType.label(8.5, color: const Color(0xFFFCD34D), letterSpacing: 0.4)),
            Text('Oak Lv.$oak', style: AppType.title(14, weight: FontWeight.w700)),
            Text('${trophies.length} Reclaimed', style: AppType.body(8.5, weight: FontWeight.w700, color: AppColors.stone)),
            Text('View ›', style: AppType.body(8, weight: FontWeight.w800, color: AppColors.amberBright)),
          ])),
      // Relics on the trophy shelf (art — stays visible in Zen Mode)
      Positioned(
        left: 359,
        top: 384,
        child: IgnorePointer(
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(trophies.isNotEmpty ? trophies[0].icon : '🏆',
                style: const TextStyle(fontSize: 18, height: 1, fontFamilyFallback: AppType.emojiFallback)),
            const SizedBox(width: 6),
            Text(trophies.length > 1 ? trophies[1].icon : '🌰',
                style: const TextStyle(fontSize: 15, height: 1, fontFamilyFallback: AppType.emojiFallback)),
          ]),
        ),
      ),
    ]);
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.width,
    required this.lines,
    this.color = const Color(0xFF241308),
    this.border = AppColors.rust,
    this.glow,
  });

  final double width;
  final List<Widget> lines;
  final Color color;
  final Color border;
  final Color? glow;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: 62,
        child: WoodPlaque(
          color: color,
          border: border,
          glow: glow,
          // Tight line height so four lines always fit the 62-unit plaque;
          // the outer FittedBox is a last-resort guard for large fonts.
          child: DefaultTextStyle.merge(
            style: const TextStyle(height: 1.08),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width - 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final l in lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0.6),
                        child: FittedBox(fit: BoxFit.scaleDown, child: l),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
